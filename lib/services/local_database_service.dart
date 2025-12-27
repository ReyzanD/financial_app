import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:financial_app/services/logger_service.dart';

/// Local SQLite Database Service
/// Replaces backend API - all data stored locally on device
class LocalDatabaseService {
  static LocalDatabaseService? _instance;
  static Database? _database;

  LocalDatabaseService._internal();
  
  factory LocalDatabaseService() {
    _instance ??= LocalDatabaseService._internal();
    return _instance!;
  }

  /// Get database instance (singleton)
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  /// Initialize database
  Future<Database> _initDatabase() async {
    try {
      final documentsDirectory = await getDatabasesPath();
      final path = join(documentsDirectory, 'financial_app.db');

      LoggerService.info('📱 Initializing local database: $path');

      return await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
      );
    } catch (e) {
      LoggerService.error('Error initializing database', error: e);
      rethrow;
    }
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    LoggerService.info('📱 Creating database schema...');

    // Enable foreign keys
    await db.execute('PRAGMA foreign_keys=ON');

    // Users table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users_232143 (
        user_id_232143 TEXT PRIMARY KEY,
        email_232143 TEXT NOT NULL UNIQUE,
        password_hash_232143 TEXT NOT NULL,
        full_name_232143 TEXT NOT NULL,
        phone_number_232143 TEXT,
        date_of_birth_232143 TEXT,
        occupation_232143 TEXT,
        income_range_232143 TEXT CHECK (income_range_232143 IN ('0-3jt','3-5jt','5-10jt','10-20jt','20jt+')),
        family_size_232143 INTEGER DEFAULT 1,
        currency_232143 TEXT DEFAULT 'IDR',
        base_location_232143 TEXT,
        financial_goals_232143 TEXT DEFAULT '{"emergency_fund": 0, "vacation": 0, "investment": 0, "debt_payment": 0}',
        risk_tolerance_232143 INTEGER DEFAULT 3,
        notification_settings_232143 TEXT DEFAULT '{"budget_alerts": true, "goal_reminders": true, "spending_insights": true, "push_notifications": true}',
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        last_login_232143 TEXT,
        is_active_232143 INTEGER DEFAULT 1
      )
    ''');

    // Categories table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS categories_232143 (
        category_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT,
        name_232143 TEXT NOT NULL,
        type_232143 TEXT NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
        color_232143 TEXT DEFAULT '#3498db',
        icon_232143 TEXT DEFAULT 'receipt',
        budget_limit_232143 REAL,
        budget_period_232143 TEXT DEFAULT 'monthly' CHECK (budget_period_232143 IN ('daily','weekly','monthly','yearly')),
        is_fixed_232143 INTEGER DEFAULT 0,
        keywords_232143 TEXT,
        location_patterns_232143 TEXT,
        parent_category_id_232143 TEXT,
        display_order_232143 INTEGER DEFAULT 0,
        is_system_default_232143 INTEGER DEFAULT 0,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (parent_category_id_232143) REFERENCES categories_232143(category_id_232143)
      )
    ''');

    // Transactions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transactions_232143 (
        transaction_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        amount_232143 REAL NOT NULL,
        type_232143 TEXT NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
        category_id_232143 TEXT,
        description_232143 TEXT NOT NULL,
        location_name_232143 TEXT,
        latitude_232143 REAL,
        longitude_232143 REAL,
        location_data_232143 TEXT,
        payment_method_232143 TEXT DEFAULT 'cash' CHECK (payment_method_232143 IN ('cash','debit_card','credit_card','e_wallet','bank_transfer')),
        receipt_image_url_232143 TEXT,
        is_recurring_232143 INTEGER DEFAULT 0,
        recurring_pattern_232143 TEXT,
        predicted_category_id_232143 TEXT,
        confidence_score_232143 REAL,
        is_verified_232143 INTEGER DEFAULT 1,
        tags_232143 TEXT,
        transaction_date_232143 TEXT NOT NULL,
        transaction_time_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
        FOREIGN KEY (predicted_category_id_232143) REFERENCES categories_232143(category_id_232143)
      )
    ''');

    // Budgets table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS budgets_232143 (
        budget_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        category_id_232143 TEXT,
        amount_232143 REAL NOT NULL,
        period_232143 TEXT NOT NULL CHECK (period_232143 IN ('daily','weekly','monthly','yearly')),
        period_start_232143 TEXT NOT NULL,
        period_end_232143 TEXT NOT NULL,
        spent_amount_232143 REAL DEFAULT 0.00,
        rollover_enabled_232143 INTEGER DEFAULT 0,
        alert_threshold_232143 INTEGER DEFAULT 80,
        is_active_232143 INTEGER DEFAULT 1,
        recommended_amount_232143 REAL,
        recommendation_reason_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        remaining_amount_232143 REAL DEFAULT 0.00,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143)
      )
    ''');

    // Financial goals table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_goals_232143 (
        goal_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        description_232143 TEXT,
        goal_type_232143 TEXT NOT NULL CHECK (goal_type_232143 IN ('emergency_fund','vacation','investment','debt_payment','education','vehicle','house','wedding','other')),
        target_amount_232143 REAL NOT NULL,
        current_amount_232143 REAL DEFAULT 0.00,
        start_date_232143 TEXT DEFAULT CURRENT_DATE,
        target_date_232143 TEXT NOT NULL,
        is_completed_232143 INTEGER DEFAULT 0,
        completed_date_232143 TEXT,
        priority_232143 INTEGER DEFAULT 3,
        monthly_target_232143 REAL,
        auto_deduct_232143 INTEGER DEFAULT 0,
        deduct_percentage_232143 REAL,
        recommended_monthly_saving_232143 REAL,
        feasibility_score_232143 REAL,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        progress_percentage_232143 REAL DEFAULT 0.00,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Financial obligations table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS financial_obligations_232143 (
        obligation_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        description_232143 TEXT,
        amount_232143 REAL NOT NULL,
        due_date_232143 TEXT NOT NULL,
        frequency_232143 TEXT NOT NULL CHECK (frequency_232143 IN ('one_time','daily','weekly','monthly','yearly')),
        payment_method_232143 TEXT DEFAULT 'cash' CHECK (payment_method_232143 IN ('cash','debit_card','credit_card','e_wallet','bank_transfer')),
        category_id_232143 TEXT,
        is_paid_232143 INTEGER DEFAULT 0,
        paid_date_232143 TEXT,
        reminder_enabled_232143 INTEGER DEFAULT 1,
        reminder_days_before_232143 INTEGER DEFAULT 3,
        auto_pay_enabled_232143 INTEGER DEFAULT 0,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users_232143(email_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions_232143(user_id_232143, transaction_date_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_transactions_type_date ON transactions_232143(type_232143, transaction_date_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_user ON categories_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_user ON financial_goals_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_obligations_user ON financial_obligations_232143(user_id_232143)');

    LoggerService.info('✅ Database schema created successfully');
  }

  /// Upgrade database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    LoggerService.info('📱 Upgrading database from version $oldVersion to $newVersion');
    // Add migration logic here if needed
  }

  /// Close database
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
      LoggerService.info('📱 Database closed');
    }
  }

  /// Delete database (for testing or reset)
  Future<void> deleteDatabase() async {
    final documentsDirectory = await getDatabasesPath();
    final path = join(documentsDirectory, 'financial_app.db');
    await databaseFactory.deleteDatabase(path);
    _database = null;
    LoggerService.info('📱 Database deleted');
  }
}

