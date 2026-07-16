import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:financial_app/services/logger_service.dart';

/// Local SQLite Database Service
/// Replaces backend API - all data stored locally on device
class LocalDatabaseService {
  static LocalDatabaseService? _instance;
  static Database? _database;

  LocalDatabaseService._internal();

  /// Named constructor for creating instances in tests or subclasses.
  /// For normal use, prefer the factory constructor [LocalDatabaseService()].
  LocalDatabaseService.test() : super();

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
        version: currentVersion,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
        onUpgrade: _onUpgrade,
        onDowngrade: _onDowngrade,
      );
    } catch (e) {
      LoggerService.error('Error initializing database', error: e);
      rethrow;
    }
  }

  /// Called on every database connection open — enables foreign keys per-connection
  Future<void> _onConfigure(Database db) async {
    // Enable foreign keys on every connection (required by SQLite)
    await db.execute('PRAGMA foreign_keys=ON');
  }

  /// Create database schema
  Future<void> _onCreate(Database db, int version) async {
    LoggerService.info('📱 Creating database schema...');

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
         account_id_232143 TEXT,
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
         FOREIGN KEY (predicted_category_id_232143) REFERENCES categories_232143(category_id_232143),
         FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143)
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

    // Financial obligations table (unified: bills + debts + subscriptions)
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
        type_232143 TEXT NOT NULL DEFAULT 'bill' CHECK (type_232143 IN ('bill','debt','subscription')),
        original_amount_232143 REAL,
        current_balance_232143 REAL,
        interest_rate_232143 REAL,
        debt_type_232143 TEXT,
        creditor_name_232143 TEXT,
        notes_232143 TEXT,
        subscription_cycle_232143 TEXT,
        next_renewal_232143 TEXT,
        is_active_232143 INTEGER DEFAULT 1,
        account_id_232143 TEXT,
        category_232143 TEXT,
        minimum_payment_232143 REAL,
        payoff_strategy_232143 TEXT,
        is_subscription_232143 INTEGER DEFAULT 0,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
        FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143)
      )
    ''');

    // Receipt scans table (for scan history)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS receipt_scans_232143 (
        receipt_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        image_path_232143 TEXT,
        merchant_232143 TEXT,
        total_amount_232143 REAL DEFAULT 0.0,
        receipt_date_232143 TEXT,
        raw_text_232143 TEXT,
        items_json_232143 TEXT,
        category_id_232143 TEXT,
        transaction_id_232143 TEXT,
        is_processed_232143 INTEGER DEFAULT 0,
        confidence_score_232143 REAL DEFAULT 0.0,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
        FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143)
      )
    ''');

    // Accounts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS accounts_232143 (
        account_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        type_232143 TEXT NOT NULL CHECK (type_232143 IN ('cash','bank','e_wallet','credit_card','investment','other')),
        icon_232143 TEXT DEFAULT 'wallet',
        color_232143 TEXT DEFAULT '#8B5FBF',
        balance_232143 REAL DEFAULT 0.0,
        currency_232143 TEXT DEFAULT 'IDR',
        account_number_232143 TEXT,
        bank_name_232143 TEXT,
        is_active_232143 INTEGER DEFAULT 1,
        is_default_232143 INTEGER DEFAULT 0,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Debts table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debts_232143 (
        debt_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        original_amount_232143 REAL NOT NULL,
        current_balance_232143 REAL NOT NULL,
        interest_rate_232143 REAL DEFAULT 0.0,
        type_232143 TEXT NOT NULL CHECK (type_232143 IN ('personal','mortgage','student','credit_card','car','business','other')),
        start_date_232143 TEXT NOT NULL,
        due_date_232143 TEXT,
        monthly_payment_232143 REAL,
        creditor_name_232143 TEXT,
        notes_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Debt payments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS debt_payments_232143 (
        payment_id_232143 TEXT PRIMARY KEY,
        debt_id_232143 TEXT NOT NULL,
        user_id_232143 TEXT NOT NULL,
        amount_232143 REAL NOT NULL,
        payment_date_232143 TEXT NOT NULL,
        balance_after_232143 REAL NOT NULL,
        notes_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (debt_id_232143) REFERENCES debts_232143(debt_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Subscriptions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS subscriptions_232143 (
        subscription_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        cost_232143 REAL NOT NULL,
        cycle_232143 TEXT NOT NULL CHECK (cycle_232143 IN ('weekly','monthly','yearly')),
        category_232143 TEXT DEFAULT 'general',
        start_date_232143 TEXT NOT NULL,
        next_renewal_232143 TEXT,
        is_active_232143 INTEGER DEFAULT 1,
        notes_232143 TEXT,
        account_id_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143)
      )
    ''');

    // Tags table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tags_232143 (
        tag_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        color_232143 TEXT DEFAULT '#8B5FBF',
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Transaction-Tags mapping table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_tags_232143 (
        transaction_id_232143 TEXT NOT NULL,
        tag_id_232143 TEXT NOT NULL,
        PRIMARY KEY (transaction_id_232143, tag_id_232143),
        FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (tag_id_232143) REFERENCES tags_232143(tag_id_232143) ON DELETE CASCADE
      )
    ''');

    // Expense splits table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS expense_splits_232143 (
        split_id_232143 TEXT PRIMARY KEY,
        transaction_id_232143 TEXT,
        user_id_232143 TEXT NOT NULL,
        participant_name_232143 TEXT NOT NULL,
        participant_phone_232143 TEXT,
        amount_232143 REAL NOT NULL,
        paid_amount_232143 REAL DEFAULT 0.0,
        is_settled_232143 INTEGER DEFAULT 0,
        notes_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        settled_at_232143 TEXT,
        FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143),
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Challenges table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS challenges_232143 (
        challenge_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        description_232143 TEXT,
        type_232143 TEXT NOT NULL CHECK (type_232143 IN ('no_spend','savings_target','budget_limit','custom')),
        target_amount_232143 REAL,
        current_amount_232143 REAL DEFAULT 0.0,
        start_date_232143 TEXT NOT NULL,
        end_date_232143 TEXT NOT NULL,
        is_active_232143 INTEGER DEFAULT 1,
        is_completed_232143 INTEGER DEFAULT 0,
        completed_date_232143 TEXT,
        streak_days_232143 INTEGER DEFAULT 0,
        notes_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Investments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS investments_232143 (
        investment_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        type_232143 TEXT NOT NULL CHECK (type_232143 IN ('stock','mutual_fund','crypto','bond','gold','deposit','other')),
        quantity_232143 REAL NOT NULL,
        buy_price_232143 REAL NOT NULL,
        current_price_232143 REAL NOT NULL,
        buy_date_232143 TEXT NOT NULL,
        ticker_232143 TEXT,
        notes_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Transaction templates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS transaction_templates_232143 (
        template_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        name_232143 TEXT NOT NULL,
        amount_232143 REAL NOT NULL,
        type_232143 TEXT NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
        category_id_232143 TEXT,
        description_232143 TEXT,
        payment_method_232143 TEXT,
        account_id_232143 TEXT,
        is_recurring_232143 INTEGER DEFAULT 0,
        recurrence_pattern_232143 TEXT,
        tags_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
        FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143)
      )
    ''');

    // Net worth history table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS net_worth_history_232143 (
        snapshot_id_232143 TEXT PRIMARY KEY,
        user_id_232143 TEXT NOT NULL,
        snapshot_date_232143 TEXT NOT NULL,
        net_worth_232143 REAL NOT NULL,
        total_assets_232143 REAL NOT NULL,
        total_liabilities_232143 REAL NOT NULL,
        asset_breakdown_232143 TEXT,
        liability_breakdown_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
      )
    ''');

    // Exchange rates table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exchange_rates_232143 (
        rate_id_232143 TEXT PRIMARY KEY,
        from_currency_232143 TEXT NOT NULL,
        to_currency_232143 TEXT NOT NULL,
        rate_232143 REAL NOT NULL,
        last_updated_232143 TEXT NOT NULL,
        UNIQUE(from_currency_232143, to_currency_232143)
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX IF NOT EXISTS idx_users_email ON users_232143(email_232143)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_user_date ON transactions_232143(user_id_232143, transaction_date_232143)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_transactions_type_date ON transactions_232143(type_232143, transaction_date_232143)',
    );
    await db.execute('CREATE INDEX IF NOT EXISTS idx_categories_user ON categories_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_budgets_user ON budgets_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_user ON financial_goals_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_obligations_user ON financial_obligations_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_user ON debts_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments_232143(debt_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_splits_user ON expense_splits_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_investments_user ON investments_232143(user_id_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_challenges_user ON challenges_232143(user_id_232143)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_net_worth_user_date ON net_worth_history_232143(user_id_232143, snapshot_date_232143)',
    );

    // Goal contributions table (tracks which account contributed to which goal)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_contributions_232143 (
        contribution_id_232143 TEXT PRIMARY KEY,
        goal_id_232143 TEXT NOT NULL,
        account_id_232143 TEXT,
        amount_232143 REAL NOT NULL,
        contributed_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        note_232143 TEXT,
        FOREIGN KEY (goal_id_232143) REFERENCES financial_goals_232143(goal_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143) ON DELETE SET NULL
      )
    ''');

    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal ON goal_contributions_232143(goal_id_232143)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_goal_contributions_account ON goal_contributions_232143(account_id_232143)',
    );

    // === Phase 2: Alternative Recommendation Engine Tables ===

    // Place visits table — deduplicated places from transaction location data
    await db.execute('''
      CREATE TABLE IF NOT EXISTS place_visits_232143 (
        place_visit_id_232143 TEXT PRIMARY KEY,
        osm_node_id_232143 TEXT,
        place_name_232143 TEXT NOT NULL,
        latitude_232143 REAL NOT NULL,
        longitude_232143 REAL NOT NULL,
        address_232143 TEXT,
        category_232143 TEXT NOT NULL,
        osm_tag_232143 TEXT,
        visit_count_232143 INTEGER DEFAULT 1,
        total_spent_232143 REAL DEFAULT 0.0,
        first_visit_232143 TEXT NOT NULL,
        last_visit_232143 TEXT NOT NULL,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');

    // Price observations table — prices at specific places per category
    await db.execute('''
      CREATE TABLE IF NOT EXISTS price_observations_232143 (
        price_observation_id_232143 TEXT PRIMARY KEY,
        place_visit_id_232143 TEXT NOT NULL,
        category_232143 TEXT NOT NULL,
        price_232143 REAL NOT NULL,
        currency_232143 TEXT DEFAULT 'IDR',
        observed_at_232143 TEXT NOT NULL,
        source_232143 TEXT DEFAULT 'auto_extracted' CHECK (source_232143 IN ('self_reported','auto_extracted')),
        transaction_id_232143 TEXT,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (place_visit_id_232143) REFERENCES place_visits_232143(place_visit_id_232143) ON DELETE CASCADE,
        FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143) ON DELETE SET NULL
      )
    ''');

    // Alternative suggestions table — cached Overpass + price-based suggestions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alternative_suggestions_232143 (
        alternative_suggestion_id_232143 TEXT PRIMARY KEY,
        origin_place_visit_id_232143 TEXT NOT NULL,
        suggested_place_name_232143 TEXT NOT NULL,
        suggested_osm_node_id_232143 TEXT NOT NULL,
        suggested_latitude_232143 REAL NOT NULL,
        suggested_longitude_232143 REAL NOT NULL,
        distance_meters_232143 REAL NOT NULL,
        estimated_savings_232143 REAL,
        basis_232143 TEXT DEFAULT 'distance_only' CHECK (basis_232143 IN ('price','distance_only')),
        category_232143 TEXT NOT NULL,
        confidence_level_232143 INTEGER DEFAULT 0,
        generated_at_232143 TEXT NOT NULL,
        created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (origin_place_visit_id_232143) REFERENCES place_visits_232143(place_visit_id_232143) ON DELETE CASCADE
      )
    ''');

    // Indexes for the new tables
    await db.execute('CREATE INDEX IF NOT EXISTS idx_place_visits_category ON place_visits_232143(category_232143)');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_place_visits_osm ON place_visits_232143(osm_node_id_232143)');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_price_observations_place ON price_observations_232143(place_visit_id_232143)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_price_observations_category ON price_observations_232143(category_232143)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alternative_suggestions_origin ON alternative_suggestions_232143(origin_place_visit_id_232143)',
    );

    LoggerService.info('✅ Database schema created successfully');
  }

  /// Get current database version
  static int get currentVersion => 7;

  /// Upgrade database schema
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    LoggerService.info('📱 Upgrading database from version $oldVersion to $newVersion');

    // Wrap all migrations in a transaction for atomicity
    await db.transaction((txn) async {
      if (oldVersion < 2) {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS receipt_scans_232143 (
          receipt_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          image_path_232143 TEXT,
          merchant_232143 TEXT,
          total_amount_232143 REAL DEFAULT 0.0,
          receipt_date_232143 TEXT,
          raw_text_232143 TEXT,
          items_json_232143 TEXT,
          category_id_232143 TEXT,
          transaction_id_232143 TEXT,
          is_processed_232143 INTEGER DEFAULT 0,
          confidence_score_232143 REAL DEFAULT 0.0,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
          FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
          FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143)
        )
      ''');
        LoggerService.info('✅ Migrated to version 2: added receipt_scans table');
      }

      if (oldVersion < 3) {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS accounts_232143 (
          account_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          name_232143 TEXT NOT NULL,
          type_232143 TEXT NOT NULL CHECK (type_232143 IN ('cash','bank','e_wallet','credit_card','investment','other')),
          icon_232143 TEXT DEFAULT 'wallet',
          color_232143 TEXT DEFAULT '#8B5FBF',
          balance_232143 REAL DEFAULT 0.0,
          currency_232143 TEXT DEFAULT 'IDR',
          account_number_232143 TEXT,
          bank_name_232143 TEXT,
          is_active_232143 INTEGER DEFAULT 1,
          is_default_232143 INTEGER DEFAULT 0,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS debts_232143 (
          debt_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          name_232143 TEXT NOT NULL,
          original_amount_232143 REAL NOT NULL,
          current_balance_232143 REAL NOT NULL,
          interest_rate_232143 REAL DEFAULT 0.0,
          type_232143 TEXT NOT NULL CHECK (type_232143 IN ('personal','mortgage','student','credit_card','car','business','other')),
          start_date_232143 TEXT NOT NULL,
          due_date_232143 TEXT,
          monthly_payment_232143 REAL,
          creditor_name_232143 TEXT,
          notes_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS debt_payments_232143 (
          payment_id_232143 TEXT PRIMARY KEY,
          debt_id_232143 TEXT NOT NULL,
          user_id_232143 TEXT NOT NULL,
          amount_232143 REAL NOT NULL,
          payment_date_232143 TEXT NOT NULL,
          balance_after_232143 REAL NOT NULL,
          notes_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (debt_id_232143) REFERENCES debts_232143(debt_id_232143) ON DELETE CASCADE,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS subscriptions_232143 (
          subscription_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          name_232143 TEXT NOT NULL,
          cost_232143 REAL NOT NULL,
          cycle_232143 TEXT NOT NULL CHECK (cycle_232143 IN ('weekly','monthly','yearly')),
          category_232143 TEXT DEFAULT 'general',
          start_date_232143 TEXT NOT NULL,
          next_renewal_232143 TEXT,
          is_active_232143 INTEGER DEFAULT 1,
          notes_232143 TEXT,
          account_id_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
          FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143)
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS tags_232143 (
          tag_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          name_232143 TEXT NOT NULL,
          color_232143 TEXT DEFAULT '#8B5FBF',
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_tags_232143 (
          transaction_id_232143 TEXT NOT NULL,
          tag_id_232143 TEXT NOT NULL,
          PRIMARY KEY (transaction_id_232143, tag_id_232143),
          FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143) ON DELETE CASCADE,
          FOREIGN KEY (tag_id_232143) REFERENCES tags_232143(tag_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS expense_splits_232143 (
          split_id_232143 TEXT PRIMARY KEY,
          transaction_id_232143 TEXT,
          user_id_232143 TEXT NOT NULL,
          participant_name_232143 TEXT NOT NULL,
          participant_phone_232143 TEXT,
          amount_232143 REAL NOT NULL,
          paid_amount_232143 REAL DEFAULT 0.0,
          is_settled_232143 INTEGER DEFAULT 0,
          notes_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          settled_at_232143 TEXT,
          FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143),
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS challenges_232143 (
          challenge_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          name_232143 TEXT NOT NULL,
          description_232143 TEXT,
          type_232143 TEXT NOT NULL CHECK (type_232143 IN ('no_spend','savings_target','budget_limit','custom')),
          target_amount_232143 REAL,
          current_amount_232143 REAL DEFAULT 0.0,
          start_date_232143 TEXT NOT NULL,
          end_date_232143 TEXT NOT NULL,
          is_active_232143 INTEGER DEFAULT 1,
          is_completed_232143 INTEGER DEFAULT 0,
          completed_date_232143 TEXT,
          streak_days_232143 INTEGER DEFAULT 0,
          notes_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS investments_232143 (
          investment_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          name_232143 TEXT NOT NULL,
          type_232143 TEXT NOT NULL CHECK (type_232143 IN ('stock','mutual_fund','crypto','bond','gold','deposit','other')),
          quantity_232143 REAL NOT NULL,
          buy_price_232143 REAL NOT NULL,
          current_price_232143 REAL NOT NULL,
          buy_date_232143 TEXT NOT NULL,
          ticker_232143 TEXT,
          notes_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS transaction_templates_232143 (
          template_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          name_232143 TEXT NOT NULL,
          amount_232143 REAL NOT NULL,
          type_232143 TEXT NOT NULL CHECK (type_232143 IN ('income','expense','transfer')),
          category_id_232143 TEXT,
          description_232143 TEXT,
          payment_method_232143 TEXT,
          account_id_232143 TEXT,
          is_recurring_232143 INTEGER DEFAULT 0,
          recurrence_pattern_232143 TEXT,
          tags_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE,
          FOREIGN KEY (category_id_232143) REFERENCES categories_232143(category_id_232143),
          FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143)
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS net_worth_history_232143 (
          snapshot_id_232143 TEXT PRIMARY KEY,
          user_id_232143 TEXT NOT NULL,
          snapshot_date_232143 TEXT NOT NULL,
          net_worth_232143 REAL NOT NULL,
          total_assets_232143 REAL NOT NULL,
          total_liabilities_232143 REAL NOT NULL,
          asset_breakdown_232143 TEXT,
          liability_breakdown_232143 TEXT,
          created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id_232143) REFERENCES users_232143(user_id_232143) ON DELETE CASCADE
        )
      ''');

        await db.execute('''
        CREATE TABLE IF NOT EXISTS exchange_rates_232143 (
          rate_id_232143 TEXT PRIMARY KEY,
          from_currency_232143 TEXT NOT NULL,
          to_currency_232143 TEXT NOT NULL,
          rate_232143 REAL NOT NULL,
          last_updated_232143 TEXT NOT NULL,
          UNIQUE(from_currency_232143, to_currency_232143)
        )
      ''');

        await db.execute('CREATE INDEX IF NOT EXISTS idx_accounts_user ON accounts_232143(user_id_232143)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_debts_user ON debts_232143(user_id_232143)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_debt_payments_debt ON debt_payments_232143(debt_id_232143)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_subscriptions_user ON subscriptions_232143(user_id_232143)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_splits_user ON expense_splits_232143(user_id_232143)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_investments_user ON investments_232143(user_id_232143)');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_challenges_user ON challenges_232143(user_id_232143)');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_net_worth_user_date ON net_worth_history_232143(user_id_232143, snapshot_date_232143)',
        );

        LoggerService.info(
          '✅ Migrated to version 3: added accounts, debts, subscriptions, tags, splits, challenges, investments, templates, net worth, exchange rates',
        );
      }

      if (oldVersion < 4) {
        await db.execute('ALTER TABLE transactions_232143 ADD COLUMN account_id_232143 TEXT');
        LoggerService.info('✅ Migrated to version 4: added account_id to transactions');
      }

      if (oldVersion < 5) {
        await db.execute('''
        CREATE TABLE IF NOT EXISTS goal_contributions_232143 (
          contribution_id_232143 TEXT PRIMARY KEY,
          goal_id_232143 TEXT NOT NULL,
          account_id_232143 TEXT,
          amount_232143 REAL NOT NULL,
          contributed_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
          note_232143 TEXT,
          FOREIGN KEY (goal_id_232143) REFERENCES financial_goals_232143(goal_id_232143) ON DELETE CASCADE,
          FOREIGN KEY (account_id_232143) REFERENCES accounts_232143(account_id_232143) ON DELETE SET NULL
        )
      ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_goal_contributions_goal ON goal_contributions_232143(goal_id_232143)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_goal_contributions_account ON goal_contributions_232143(account_id_232143)',
        );

        LoggerService.info('✅ Migrated to version 5: added goal_contributions table');
      }

      if (oldVersion < 6) {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS place_visits_232143 (
            place_visit_id_232143 TEXT PRIMARY KEY,
            osm_node_id_232143 TEXT,
            place_name_232143 TEXT NOT NULL,
            latitude_232143 REAL NOT NULL,
            longitude_232143 REAL NOT NULL,
            address_232143 TEXT,
            category_232143 TEXT NOT NULL,
            osm_tag_232143 TEXT,
            visit_count_232143 INTEGER DEFAULT 1,
            total_spent_232143 REAL DEFAULT 0.0,
            first_visit_232143 TEXT NOT NULL,
            last_visit_232143 TEXT NOT NULL,
            created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS price_observations_232143 (
            price_observation_id_232143 TEXT PRIMARY KEY,
            place_visit_id_232143 TEXT NOT NULL,
            category_232143 TEXT NOT NULL,
            price_232143 REAL NOT NULL,
            currency_232143 TEXT DEFAULT 'IDR',
            observed_at_232143 TEXT NOT NULL,
            source_232143 TEXT DEFAULT 'auto_extracted' CHECK (source_232143 IN ('self_reported','auto_extracted')),
            transaction_id_232143 TEXT,
            created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (place_visit_id_232143) REFERENCES place_visits_232143(place_visit_id_232143) ON DELETE CASCADE,
            FOREIGN KEY (transaction_id_232143) REFERENCES transactions_232143(transaction_id_232143) ON DELETE SET NULL
          )
        ''');

        await db.execute('''
          CREATE TABLE IF NOT EXISTS alternative_suggestions_232143 (
            alternative_suggestion_id_232143 TEXT PRIMARY KEY,
            origin_place_visit_id_232143 TEXT NOT NULL,
            suggested_place_name_232143 TEXT NOT NULL,
            suggested_osm_node_id_232143 TEXT NOT NULL,
            suggested_latitude_232143 REAL NOT NULL,
            suggested_longitude_232143 REAL NOT NULL,
            distance_meters_232143 REAL NOT NULL,
            estimated_savings_232143 REAL,
            basis_232143 TEXT DEFAULT 'distance_only' CHECK (basis_232143 IN ('price','distance_only')),
            category_232143 TEXT NOT NULL,
            confidence_level_232143 INTEGER DEFAULT 0,
            generated_at_232143 TEXT NOT NULL,
            created_at_232143 TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (origin_place_visit_id_232143) REFERENCES place_visits_232143(place_visit_id_232143) ON DELETE CASCADE
          )
        ''');

        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_place_visits_category ON place_visits_232143(category_232143)',
        );
        await db.execute('CREATE INDEX IF NOT EXISTS idx_place_visits_osm ON place_visits_232143(osm_node_id_232143)');
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_price_observations_place ON price_observations_232143(place_visit_id_232143)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_price_observations_category ON price_observations_232143(category_232143)',
        );
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_alternative_suggestions_origin ON alternative_suggestions_232143(origin_place_visit_id_232143)',
        );

        LoggerService.info(
          '✅ Migrated to version 6: added place_visits, price_observations, alternative_suggestions tables',
        );
      }

      if (oldVersion < 7) {
        // Add unified type columns to financial_obligations_232143
        await txn.execute(
          "ALTER TABLE financial_obligations_232143 ADD COLUMN type_232143 TEXT NOT NULL DEFAULT 'bill'",
        );
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN original_amount_232143 REAL');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN current_balance_232143 REAL');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN interest_rate_232143 REAL');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN debt_type_232143 TEXT');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN creditor_name_232143 TEXT');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN notes_232143 TEXT');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN subscription_cycle_232143 TEXT');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN next_renewal_232143 TEXT');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN is_active_232143 INTEGER DEFAULT 1');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN account_id_232143 TEXT');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN category_232143 TEXT');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN minimum_payment_232143 REAL');
        await txn.execute('ALTER TABLE financial_obligations_232143 ADD COLUMN payoff_strategy_232143 TEXT');
        await txn.execute(
          'ALTER TABLE financial_obligations_232143 ADD COLUMN is_subscription_232143 INTEGER DEFAULT 0',
        );

        // Migrate debts_232143 → financial_obligations_232143
        await txn.execute('''
          INSERT INTO financial_obligations_232143 (
            obligation_id_232143, user_id_232143, name_232143, amount_232143,
            due_date_232143, frequency_232143, is_paid_232143, created_at_232143,
            updated_at_232143, type_232143, original_amount_232143,
            current_balance_232143, interest_rate_232143, debt_type_232143,
            creditor_name_232143, notes_232143, is_active_232143, description_232143,
            minimum_payment_232143
          )
          SELECT
            'mig_debt_' || debt_id_232143, user_id_232143, name_232143,
            COALESCE(monthly_payment_232143, 0.0),
            COALESCE(due_date_232143, start_date_232143),
            'monthly', 0, created_at_232143, updated_at_232143,
            'debt', original_amount_232143, current_balance_232143,
            COALESCE(interest_rate_232143, 0.0), type_232143,
            creditor_name_232143, notes_232143, 1, notes_232143,
            monthly_payment_232143
          FROM debts_232143
        ''');

        // Migrate subscriptions_232143 → financial_obligations_232143
        await txn.execute('''
          INSERT INTO financial_obligations_232143 (
            obligation_id_232143, user_id_232143, name_232143, amount_232143,
            due_date_232143, frequency_232143, is_paid_232143, created_at_232143,
            updated_at_232143, type_232143, subscription_cycle_232143,
            next_renewal_232143, is_active_232143, account_id_232143,
            notes_232143, description_232143, category_232143,
            is_subscription_232143
          )
          SELECT
            'mig_sub_' || subscription_id_232143, user_id_232143, name_232143,
            cost_232143, COALESCE(next_renewal_232143, start_date_232143),
            CASE cycle_232143
              WHEN 'weekly' THEN 'weekly'
              WHEN 'yearly' THEN 'yearly'
              ELSE 'monthly'
            END, 0, created_at_232143, updated_at_232143,
            'subscription', cycle_232143, next_renewal_232143,
            is_active_232143, account_id_232143, notes_232143,
            notes_232143, category_232143, 1
          FROM subscriptions_232143
        ''');

        LoggerService.info(
          '✅ Migrated to version 7: unified financial_obligations with type, debt, subscription columns + migrated existing data',
        );
      }
    });
  }

  /// Handle database downgrade (prevents opening with older app version)
  Future<void> _onDowngrade(Database db, int oldVersion, int newVersion) async {
    LoggerService.warning(
      '⚠️ Database downgrade detected: $oldVersion → $newVersion. '
      'This is not supported — re-creating schema.',
    );
    // Drop all user-created tables and re-create to prevent data corruption
    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%' AND name NOT LIKE 'android_%'",
    );
    for (final table in tables) {
      await db.execute('DROP TABLE IF EXISTS ${table['name']}');
    }
    await _onCreate(db, currentVersion);
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
