import os
import time
from datetime import datetime
from collections import deque
import json
import config

# Suppress deprecation warnings for google.generativeai
import warnings
warnings.filterwarnings('ignore', category=FutureWarning, module='google.*')

try:
    import google.generativeai as genai
    GEMINI_AVAILABLE = True
except ImportError:
    GEMINI_AVAILABLE = False
    # Only print warning once at module import, not on every import
    import sys
    if not hasattr(sys, '_gemini_warning_shown'):
        print("⚠️ Warning: google-generativeai not installed. LLM features will be disabled.")
        sys._gemini_warning_shown = True


class GeminiService:
    """Service for Google Gemini LLM integration"""
    
    def __init__(self):
        self.api_key = config.Config.GEMINI_API_KEY
        self.model_name = config.Config.GEMINI_MODEL
        
        # Rate limiting for free tier (15 requests/minute)
        self.request_times = deque(maxlen=15)
        self.min_request_interval = 4.0  # seconds between requests (to stay under 15/min)
        self.last_request_time = 0
        
        # Conversation history storage (in-memory, per user)
        self.conversation_history = {}
        
        # Initialize Gemini if available
        if GEMINI_AVAILABLE and self.api_key:
            try:
                genai.configure(api_key=self.api_key)
                # Try to initialize the model to validate it exists
                self.model = genai.GenerativeModel(self.model_name)
                self.is_available = True
                print(f"✅ Gemini initialized with model: {self.model_name}")
            except Exception as e:
                error_msg = str(e)
                print(f"⚠️ Warning: Failed to initialize Gemini: {error_msg}")
                # Check if it's a model not found error
                if "not found" in error_msg.lower() or "404" in error_msg:
                    print(f"💡 Hint: Model '{self.model_name}' may not be available. Try 'gemini-1.5-flash' or 'gemini-1.5-pro'")
                self.is_available = False
        else:
            self.is_available = False
    
    def _is_feature_enabled(self, feature_flag_name):
        """
        Check if a specific LLM feature is enabled via config flags
        
        Args:
            feature_flag_name: Name of the feature flag (e.g., 'LLM_ENABLE_CHAT')
        
        Returns:
            bool: True if feature is enabled, False otherwise
        """
        if not self.is_available:
            return False
        
        try:
            import config
            return getattr(config.Config, feature_flag_name, True)
        except:
            return False
    
    def _is_financial_question(self, message):
        """
        Check if a message is related to financial topics (multi-language support)
        
        Args:
            message: User's message
        
        Returns:
            bool: True if financial-related, False otherwise
        """
        if not message or len(message.strip()) < 3:
            return False
        
        message_lower = message.lower()
        
        # Financial keywords - Multi-language (Indonesian, English, and common terms)
        financial_keywords = [
            # Indonesian
            'uang', 'keuangan', 'budget', 'anggaran', 'pengeluaran', 'pemasukan',
            'tabungan', 'menabung', 'hemat', 'penghematan', 'belanja', 'transaksi',
            'kategori', 'tagihan', 'utang', 'hutang', 'cicilan', 'investasi',
            'pendapatan', 'gaji', 'penghasilan', 'biaya', 'pengeluaran bulanan',
            'rencana keuangan', 'tujuan keuangan', 'financial goal', 'saving',
            'expense', 'income', 'spending', 'bills', 'debt', 'loan',
            # English
            'money', 'finance', 'budget', 'expense', 'income', 'saving', 'spending',
            'transaction', 'category', 'bill', 'debt', 'loan', 'investment',
            'financial', 'cash', 'payment', 'cost', 'price', 'amount', 'balance',
            'account', 'wallet', 'credit', 'debit', 'withdrawal', 'deposit',
            'salary', 'wage', 'earnings', 'revenue', 'profit', 'loss',
            # Common financial terms (works in multiple languages)
            '€', '$', '£', '¥', 'rp', 'rupiah', 'dollar', 'euro', 'pound',
            'bank', 'atm', 'transfer', 'remittance'
        ]
        
        # Check if message contains financial keywords
        has_financial_keyword = any(keyword in message_lower for keyword in financial_keywords)
        
        # Check for financial question patterns (multi-language)
        financial_patterns = [
            # Indonesian patterns
            'berapa', 'berapa banyak', 'berapa biaya', 'berapa harga',
            'bagaimana cara', 'cara hemat', 'cara menabung', 'cara menghemat',
            'tips', 'saran', 'rekomendasi',
            'apakah', 'apakah saya', 'apakah perlu',
            'kenapa', 'mengapa',
            # English patterns
            'how much', 'how to save', 'how to budget', 'how to manage',
            'what is', 'what are', 'what should', 'what can',
            'why', 'when', 'where',
            'suggest', 'recommend', 'advice', 'tip', 'tips',
            'should i', 'can i', 'do i need'
        ]
        
        has_financial_pattern = any(pattern in message_lower for pattern in financial_patterns)
        
        # If it's a very short message without context, be more lenient
        if len(message.split()) <= 3:
            return has_financial_keyword or has_financial_pattern
        
        # For longer messages, require financial keyword
        return has_financial_keyword
    
    def _check_rate_limit(self):
        """Check and enforce rate limiting"""
        current_time = time.time()
        time_since_last = current_time - self.last_request_time
        
        if time_since_last < self.min_request_interval:
            sleep_time = self.min_request_interval - time_since_last
            time.sleep(sleep_time)
        
        # Remove old requests outside the 1-minute window
        current_time = time.time()
        while self.request_times and current_time - self.request_times[0] > 60:
            self.request_times.popleft()
        
        # Check if we've hit the rate limit
        if len(self.request_times) >= 15:
            oldest_request = self.request_times[0]
            wait_time = 60 - (current_time - oldest_request)
            if wait_time > 0:
                time.sleep(wait_time)
                # Clean up again after waiting
                while self.request_times and time.time() - self.request_times[0] > 60:
                    self.request_times.popleft()
        
        self.request_times.append(time.time())
        self.last_request_time = time.time()
    
    def _make_request(self, prompt, system_instruction=None, temperature=0.7):
        """Make a request to Gemini API with rate limiting and error handling"""
        if not self.is_available:
            return None, "LLM service not available"
        
        try:
            self._check_rate_limit()
            
            # Build the full prompt with system instruction if provided
            full_prompt = prompt
            if system_instruction:
                full_prompt = f"{system_instruction}\n\n{prompt}"
            
            response = self.model.generate_content(
                full_prompt,
                generation_config=genai.types.GenerationConfig(
                    temperature=temperature,
                    max_output_tokens=2048,
                )
            )
            
            return response.text, None
        except Exception as e:
            error_msg = str(e)
            print(f"❌ Gemini API error: {error_msg}")
            
            # Check if it's a model not found error
            if "not found" in error_msg.lower() or "404" in error_msg or "is not supported" in error_msg.lower():
                return None, f"Model '{self.model_name}' is not available. Please update GEMINI_MODEL in your .env file to 'gemini-1.5-flash' or 'gemini-1.5-pro'"
            
            return None, error_msg
    
    def _get_financial_context(self, user_id):
        """Get user's financial data for context"""
        try:
            from models.transaction_model import TransactionModel
            from models.budget_model import BudgetModel
            from models.goal_model import GoalModel
            
            context = {
                'recent_transactions': TransactionModel.get_recent_transactions(user_id, 10),
                'budgets': BudgetModel.get_user_budgets(user_id, active_only=True),
                'goals': GoalModel.get_user_goals(user_id, include_completed=False)
            }
            return context
        except Exception as e:
            print(f"Error getting financial context: {e}")
            return {}
    
    def generate_chat_response(self, user_id, message, conversation_history=None):
        """
        Generate a chat response from Gemini
        
        Args:
            user_id: User ID for conversation context
            message: User's message
            conversation_history: Optional conversation history (if None, uses stored history)
        
        Returns:
            tuple: (response_text, error_message)
        """
        if not self.is_available:
            return None, "LLM service not available"
        
        # Check if chat feature is enabled
        if not self._is_feature_enabled('LLM_ENABLE_CHAT'):
            return None, "Chat feature is disabled"
        
        # Validate that message is financial-related (only if strict mode is enabled)
        if not self._is_feature_enabled('LLM_ALLOW_NON_FINANCIAL'):
            if not self._is_financial_question(message):
                # Detect user language for appropriate error message
                message_lower = message.lower()
                if any(word in message_lower for word in ['how', 'what', 'why', 'when', 'where', 'can', 'should', 'do']):
                    error_msg = "Sorry, I can only help with personal finance questions. Please ask about budget, expenses, savings, or your financial planning."
                else:
                    error_msg = "Maaf, saya hanya dapat membantu dengan pertanyaan tentang keuangan pribadi. Silakan tanyakan tentang budget, pengeluaran, tabungan, atau perencanaan keuangan Anda."
                return None, error_msg
        
        # Get or initialize conversation history
        if conversation_history is None:
            if user_id not in self.conversation_history:
                self.conversation_history[user_id] = []
            conversation_history = self.conversation_history[user_id]
        
        # Get financial context
        financial_context = self._get_financial_context(user_id)
        
        # Build system instruction (multi-language support)
        # Check if non-financial questions are allowed
        allow_non_financial = self._is_feature_enabled('LLM_ALLOW_NON_FINANCIAL')
        
        if allow_non_financial:
            system_instruction = """You are a friendly financial assistant that specializes in personal finance but can also help with general questions.

PRIORITY: Focus on personal finance topics:
   - Budget and expense management
   - Personal financial planning
   - Transaction and spending analysis
   - Saving tips and strategies
   - Savings and financial goals management
   - Transaction categories
   - Budget and spending patterns
   - Income and expense tracking

GUIDELINES:
1. If asked about finance: Provide detailed, helpful answers using the user's financial context when available.
2. If asked about non-financial topics: Answer briefly and politely, then gently guide the conversation back to finance when appropriate.
   - Example: "I can help with that briefly, but I specialize in personal finance. Would you like to know about budgeting or saving strategies?"
3. DO NOT provide specific investment advice or recommend specific financial products.
4. Be friendly, conversational, and respond in the same language the user uses (Indonesian, English, or other languages)."""
        else:
            system_instruction = """You are a financial assistant that ONLY helps with personal finance questions.

STRICT RULES:
1. ONLY answer questions related to:
   - Budget and expense management
   - Personal financial planning
   - Transaction and spending analysis
   - Saving tips and strategies
   - Savings and financial goals management
   - Transaction categories
   - Budget and spending patterns
   - Income and expense tracking

2. If the question is NOT related to finance, politely decline:
   - Indonesian: "Maaf, saya hanya dapat membantu dengan pertanyaan tentang keuangan pribadi. Silakan tanyakan tentang budget, pengeluaran, tabungan, atau perencanaan keuangan Anda."
   - English: "Sorry, I can only help with personal finance questions. Please ask about budget, expenses, savings, or your financial planning."
   - Other languages: Respond in the user's language with a similar message

3. DO NOT provide specific investment advice or recommend specific financial products.

4. Focus on budget management, saving, and personal financial planning.

5. Respond in the same language the user uses (Indonesian, English, or other languages). Be friendly and easy to understand."""
        
        # Build context string
        context_str = ""
        if financial_context.get('recent_transactions'):
            context_str += f"\nRecent transactions: {len(financial_context['recent_transactions'])} transactions"
        if financial_context.get('budgets'):
            context_str += f"\nActive budgets: {len(financial_context['budgets'])} budgets"
        if financial_context.get('goals'):
            context_str += f"\nFinancial goals: {len(financial_context['goals'])} goals"
        
        # Build conversation history string
        history_str = ""
        if conversation_history:
            history_str = "\n\nConversation history:\n"
            for entry in conversation_history[-5:]:  # Last 5 messages
                history_str += f"User: {entry.get('user', '')}\n"
                history_str += f"Assistant: {entry.get('assistant', '')}\n"
        
        # Build full prompt
        if allow_non_financial:
            prompt = f"""User's financial context:{context_str}
{history_str}

User's question: {message}

Answer helpfully in the same language the user used. If the question is not financial-related, provide a brief answer and gently guide the conversation back to finance when appropriate."""
        else:
            prompt = f"""User's financial context:{context_str}
{history_str}

User's question: {message}

Answer helpfully in the same language the user used. If the question is not financial-related, politely decline."""
        
        response_text, error = self._make_request(prompt, system_instruction, temperature=0.7)
        
        if response_text:
            # Store in conversation history
            if user_id not in self.conversation_history:
                self.conversation_history[user_id] = []
            self.conversation_history[user_id].append({
                'user': message,
                'assistant': response_text,
                'timestamp': datetime.now().isoformat()
            })
            # Keep only last 10 messages
            if len(self.conversation_history[user_id]) > 10:
                self.conversation_history[user_id] = self.conversation_history[user_id][-10:]
        
        return response_text, error
    
    def categorize_transaction(self, description, amount, date=None):
        """
        Categorize a transaction using LLM
        
        Args:
            description: Transaction description
            amount: Transaction amount
            date: Optional transaction date
        
        Returns:
            tuple: (category_name, confidence, error_message)
        """
        if not self.is_available:
            return None, 0.0, "LLM service not available"
        
        if not self._is_feature_enabled('LLM_ENABLE_CATEGORIZATION'):
            return None, 0.0, "Categorization feature is disabled"
        
        prompt = f"""Kategorikan transaksi berikut ke dalam salah satu kategori keuangan umum:
Deskripsi: {description}
Jumlah: Rp {amount:,.0f}
Tanggal: {date or 'Tidak diketahui'}

Kategori yang umum digunakan:
- Makanan & Minuman (restoran, makanan cepat saji, belanja bahan makanan)
- Transportasi (bensin, parkir, tiket transportasi umum, ojek online)
- Belanja (pakaian, elektronik, kebutuhan rumah tangga)
- Hiburan (film, konser, game, streaming)
- Kesehatan (obat, dokter, apotek, gym)
- Tagihan (listrik, air, internet, telepon)
- Pendidikan (buku, kursus, sekolah)
- Lainnya

Jawab HANYA dengan nama kategori saja, tanpa penjelasan tambahan."""
        
        response_text, error = self._make_request(prompt, temperature=0.3)
        
        if error:
            return None, 0.0, error
        
        # Extract category name
        category_name = response_text.strip() if response_text else "Lainnya"
        confidence = 0.8 if response_text else 0.0
        
        return category_name, confidence, None
    
    def generate_transaction_summary(self, transactions):
        """
        Generate a summary of transactions using LLM
        
        Args:
            transactions: List of transaction dictionaries
        
        Returns:
            tuple: (summary_text, error_message)
        """
        if not self.is_available:
            return None, "LLM service not available"
        
        if not self._is_feature_enabled('LLM_ENABLE_SUMMARIZATION'):
            return None, "Summarization feature is disabled"
        
        if not transactions:
            return "Tidak ada transaksi untuk diringkas.", None
        
        # Prepare transaction data
        total_expenses = sum(float(t.get('amount_232143', 0) or 0) for t in transactions if t.get('type_232143') == 'expense')
        total_income = sum(float(t.get('amount_232143', 0) or 0) for t in transactions if t.get('type_232143') == 'income')
        
        # Group by category
        category_totals = {}
        for t in transactions:
            if t.get('type_232143') == 'expense':
                cat = t.get('category_name', 'Lainnya')
                amount = float(t.get('amount_232143', 0) or 0)
                category_totals[cat] = category_totals.get(cat, 0) + amount
        
        # Build prompt
        prompt = f"""Buatkan ringkasan keuangan berdasarkan data berikut:

Total Pengeluaran: Rp {total_expenses:,.0f}
Total Pendapatan: Rp {total_income:,.0f}
Jumlah Transaksi: {len(transactions)}

Pengeluaran per Kategori:
{chr(10).join(f"- {cat}: Rp {amt:,.0f}" for cat, amt in sorted(category_totals.items(), key=lambda x: x[1], reverse=True)[:5])}

Buatkan ringkasan singkat (2-3 kalimat) dalam bahasa Indonesia yang menjelaskan pola pengeluaran dan memberikan insight yang berguna."""
        
        response_text, error = self._make_request(prompt, temperature=0.5)
        return response_text, error
    
    def enhance_recommendations(self, user_data, base_recommendations):
        """
        Enhance recommendations with natural language using LLM
        
        Args:
            user_data: Dictionary with user financial data
            base_recommendations: List of base recommendation dictionaries
        
        Returns:
            list: Enhanced recommendations with LLM-generated explanations
        """
        if not self.is_available or not base_recommendations:
            return base_recommendations
        
        if not self._is_feature_enabled('LLM_ENHANCE_RECOMMENDATIONS'):
            return base_recommendations
        
        try:
            # Build prompt with recommendations
            recs_text = "\n".join([
                f"{i+1}. {r.get('title', '')}: {r.get('message', '')}"
                for i, r in enumerate(base_recommendations[:5])
            ])
            
            prompt = f"""Berikut adalah rekomendasi keuangan yang dihasilkan oleh sistem:
{recs_text}

Tugas Anda adalah memperbaiki dan memperjelas rekomendasi-rekomendasi ini dengan bahasa yang lebih natural dan mudah dipahami dalam bahasa Indonesia. 
Jaga inti pesan dan prioritas tetap sama, tapi buat lebih ramah dan actionable.

Format output: JSON array dengan format:
[
  {{
    "title": "Judul rekomendasi",
    "message": "Pesan yang diperjelas",
    "priority": angka_prioritas
  }}
]"""
            
            response_text, error = self._make_request(prompt, temperature=0.6)
            
            if error or not response_text:
                return base_recommendations
            
            # Try to parse JSON response
            try:
                import re
                # Extract JSON from response
                json_match = re.search(r'\[.*\]', response_text, re.DOTALL)
                if json_match:
                    enhanced = json.loads(json_match.group())
                    # Merge with original recommendations
                    for i, enhanced_rec in enumerate(enhanced):
                        if i < len(base_recommendations):
                            base_recommendations[i]['message'] = enhanced_rec.get('message', base_recommendations[i].get('message'))
                            base_recommendations[i]['title'] = enhanced_rec.get('title', base_recommendations[i].get('title'))
            except:
                # If parsing fails, just use original
                pass
            
            return base_recommendations
        except Exception as e:
            print(f"Error enhancing recommendations: {e}")
            return base_recommendations
    
    def explain_budget(self, budget_data, spending_data):
        """
        Explain budget status using LLM
        
        Args:
            budget_data: Budget dictionary
            spending_data: Spending summary dictionary
        
        Returns:
            tuple: (explanation_text, error_message)
        """
        if not self.is_available:
            return None, "LLM service not available"
        
        if not self._is_feature_enabled('LLM_ENABLE_BUDGET_EXPLANATION'):
            return None, "Budget explanation feature is disabled"
        
        limit = float(budget_data.get('limit_amount_232143', 0) or 0)
        spent = float(budget_data.get('spent_amount_232143', 0) or 0)
        category = budget_data.get('category_name', 'Kategori')
        usage_percent = (spent / limit * 100) if limit > 0 else 0
        
        prompt = f"""Jelaskan status budget berikut dalam bahasa Indonesia yang ramah:

Kategori: {category}
Limit Budget: Rp {limit:,.0f}
Jumlah Terpakai: Rp {spent:,.0f}
Persentase: {usage_percent:.1f}%
Sisa: Rp {limit - spent:,.0f}

Buatkan penjelasan singkat (2-3 kalimat) yang menjelaskan status budget dan memberikan saran jika diperlukan."""
        
        response_text, error = self._make_request(prompt, temperature=0.5)
        return response_text, error
    
    def suggest_goal_strategy(self, goals, financial_situation):
        """
        Suggest goal strategy using LLM
        
        Args:
            goals: List of goal dictionaries
            financial_situation: Dictionary with financial summary
        
        Returns:
            tuple: (strategy_text, error_message)
        """
        if not self.is_available:
            return None, "LLM service not available"
        
        if not self._is_feature_enabled('LLM_ENABLE_GOAL_STRATEGY'):
            return None, "Goal strategy feature is disabled"
        
        goals_text = "\n".join([
            f"- {g.get('name_232143', 'Goal')}: Rp {float(g.get('current_amount_232143', 0) or 0):,.0f} / Rp {float(g.get('target_amount_232143', 0) or 0):,.0f}"
            for g in goals[:5]
        ])
        
        prompt = f"""Berdasarkan situasi keuangan berikut, berikan strategi untuk mencapai tujuan keuangan:

Tujuan Keuangan:
{goals_text}

Situasi Keuangan:
- Pendapatan bulanan: Rp {financial_situation.get('monthly_income', 0):,.0f}
- Pengeluaran bulanan: Rp {financial_situation.get('monthly_expenses', 0):,.0f}
- Tabungan bulanan: Rp {financial_situation.get('monthly_savings', 0):,.0f}

Buatkan strategi singkat (3-4 kalimat) dalam bahasa Indonesia untuk mencapai tujuan-tujuan ini."""
        
        response_text, error = self._make_request(prompt, temperature=0.6)
        return response_text, error
    
    def get_conversation_history(self, user_id):
        """Get conversation history for a user"""
        return self.conversation_history.get(user_id, [])
    
    def clear_conversation_history(self, user_id):
        """Clear conversation history for a user"""
        if user_id in self.conversation_history:
            del self.conversation_history[user_id]


# Singleton instance
gemini_service = GeminiService() 