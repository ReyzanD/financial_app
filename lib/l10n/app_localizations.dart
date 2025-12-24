import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// App Localizations untuk multi-language support
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'id': {
      // Common
      'app_name': 'Financial App',
      'loading': 'Memuat...',
      'error': 'Terjadi kesalahan',
      'retry': 'Coba Lagi',
      'cancel': 'Batal',
      'save': 'Simpan',
      'delete': 'Hapus',
      'edit': 'Edit',
      'add': 'Tambah',
      'search': 'Cari',
      'filter': 'Filter',
      
      // Home
      'home': 'Beranda',
      'transactions': 'Transaksi',
      'budgets': 'Anggaran',
      'goals': 'Tujuan',
      'analytics': 'Analitik',
      
      // Transactions
      'add_transaction': 'Tambah Transaksi',
      'income': 'Pemasukan',
      'expense': 'Pengeluaran',
      'transfer': 'Transfer',
      'amount': 'Jumlah',
      'category': 'Kategori',
      'description': 'Deskripsi',
      'date': 'Tanggal',
      'location': 'Lokasi',
      
      // Budgets
      'budget': 'Anggaran',
      'budget_progress': 'Progress Anggaran',
      'spent': 'Terpakai',
      'remaining': 'Sisa',
      'over_budget': 'Melebihi Anggaran',
      
      // Goals
      'goal': 'Tujuan',
      'target': 'Target',
      'current': 'Saat Ini',
      'progress': 'Progress',
      
      // Analytics
      'total_income': 'Total Pemasukan',
      'total_expense': 'Total Pengeluaran',
      'balance': 'Saldo',
      'savings_rate': 'Tingkat Tabungan',
      
      // Settings
      'settings': 'Pengaturan',
      'theme': 'Tema',
      'language': 'Bahasa',
      'dark_mode': 'Mode Gelap',
      'light_mode': 'Mode Terang',
      'system': 'Sistem',
      
      // Notifications
      'notifications': 'Notifikasi',
      'budget_alerts': 'Peringatan Anggaran',
      'bill_reminders': 'Pengingat Tagihan',
      
      // Onboarding
      'welcome': 'Selamat Datang',
      'skip': 'Lewati',
      'next': 'Lanjut',
      'get_started': 'Mulai',
    },
    'en': {
      // Common
      'app_name': 'Financial App',
      'loading': 'Loading...',
      'error': 'An error occurred',
      'retry': 'Retry',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search',
      'filter': 'Filter',
      
      // Home
      'home': 'Home',
      'transactions': 'Transactions',
      'budgets': 'Budgets',
      'goals': 'Goals',
      'analytics': 'Analytics',
      
      // Transactions
      'add_transaction': 'Add Transaction',
      'income': 'Income',
      'expense': 'Expense',
      'transfer': 'Transfer',
      'amount': 'Amount',
      'category': 'Category',
      'description': 'Description',
      'date': 'Date',
      'location': 'Location',
      
      // Budgets
      'budget': 'Budget',
      'budget_progress': 'Budget Progress',
      'spent': 'Spent',
      'remaining': 'Remaining',
      'over_budget': 'Over Budget',
      
      // Goals
      'goal': 'Goal',
      'target': 'Target',
      'current': 'Current',
      'progress': 'Progress',
      
      // Analytics
      'total_income': 'Total Income',
      'total_expense': 'Total Expense',
      'balance': 'Balance',
      'savings_rate': 'Savings Rate',
      
      // Settings
      'settings': 'Settings',
      'theme': 'Theme',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'light_mode': 'Light Mode',
      'system': 'System',
      
      // Notifications
      'notifications': 'Notifications',
      'budget_alerts': 'Budget Alerts',
      'bill_reminders': 'Bill Reminders',
      
      // Onboarding
      'welcome': 'Welcome',
      'skip': 'Skip',
      'next': 'Next',
      'get_started': 'Get Started',
    },
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ?? key;
  }

  // Getters for common strings
  String get appName => translate('app_name');
  String get loading => translate('loading');
  String get error => translate('error');
  String get retry => translate('retry');
  String get cancel => translate('cancel');
  String get save => translate('save');
  String get delete => translate('delete');
  String get edit => translate('edit');
  String get add => translate('add');
  String get search => translate('search');
  String get filter => translate('filter');
  String get home => translate('home');
  String get transactions => translate('transactions');
  String get budgets => translate('budgets');
  String get goals => translate('goals');
  String get analytics => translate('analytics');
  String get addTransaction => translate('add_transaction');
  String get income => translate('income');
  String get expense => translate('expense');
  String get transfer => translate('transfer');
  String get amount => translate('amount');
  String get category => translate('category');
  String get description => translate('description');
  String get date => translate('date');
  String get location => translate('location');
  String get budget => translate('budget');
  String get budgetProgress => translate('budget_progress');
  String get spent => translate('spent');
  String get remaining => translate('remaining');
  String get overBudget => translate('over_budget');
  String get goal => translate('goal');
  String get target => translate('target');
  String get current => translate('current');
  String get progress => translate('progress');
  String get totalIncome => translate('total_income');
  String get totalExpense => translate('total_expense');
  String get balance => translate('balance');
  String get savingsRate => translate('savings_rate');
  String get settings => translate('settings');
  String get theme => translate('theme');
  String get language => translate('language');
  String get darkMode => translate('dark_mode');
  String get lightMode => translate('light_mode');
  String get system => translate('system');
  String get notifications => translate('notifications');
  String get budgetAlerts => translate('budget_alerts');
  String get billReminders => translate('bill_reminders');
  String get welcome => translate('welcome');
  String get skip => translate('skip');
  String get next => translate('next');
  String get getStarted => translate('get_started');

  // Date formatting
  String formatDate(DateTime date) {
    final formatter = DateFormat.yMMMd(locale.languageCode);
    return formatter.format(date);
  }

  // Currency formatting
  String formatCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: locale.languageCode == 'id' ? 'id_ID' : 'en_US',
      symbol: locale.languageCode == 'id' ? 'Rp ' : '\$',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Number formatting
  String formatNumber(double number) {
    final formatter = NumberFormat.decimalPattern(locale.languageCode);
    return formatter.format(number);
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['id', 'en'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

