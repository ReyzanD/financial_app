import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_id.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('id'),
  ];

  /// No description provided for @about_app.
  ///
  /// In en, this message translates to:
  /// **'About App'**
  String get about_app;

  /// No description provided for @about_financial_app.
  ///
  /// In en, this message translates to:
  /// **'About Financial App'**
  String get about_financial_app;

  /// No description provided for @account.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get account;

  /// No description provided for @account_information.
  ///
  /// In en, this message translates to:
  /// **'Account Information'**
  String get account_information;

  /// No description provided for @achieve_financial_goals.
  ///
  /// In en, this message translates to:
  /// **'Achieve financial goals'**
  String get achieve_financial_goals;

  /// No description provided for @achieve_goals.
  ///
  /// In en, this message translates to:
  /// **'Achieve Goals'**
  String get achieve_goals;

  /// No description provided for @actions.
  ///
  /// In en, this message translates to:
  /// **'Actions'**
  String get actions;

  /// No description provided for @active.
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @add_description.
  ///
  /// In en, this message translates to:
  /// **'Add description...'**
  String get add_description;

  /// No description provided for @add_expense.
  ///
  /// In en, this message translates to:
  /// **'Add Expense'**
  String get add_expense;

  /// No description provided for @add_income.
  ///
  /// In en, this message translates to:
  /// **'Add Income'**
  String get add_income;

  /// No description provided for @add_income_first.
  ///
  /// In en, this message translates to:
  /// **'Add income first or reduce the expense amount.'**
  String get add_income_first;

  /// No description provided for @add_obligation.
  ///
  /// In en, this message translates to:
  /// **'Add Obligation'**
  String get add_obligation;

  /// No description provided for @add_obligation_hint.
  ///
  /// In en, this message translates to:
  /// **'Tap + to add a bill'**
  String get add_obligation_hint;

  /// No description provided for @add_recurring_transaction.
  ///
  /// In en, this message translates to:
  /// **'Add Recurring Transaction'**
  String get add_recurring_transaction;

  /// No description provided for @add_target.
  ///
  /// In en, this message translates to:
  /// **'Add Target'**
  String get add_target;

  /// No description provided for @add_transaction.
  ///
  /// In en, this message translates to:
  /// **'Add Transaction'**
  String get add_transaction;

  /// No description provided for @ai_recommendations.
  ///
  /// In en, this message translates to:
  /// **'AI Recommendations'**
  String get ai_recommendations;

  /// No description provided for @all.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// No description provided for @all_categories.
  ///
  /// In en, this message translates to:
  /// **'All Categories'**
  String get all_categories;

  /// No description provided for @allow_access.
  ///
  /// In en, this message translates to:
  /// **'Allow Access'**
  String get allow_access;

  /// No description provided for @amount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get amount;

  /// No description provided for @analytics.
  ///
  /// In en, this message translates to:
  /// **'Analytics'**
  String get analytics;

  /// No description provided for @app.
  ///
  /// In en, this message translates to:
  /// **'App'**
  String get app;

  /// No description provided for @app_description.
  ///
  /// In en, this message translates to:
  /// **'Personal financial management app with AI features to help you manage expenses and achieve financial goals.'**
  String get app_description;

  /// No description provided for @app_name.
  ///
  /// In en, this message translates to:
  /// **'Financial App'**
  String get app_name;

  /// No description provided for @app_permissions.
  ///
  /// In en, this message translates to:
  /// **'App Permissions'**
  String get app_permissions;

  /// No description provided for @app_stores_data_locally.
  ///
  /// In en, this message translates to:
  /// **'This app stores your financial data locally and securely. Data is only stored on your device and encrypted servers.'**
  String get app_stores_data_locally;

  /// No description provided for @app_version.
  ///
  /// In en, this message translates to:
  /// **'Version 1.0.0'**
  String get app_version;

  /// No description provided for @apply_filter.
  ///
  /// In en, this message translates to:
  /// **'Apply Filter'**
  String get apply_filter;

  /// No description provided for @authentication_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Authentication cancelled'**
  String get authentication_cancelled;

  /// No description provided for @authentication_required.
  ///
  /// In en, this message translates to:
  /// **'Authentication Required'**
  String get authentication_required;

  /// No description provided for @authentication_required_for_delete.
  ///
  /// In en, this message translates to:
  /// **'Authentication required to delete account'**
  String get authentication_required_for_delete;

  /// No description provided for @authentication_required_for_export.
  ///
  /// In en, this message translates to:
  /// **'Authentication required to export data'**
  String get authentication_required_for_export;

  /// No description provided for @available_balance.
  ///
  /// In en, this message translates to:
  /// **'Available Balance'**
  String get available_balance;

  /// No description provided for @backup_created_and_ready.
  ///
  /// In en, this message translates to:
  /// **'Backup created and ready to share!'**
  String get backup_created_and_ready;

  /// No description provided for @backup_created_successfully.
  ///
  /// In en, this message translates to:
  /// **'Backup created successfully!'**
  String get backup_created_successfully;

  /// No description provided for @backup_deleted.
  ///
  /// In en, this message translates to:
  /// **'Backup deleted'**
  String get backup_deleted;

  /// No description provided for @backup_description.
  ///
  /// In en, this message translates to:
  /// **'Backup your financial data regularly. Backup files can be shared to email or cloud storage.'**
  String get backup_description;

  /// No description provided for @backup_restore.
  ///
  /// In en, this message translates to:
  /// **'Backup & Restore'**
  String get backup_restore;

  /// No description provided for @backup_saved.
  ///
  /// In en, this message translates to:
  /// **'Backup Saved'**
  String get backup_saved;

  /// No description provided for @bahasa_indonesia.
  ///
  /// In en, this message translates to:
  /// **'Bahasa Indonesia'**
  String get bahasa_indonesia;

  /// No description provided for @balance.
  ///
  /// In en, this message translates to:
  /// **'Balance'**
  String get balance;

  /// No description provided for @bill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get bill;

  /// No description provided for @bill_reminders.
  ///
  /// In en, this message translates to:
  /// **'Bill Reminders'**
  String get bill_reminders;

  /// No description provided for @budget.
  ///
  /// In en, this message translates to:
  /// **'Budget'**
  String get budget;

  /// No description provided for @budget_alerts.
  ///
  /// In en, this message translates to:
  /// **'Budget Alerts'**
  String get budget_alerts;

  /// No description provided for @budget_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Budget deleted successfully.'**
  String get budget_deleted_successfully;

  /// No description provided for @budget_forecasting.
  ///
  /// In en, this message translates to:
  /// **'Budget forecasting'**
  String get budget_forecasting;

  /// No description provided for @budget_progress.
  ///
  /// In en, this message translates to:
  /// **'Budget Progress'**
  String get budget_progress;

  /// No description provided for @budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get budgets;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @cannot_recognize_amount.
  ///
  /// In en, this message translates to:
  /// **'Cannot recognize amount from'**
  String get cannot_recognize_amount;

  /// No description provided for @cannot_scan_receipt.
  ///
  /// In en, this message translates to:
  /// **'Cannot scan receipt. Make sure the image is clear and contains text.'**
  String get cannot_scan_receipt;

  /// No description provided for @cannot_scan_receipt_try_again.
  ///
  /// In en, this message translates to:
  /// **'Cannot scan receipt. Try again.'**
  String get cannot_scan_receipt_try_again;

  /// No description provided for @car_loan.
  ///
  /// In en, this message translates to:
  /// **'Car Loan'**
  String get car_loan;

  /// No description provided for @category.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get category;

  /// No description provided for @category_breakdown.
  ///
  /// In en, this message translates to:
  /// **'Category Breakdown'**
  String get category_breakdown;

  /// No description provided for @change.
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// No description provided for @change_app_security_pin.
  ///
  /// In en, this message translates to:
  /// **'Change app security PIN'**
  String get change_app_security_pin;

  /// No description provided for @change_login_password.
  ///
  /// In en, this message translates to:
  /// **'Change login password'**
  String get change_login_password;

  /// No description provided for @change_password.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password;

  /// No description provided for @change_password_security.
  ///
  /// In en, this message translates to:
  /// **'Change password and security settings'**
  String get change_password_security;

  /// No description provided for @change_password_title.
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get change_password_title;

  /// No description provided for @change_pin.
  ///
  /// In en, this message translates to:
  /// **'Change PIN'**
  String get change_pin;

  /// No description provided for @choose_from_gallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from Gallery'**
  String get choose_from_gallery;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @confirm_delete_budget.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this budget?'**
  String get confirm_delete_budget;

  /// No description provided for @confirm_new_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm new password'**
  String get confirm_new_password;

  /// No description provided for @confirm_password.
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirm_password;

  /// No description provided for @confirm_pin.
  ///
  /// In en, this message translates to:
  /// **'Confirm PIN'**
  String get confirm_pin;

  /// No description provided for @continueText.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueText;

  /// No description provided for @control_expenses.
  ///
  /// In en, this message translates to:
  /// **'Control your expenses'**
  String get control_expenses;

  /// No description provided for @create_budget.
  ///
  /// In en, this message translates to:
  /// **'Create Budget'**
  String get create_budget;

  /// No description provided for @create_pin.
  ///
  /// In en, this message translates to:
  /// **'Create PIN'**
  String get create_pin;

  /// No description provided for @create_pin_to_secure.
  ///
  /// In en, this message translates to:
  /// **'Create PIN to secure your account'**
  String get create_pin_to_secure;

  /// No description provided for @credit_card.
  ///
  /// In en, this message translates to:
  /// **'Credit Card'**
  String get credit_card;

  /// No description provided for @current.
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// No description provided for @current_balance.
  ///
  /// In en, this message translates to:
  /// **'Current Balance'**
  String get current_balance;

  /// No description provided for @current_balance_optional.
  ///
  /// In en, this message translates to:
  /// **'Current Balance (Optional)'**
  String get current_balance_optional;

  /// No description provided for @cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get cycle;

  /// No description provided for @dark_mode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get dark_mode;

  /// No description provided for @dashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get dashboard;

  /// No description provided for @data_exported_successfully.
  ///
  /// In en, this message translates to:
  /// **'Data Exported Successfully'**
  String get data_exported_successfully;

  /// No description provided for @data_privacy.
  ///
  /// In en, this message translates to:
  /// **'Data & Privacy'**
  String get data_privacy;

  /// No description provided for @data_saved_to_clipboard.
  ///
  /// In en, this message translates to:
  /// **'Data saved to clipboard. Keep it safe!'**
  String get data_saved_to_clipboard;

  /// No description provided for @date.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date;

  /// No description provided for @date_label.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get date_label;

  /// No description provided for @days.
  ///
  /// In en, this message translates to:
  /// **'days'**
  String get days;

  /// No description provided for @days_late.
  ///
  /// In en, this message translates to:
  /// **'days late'**
  String get days_late;

  /// No description provided for @days_left.
  ///
  /// In en, this message translates to:
  /// **'days left'**
  String get days_left;

  /// No description provided for @days_remaining.
  ///
  /// In en, this message translates to:
  /// **'Days Remaining'**
  String get days_remaining;

  /// No description provided for @debt.
  ///
  /// In en, this message translates to:
  /// **'Debt'**
  String get debt;

  /// No description provided for @debt_payment.
  ///
  /// In en, this message translates to:
  /// **'Debt Payment'**
  String get debt_payment;

  /// No description provided for @default_tab.
  ///
  /// In en, this message translates to:
  /// **'Default Tab'**
  String get default_tab;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @delete_account.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account;

  /// No description provided for @delete_account_and_all_data.
  ///
  /// In en, this message translates to:
  /// **'Delete account and all data'**
  String get delete_account_and_all_data;

  /// No description provided for @delete_account_confirmation.
  ///
  /// In en, this message translates to:
  /// **'This action will permanently delete your account and all financial data. Are you sure you want to continue?'**
  String get delete_account_confirmation;

  /// No description provided for @delete_account_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Account'**
  String get delete_account_title;

  /// No description provided for @delete_all_history.
  ///
  /// In en, this message translates to:
  /// **'Delete All History'**
  String get delete_all_history;

  /// No description provided for @delete_backup_message.
  ///
  /// In en, this message translates to:
  /// **'This backup will be permanently deleted.'**
  String get delete_backup_message;

  /// No description provided for @delete_backup_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Backup?'**
  String get delete_backup_title;

  /// No description provided for @delete_bill_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the bill'**
  String get delete_bill_confirm;

  /// No description provided for @delete_budget.
  ///
  /// In en, this message translates to:
  /// **'Delete Budget'**
  String get delete_budget;

  /// No description provided for @delete_history_question.
  ///
  /// In en, this message translates to:
  /// **'Delete History?'**
  String get delete_history_question;

  /// No description provided for @delete_label.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete_label;

  /// No description provided for @delete_notification_history_message.
  ///
  /// In en, this message translates to:
  /// **'All notification history will be deleted'**
  String get delete_notification_history_message;

  /// No description provided for @delete_obligation.
  ///
  /// In en, this message translates to:
  /// **'Delete Obligation'**
  String get delete_obligation;

  /// No description provided for @delete_obligation_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the obligation'**
  String get delete_obligation_confirm;

  /// No description provided for @delete_payment.
  ///
  /// In en, this message translates to:
  /// **'Delete Payment'**
  String get delete_payment;

  /// No description provided for @delete_payment_confirm.
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete this payment?'**
  String get delete_payment_confirm;

  /// No description provided for @delete_recurring_transaction_message.
  ///
  /// In en, this message translates to:
  /// **'will be deleted permanently.'**
  String get delete_recurring_transaction_message;

  /// No description provided for @delete_recurring_transaction_title.
  ///
  /// In en, this message translates to:
  /// **'Delete Recurring Transaction?'**
  String get delete_recurring_transaction_title;

  /// No description provided for @description.
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// No description provided for @details.
  ///
  /// In en, this message translates to:
  /// **'Details'**
  String get details;

  /// No description provided for @download_financial_data.
  ///
  /// In en, this message translates to:
  /// **'Download your financial data'**
  String get download_financial_data;

  /// No description provided for @due_date.
  ///
  /// In en, this message translates to:
  /// **'Due Date'**
  String get due_date;

  /// No description provided for @due_date_day.
  ///
  /// In en, this message translates to:
  /// **'Due Date (Day)'**
  String get due_date_day;

  /// No description provided for @due_soon.
  ///
  /// In en, this message translates to:
  /// **'Due Soon'**
  String get due_soon;

  /// No description provided for @due_this_week.
  ///
  /// In en, this message translates to:
  /// **'Due This Week'**
  String get due_this_week;

  /// No description provided for @duplicate_transaction.
  ///
  /// In en, this message translates to:
  /// **'Duplicate Transaction?'**
  String get duplicate_transaction;

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @edit_feature_coming_soon.
  ///
  /// In en, this message translates to:
  /// **'Edit feature coming soon'**
  String get edit_feature_coming_soon;

  /// No description provided for @edit_obligation.
  ///
  /// In en, this message translates to:
  /// **'Edit Obligation'**
  String get edit_obligation;

  /// No description provided for @education.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @emergency_fund.
  ///
  /// In en, this message translates to:
  /// **'Emergency Fund'**
  String get emergency_fund;

  /// No description provided for @enable_for_local_recommendations.
  ///
  /// In en, this message translates to:
  /// **'Enable for local recommendations'**
  String get enable_for_local_recommendations;

  /// No description provided for @enable_reminders.
  ///
  /// In en, this message translates to:
  /// **'Enable Reminders'**
  String get enable_reminders;

  /// No description provided for @english.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// No description provided for @enter_new_password.
  ///
  /// In en, this message translates to:
  /// **'Enter new password'**
  String get enter_new_password;

  /// No description provided for @enter_old_password.
  ///
  /// In en, this message translates to:
  /// **'Enter old password'**
  String get enter_old_password;

  /// No description provided for @enter_pin.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN'**
  String get enter_pin;

  /// No description provided for @enter_pin_again.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN again to confirm'**
  String get enter_pin_again;

  /// No description provided for @enter_pin_to_unlock.
  ///
  /// In en, this message translates to:
  /// **'Enter PIN to unlock the app'**
  String get enter_pin_to_unlock;

  /// No description provided for @entertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get entertainment;

  /// No description provided for @error.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get error;

  /// No description provided for @error_scanning.
  ///
  /// In en, this message translates to:
  /// **'Error scanning'**
  String get error_scanning;

  /// No description provided for @error_scanning_receipt.
  ///
  /// In en, this message translates to:
  /// **'An error occurred while scanning receipt. Please try again.'**
  String get error_scanning_receipt;

  /// No description provided for @every_day_at.
  ///
  /// In en, this message translates to:
  /// **'Every day at'**
  String get every_day_at;

  /// No description provided for @every_month.
  ///
  /// In en, this message translates to:
  /// **'every month'**
  String get every_month;

  /// No description provided for @expense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get expense;

  /// No description provided for @export_completed_on.
  ///
  /// In en, this message translates to:
  /// **'Export completed on:'**
  String get export_completed_on;

  /// No description provided for @export_data.
  ///
  /// In en, this message translates to:
  /// **'Export Data'**
  String get export_data;

  /// No description provided for @exported_data.
  ///
  /// In en, this message translates to:
  /// **'Exported data:'**
  String get exported_data;

  /// No description provided for @exporting_data.
  ///
  /// In en, this message translates to:
  /// **'Exporting data...'**
  String get exporting_data;

  /// No description provided for @failed.
  ///
  /// In en, this message translates to:
  /// **'Failed'**
  String get failed;

  /// No description provided for @failed_to_create_backup.
  ///
  /// In en, this message translates to:
  /// **'Failed to create backup'**
  String get failed_to_create_backup;

  /// No description provided for @failed_to_delete.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failed_to_delete;

  /// No description provided for @failed_to_delete_notification.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete'**
  String get failed_to_delete_notification;

  /// No description provided for @failed_to_get_location.
  ///
  /// In en, this message translates to:
  /// **'Failed to get location. Make sure location permission is enabled.'**
  String get failed_to_get_location;

  /// No description provided for @failed_to_load_analytics.
  ///
  /// In en, this message translates to:
  /// **'Failed to load analytics'**
  String get failed_to_load_analytics;

  /// No description provided for @failed_to_load_backup.
  ///
  /// In en, this message translates to:
  /// **'Failed to load backup'**
  String get failed_to_load_backup;

  /// No description provided for @failed_to_load_categories.
  ///
  /// In en, this message translates to:
  /// **'Failed to load categories'**
  String get failed_to_load_categories;

  /// No description provided for @failed_to_load_info.
  ///
  /// In en, this message translates to:
  /// **'Failed to load info'**
  String get failed_to_load_info;

  /// No description provided for @failed_to_load_profile.
  ///
  /// In en, this message translates to:
  /// **'Failed to load profile'**
  String get failed_to_load_profile;

  /// No description provided for @failed_to_share.
  ///
  /// In en, this message translates to:
  /// **'Failed to share'**
  String get failed_to_share;

  /// No description provided for @family_members_count.
  ///
  /// In en, this message translates to:
  /// **'Family Members Count'**
  String get family_members_count;

  /// No description provided for @filter.
  ///
  /// In en, this message translates to:
  /// **'Filter'**
  String get filter;

  /// No description provided for @filter_optional.
  ///
  /// In en, this message translates to:
  /// **'Filter (Optional)'**
  String get filter_optional;

  /// No description provided for @financial_information.
  ///
  /// In en, this message translates to:
  /// **'Financial Information'**
  String get financial_information;

  /// No description provided for @financial_obligations.
  ///
  /// In en, this message translates to:
  /// **'Financial Obligations'**
  String get financial_obligations;

  /// No description provided for @forgot_pin_logout.
  ///
  /// In en, this message translates to:
  /// **'Forgot PIN? Logout'**
  String get forgot_pin_logout;

  /// No description provided for @fourteen_days.
  ///
  /// In en, this message translates to:
  /// **'14 days'**
  String get fourteen_days;

  /// No description provided for @frequent_categories.
  ///
  /// In en, this message translates to:
  /// **'Frequent Categories'**
  String get frequent_categories;

  /// No description provided for @full_name.
  ///
  /// In en, this message translates to:
  /// **'Full Name'**
  String get full_name;

  /// No description provided for @full_name_required.
  ///
  /// In en, this message translates to:
  /// **'Full name is required'**
  String get full_name_required;

  /// No description provided for @get_smart_financial_advice.
  ///
  /// In en, this message translates to:
  /// **'Get smart financial advice'**
  String get get_smart_financial_advice;

  /// No description provided for @get_started.
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get get_started;

  /// No description provided for @goal.
  ///
  /// In en, this message translates to:
  /// **'Goal'**
  String get goal;

  /// No description provided for @goal_milestones.
  ///
  /// In en, this message translates to:
  /// **'Goal milestones'**
  String get goal_milestones;

  /// No description provided for @goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get goals;

  /// No description provided for @highest_amount.
  ///
  /// In en, this message translates to:
  /// **'Highest Amount'**
  String get highest_amount;

  /// No description provided for @history.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// No description provided for @home.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// No description provided for @house.
  ///
  /// In en, this message translates to:
  /// **'House'**
  String get house;

  /// No description provided for @housing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get housing;

  /// No description provided for @import_data.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get import_data;

  /// No description provided for @import_data_description.
  ///
  /// In en, this message translates to:
  /// **'Import feature will be available soon. You will be able to upload exported JSON files to restore data.'**
  String get import_data_description;

  /// No description provided for @import_data_title.
  ///
  /// In en, this message translates to:
  /// **'Import Data'**
  String get import_data_title;

  /// No description provided for @import_from_other_apps.
  ///
  /// In en, this message translates to:
  /// **'Import data from other apps'**
  String get import_from_other_apps;

  /// No description provided for @inactive.
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// No description provided for @income.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get income;

  /// No description provided for @income_range.
  ///
  /// In en, this message translates to:
  /// **'Income Range'**
  String get income_range;

  /// No description provided for @insurance.
  ///
  /// In en, this message translates to:
  /// **'Insurance'**
  String get insurance;

  /// No description provided for @interest.
  ///
  /// In en, this message translates to:
  /// **'Interest'**
  String get interest;

  /// No description provided for @interest_rate.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate'**
  String get interest_rate;

  /// No description provided for @interest_rate_percent_optional.
  ///
  /// In en, this message translates to:
  /// **'Interest Rate (%) (Optional)'**
  String get interest_rate_percent_optional;

  /// No description provided for @internet.
  ///
  /// In en, this message translates to:
  /// **'Internet'**
  String get internet;

  /// No description provided for @invalid_amount.
  ///
  /// In en, this message translates to:
  /// **'Invalid amount'**
  String get invalid_amount;

  /// No description provided for @invalid_obligation_id.
  ///
  /// In en, this message translates to:
  /// **'Invalid obligation ID'**
  String get invalid_obligation_id;

  /// No description provided for @investment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get investment;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @language_changed_to.
  ///
  /// In en, this message translates to:
  /// **'Language changed to'**
  String get language_changed_to;

  /// No description provided for @late.
  ///
  /// In en, this message translates to:
  /// **'Late'**
  String get late;

  /// No description provided for @late_payments.
  ///
  /// In en, this message translates to:
  /// **'Late Payments'**
  String get late_payments;

  /// No description provided for @light_mode.
  ///
  /// In en, this message translates to:
  /// **'Light Mode'**
  String get light_mode;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @location.
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// No description provided for @location_permission_desc.
  ///
  /// In en, this message translates to:
  /// **'• Location: Used to record transaction locations\\n• Notifications: To remind about bills and budgets\\n• Storage: To store app data'**
  String get location_permission_desc;

  /// No description provided for @location_removed.
  ///
  /// In en, this message translates to:
  /// **'Location removed'**
  String get location_removed;

  /// No description provided for @location_services.
  ///
  /// In en, this message translates to:
  /// **'Location Services'**
  String get location_services;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @lowest_amount.
  ///
  /// In en, this message translates to:
  /// **'Lowest Amount'**
  String get lowest_amount;

  /// No description provided for @manage_account_info.
  ///
  /// In en, this message translates to:
  /// **'Manage your account information'**
  String get manage_account_info;

  /// No description provided for @manage_budget.
  ///
  /// In en, this message translates to:
  /// **'Manage Budget'**
  String get manage_budget;

  /// No description provided for @manage_data_and_permissions.
  ///
  /// In en, this message translates to:
  /// **'Manage data and app permissions'**
  String get manage_data_and_permissions;

  /// No description provided for @mark_all.
  ///
  /// In en, this message translates to:
  /// **'Mark All'**
  String get mark_all;

  /// No description provided for @mark_as_paid.
  ///
  /// In en, this message translates to:
  /// **'Mark as Paid'**
  String get mark_as_paid;

  /// No description provided for @minimum_balance.
  ///
  /// In en, this message translates to:
  /// **'Minimum Balance'**
  String get minimum_balance;

  /// No description provided for @minimum_payment.
  ///
  /// In en, this message translates to:
  /// **'Minimum Payment'**
  String get minimum_payment;

  /// No description provided for @minimum_payment_optional.
  ///
  /// In en, this message translates to:
  /// **'Minimum Payment (Optional)'**
  String get minimum_payment_optional;

  /// No description provided for @monitor_expenses_income.
  ///
  /// In en, this message translates to:
  /// **'Monitor every expense and income'**
  String get monitor_expenses_income;

  /// No description provided for @monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get monthly;

  /// No description provided for @monthly_amount.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amount'**
  String get monthly_amount;

  /// No description provided for @monthly_amount_rp.
  ///
  /// In en, this message translates to:
  /// **'Monthly Amount (Rp)'**
  String get monthly_amount_rp;

  /// No description provided for @monthly_total.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get monthly_total;

  /// No description provided for @monthly_total_label.
  ///
  /// In en, this message translates to:
  /// **'Monthly Total'**
  String get monthly_total_label;

  /// No description provided for @monthly_trends.
  ///
  /// In en, this message translates to:
  /// **'Monthly Trends'**
  String get monthly_trends;

  /// No description provided for @mortgage.
  ///
  /// In en, this message translates to:
  /// **'Mortgage'**
  String get mortgage;

  /// No description provided for @name.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// No description provided for @new_password.
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get new_password;

  /// No description provided for @newest_date.
  ///
  /// In en, this message translates to:
  /// **'Newest Date'**
  String get newest_date;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @no_backup_yet.
  ///
  /// In en, this message translates to:
  /// **'No backup yet'**
  String get no_backup_yet;

  /// No description provided for @no_budgets_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set budgets to control your spending'**
  String get no_budgets_subtitle;

  /// No description provided for @no_budgets_title.
  ///
  /// In en, this message translates to:
  /// **'No Budgets'**
  String get no_budgets_title;

  /// No description provided for @no_categories_create_first.
  ///
  /// In en, this message translates to:
  /// **'No categories. Create categories first in the Budget menu.'**
  String get no_categories_create_first;

  /// No description provided for @no_connection_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get no_connection_subtitle;

  /// No description provided for @no_connection_title.
  ///
  /// In en, this message translates to:
  /// **'No Connection'**
  String get no_connection_title;

  /// No description provided for @no_debts.
  ///
  /// In en, this message translates to:
  /// **'No active debts'**
  String get no_debts;

  /// No description provided for @no_frequent_categories.
  ///
  /// In en, this message translates to:
  /// **'No frequently used categories yet'**
  String get no_frequent_categories;

  /// No description provided for @no_goals_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Set financial goals and achieve your dreams'**
  String get no_goals_subtitle;

  /// No description provided for @no_goals_title.
  ///
  /// In en, this message translates to:
  /// **'No Goals'**
  String get no_goals_title;

  /// No description provided for @no_notifications_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Your notifications will appear here'**
  String get no_notifications_subtitle;

  /// No description provided for @no_notifications_title.
  ///
  /// In en, this message translates to:
  /// **'No Notifications'**
  String get no_notifications_title;

  /// No description provided for @no_notifications_yet.
  ///
  /// In en, this message translates to:
  /// **'No notifications yet'**
  String get no_notifications_yet;

  /// No description provided for @no_obligations.
  ///
  /// In en, this message translates to:
  /// **'No obligations yet'**
  String get no_obligations;

  /// No description provided for @no_obligations_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Record your bills and subscriptions'**
  String get no_obligations_subtitle;

  /// No description provided for @no_obligations_title.
  ///
  /// In en, this message translates to:
  /// **'No Obligations'**
  String get no_obligations_title;

  /// No description provided for @no_payment_history.
  ///
  /// In en, this message translates to:
  /// **'No payment history yet'**
  String get no_payment_history;

  /// No description provided for @no_recurring_transactions_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Automatically record recurring transactions'**
  String get no_recurring_transactions_subtitle;

  /// No description provided for @no_recurring_transactions_title.
  ///
  /// In en, this message translates to:
  /// **'No Recurring Transactions'**
  String get no_recurring_transactions_title;

  /// No description provided for @no_recurring_transactions_yet.
  ///
  /// In en, this message translates to:
  /// **'No recurring transactions yet'**
  String get no_recurring_transactions_yet;

  /// No description provided for @no_scheduled_notifications.
  ///
  /// In en, this message translates to:
  /// **'No scheduled notifications'**
  String get no_scheduled_notifications;

  /// No description provided for @no_search_results.
  ///
  /// In en, this message translates to:
  /// **'No results match your search'**
  String get no_search_results;

  /// No description provided for @no_search_results_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Try different keywords or filters'**
  String get no_search_results_subtitle;

  /// No description provided for @no_search_results_title.
  ///
  /// In en, this message translates to:
  /// **'No Results'**
  String get no_search_results_title;

  /// No description provided for @no_subscriptions.
  ///
  /// In en, this message translates to:
  /// **'No active subscriptions'**
  String get no_subscriptions;

  /// No description provided for @no_transactions_for_period.
  ///
  /// In en, this message translates to:
  /// **'No transactions for selected period'**
  String get no_transactions_for_period;

  /// No description provided for @no_transactions_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Start recording your expenses and income'**
  String get no_transactions_subtitle;

  /// No description provided for @no_transactions_title.
  ///
  /// In en, this message translates to:
  /// **'No Transactions'**
  String get no_transactions_title;

  /// No description provided for @no_trend_data.
  ///
  /// In en, this message translates to:
  /// **'No trend data yet'**
  String get no_trend_data;

  /// No description provided for @no_upcoming.
  ///
  /// In en, this message translates to:
  /// **'No upcoming obligations'**
  String get no_upcoming;

  /// No description provided for @notification_cancelled.
  ///
  /// In en, this message translates to:
  /// **'Notification cancelled'**
  String get notification_cancelled;

  /// No description provided for @notification_deleted.
  ///
  /// In en, this message translates to:
  /// **'Notification deleted'**
  String get notification_deleted;

  /// No description provided for @notification_history_deleted.
  ///
  /// In en, this message translates to:
  /// **'Notification history deleted'**
  String get notification_history_deleted;

  /// No description provided for @notifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notifications;

  /// No description provided for @notifications_bills_due.
  ///
  /// In en, this message translates to:
  /// **'Notifications for bills due soon'**
  String get notifications_bills_due;

  /// No description provided for @notifications_budget_almost_empty.
  ///
  /// In en, this message translates to:
  /// **'Notifications when budget is almost/empty'**
  String get notifications_budget_almost_empty;

  /// No description provided for @notifications_help_stay_updated.
  ///
  /// In en, this message translates to:
  /// **'Notifications help you stay updated with finances'**
  String get notifications_help_stay_updated;

  /// No description provided for @notifications_progress_achievements.
  ///
  /// In en, this message translates to:
  /// **'Notifications for progress and goal achievements'**
  String get notifications_progress_achievements;

  /// No description provided for @notifications_will_appear_here.
  ///
  /// In en, this message translates to:
  /// **'Notifications will appear here'**
  String get notifications_will_appear_here;

  /// No description provided for @obligation_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Obligation deleted successfully'**
  String get obligation_deleted_successfully;

  /// No description provided for @obligation_name.
  ///
  /// In en, this message translates to:
  /// **'Obligation Name'**
  String get obligation_name;

  /// No description provided for @obligations.
  ///
  /// In en, this message translates to:
  /// **'Obligations'**
  String get obligations;

  /// No description provided for @obligations_count.
  ///
  /// In en, this message translates to:
  /// **'obligations'**
  String get obligations_count;

  /// No description provided for @old_password.
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get old_password;

  /// No description provided for @oldest_date.
  ///
  /// In en, this message translates to:
  /// **'Oldest Date'**
  String get oldest_date;

  /// No description provided for @on_time.
  ///
  /// In en, this message translates to:
  /// **'On Time'**
  String get on_time;

  /// No description provided for @on_time_payments.
  ///
  /// In en, this message translates to:
  /// **'On-Time Payments'**
  String get on_time_payments;

  /// No description provided for @one_day.
  ///
  /// In en, this message translates to:
  /// **'1 day'**
  String get one_day;

  /// No description provided for @original_amount.
  ///
  /// In en, this message translates to:
  /// **'Original Amount'**
  String get original_amount;

  /// No description provided for @original_debt_amount_optional.
  ///
  /// In en, this message translates to:
  /// **'Original Debt Amount (Optional)'**
  String get original_debt_amount_optional;

  /// No description provided for @other.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get other;

  /// No description provided for @over.
  ///
  /// In en, this message translates to:
  /// **'Over'**
  String get over;

  /// No description provided for @over_budget.
  ///
  /// In en, this message translates to:
  /// **'Over Budget'**
  String get over_budget;

  /// No description provided for @overdue.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue;

  /// No description provided for @overdue_count.
  ///
  /// In en, this message translates to:
  /// **'Overdue'**
  String get overdue_count;

  /// No description provided for @paid.
  ///
  /// In en, this message translates to:
  /// **'Paid'**
  String get paid;

  /// No description provided for @password_changed_successfully.
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get password_changed_successfully;

  /// No description provided for @password_min_6_chars.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 6 characters'**
  String get password_min_6_chars;

  /// No description provided for @passwords_do_not_match.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwords_do_not_match;

  /// No description provided for @pause.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// No description provided for @pay.
  ///
  /// In en, this message translates to:
  /// **'Pay'**
  String get pay;

  /// No description provided for @payment_amount.
  ///
  /// In en, this message translates to:
  /// **'Amount Paid (Rp)'**
  String get payment_amount;

  /// No description provided for @payment_date.
  ///
  /// In en, this message translates to:
  /// **'Payment Date'**
  String get payment_date;

  /// No description provided for @payment_delete_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to delete payment'**
  String get payment_delete_failed;

  /// No description provided for @payment_deleted.
  ///
  /// In en, this message translates to:
  /// **'Payment deleted successfully'**
  String get payment_deleted;

  /// No description provided for @payment_failed.
  ///
  /// In en, this message translates to:
  /// **'Failed to record payment'**
  String get payment_failed;

  /// No description provided for @payment_history.
  ///
  /// In en, this message translates to:
  /// **'Payment History'**
  String get payment_history;

  /// No description provided for @payment_history_hint.
  ///
  /// In en, this message translates to:
  /// **'Payment history for this obligation'**
  String get payment_history_hint;

  /// No description provided for @payment_recorded.
  ///
  /// In en, this message translates to:
  /// **'Payment recorded successfully'**
  String get payment_recorded;

  /// No description provided for @payment_statistics.
  ///
  /// In en, this message translates to:
  /// **'Payment Statistics'**
  String get payment_statistics;

  /// No description provided for @personal_loan.
  ///
  /// In en, this message translates to:
  /// **'Personal Loan'**
  String get personal_loan;

  /// No description provided for @phone.
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// No description provided for @phone_number.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phone_number;

  /// No description provided for @plan_financial_future.
  ///
  /// In en, this message translates to:
  /// **'Plan your financial future'**
  String get plan_financial_future;

  /// No description provided for @please_select_month.
  ///
  /// In en, this message translates to:
  /// **'Please select month'**
  String get please_select_month;

  /// No description provided for @please_select_period_first.
  ///
  /// In en, this message translates to:
  /// **'Please select period first'**
  String get please_select_period_first;

  /// No description provided for @please_select_year.
  ///
  /// In en, this message translates to:
  /// **'Please select year'**
  String get please_select_year;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @privacy_policy.
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacy_policy;

  /// No description provided for @progress.
  ///
  /// In en, this message translates to:
  /// **'Progress'**
  String get progress;

  /// No description provided for @quick_add.
  ///
  /// In en, this message translates to:
  /// **'Quick Add'**
  String get quick_add;

  /// No description provided for @quick_add_enhanced.
  ///
  /// In en, this message translates to:
  /// **'Quick Add (Enhanced)'**
  String get quick_add_enhanced;

  /// No description provided for @quick_amounts.
  ///
  /// In en, this message translates to:
  /// **'Quick Amounts'**
  String get quick_amounts;

  /// No description provided for @quick_expense.
  ///
  /// In en, this message translates to:
  /// **'Quick Expense'**
  String get quick_expense;

  /// No description provided for @quick_income.
  ///
  /// In en, this message translates to:
  /// **'Quick Income'**
  String get quick_income;

  /// No description provided for @receipt_scanned_successfully.
  ///
  /// In en, this message translates to:
  /// **'Receipt scanned successfully! Form has been filled automatically.'**
  String get receipt_scanned_successfully;

  /// No description provided for @record_payment.
  ///
  /// In en, this message translates to:
  /// **'Record Payment'**
  String get record_payment;

  /// No description provided for @record_transactions.
  ///
  /// In en, this message translates to:
  /// **'Record Transactions'**
  String get record_transactions;

  /// No description provided for @remaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining'**
  String get remaining;

  /// No description provided for @remaining_this_month.
  ///
  /// In en, this message translates to:
  /// **'Remaining This Month'**
  String get remaining_this_month;

  /// No description provided for @reminder_days.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for'**
  String get reminder_days;

  /// No description provided for @reminder_description.
  ///
  /// In en, this message translates to:
  /// **'Get notifications before bills are due'**
  String get reminder_description;

  /// No description provided for @reminder_disabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder disabled'**
  String get reminder_disabled;

  /// No description provided for @reminder_enabled.
  ///
  /// In en, this message translates to:
  /// **'Reminder enabled'**
  String get reminder_enabled;

  /// No description provided for @reminder_set.
  ///
  /// In en, this message translates to:
  /// **'Reminder set for'**
  String get reminder_set;

  /// No description provided for @reminder_settings.
  ///
  /// In en, this message translates to:
  /// **'Reminder Settings'**
  String get reminder_settings;

  /// No description provided for @reminder_snoozed.
  ///
  /// In en, this message translates to:
  /// **'Reminder snoozed for 24 hours'**
  String get reminder_snoozed;

  /// No description provided for @reminders_and_updates.
  ///
  /// In en, this message translates to:
  /// **'Reminders and important updates'**
  String get reminders_and_updates;

  /// No description provided for @reset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get reset;

  /// No description provided for @residence_location.
  ///
  /// In en, this message translates to:
  /// **'Residence Location'**
  String get residence_location;

  /// No description provided for @resume.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get resume;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @save_changes.
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get save_changes;

  /// No description provided for @savings_rate.
  ///
  /// In en, this message translates to:
  /// **'Savings Rate'**
  String get savings_rate;

  /// No description provided for @savings_recommendations.
  ///
  /// In en, this message translates to:
  /// **'Savings recommendations'**
  String get savings_recommendations;

  /// No description provided for @scan_receipt_automatically.
  ///
  /// In en, this message translates to:
  /// **'Scan receipt automatically'**
  String get scan_receipt_automatically;

  /// No description provided for @scheduled.
  ///
  /// In en, this message translates to:
  /// **'Scheduled'**
  String get scheduled;

  /// No description provided for @search.
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// No description provided for @search_obligations.
  ///
  /// In en, this message translates to:
  /// **'Search bills, debts, or subscriptions...'**
  String get search_obligations;

  /// No description provided for @security.
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get security;

  /// No description provided for @select_action.
  ///
  /// In en, this message translates to:
  /// **'Select action:'**
  String get select_action;

  /// No description provided for @select_category.
  ///
  /// In en, this message translates to:
  /// **'Select category'**
  String get select_category;

  /// No description provided for @select_default_tab.
  ///
  /// In en, this message translates to:
  /// **'Select Default Tab'**
  String get select_default_tab;

  /// No description provided for @select_image_source.
  ///
  /// In en, this message translates to:
  /// **'Select Image Source'**
  String get select_image_source;

  /// No description provided for @select_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get select_language;

  /// No description provided for @select_month.
  ///
  /// In en, this message translates to:
  /// **'Select Month'**
  String get select_month;

  /// No description provided for @select_period.
  ///
  /// In en, this message translates to:
  /// **'Select Period'**
  String get select_period;

  /// No description provided for @select_pin_length.
  ///
  /// In en, this message translates to:
  /// **'Select PIN Length'**
  String get select_pin_length;

  /// No description provided for @select_year.
  ///
  /// In en, this message translates to:
  /// **'Select Year'**
  String get select_year;

  /// No description provided for @server_error_subtitle.
  ///
  /// In en, this message translates to:
  /// **'Server is having issues. Try again in a few moments'**
  String get server_error_subtitle;

  /// No description provided for @server_error_title.
  ///
  /// In en, this message translates to:
  /// **'An Error Occurred'**
  String get server_error_title;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @seven_days.
  ///
  /// In en, this message translates to:
  /// **'7 days'**
  String get seven_days;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @shortage.
  ///
  /// In en, this message translates to:
  /// **'Shortage'**
  String get shortage;

  /// No description provided for @similar_transaction_added.
  ///
  /// In en, this message translates to:
  /// **'A similar transaction was just added. Are you sure you want to continue?'**
  String get similar_transaction_added;

  /// No description provided for @skip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// No description provided for @smart_category_suggestions.
  ///
  /// In en, this message translates to:
  /// **'Smart category suggestions'**
  String get smart_category_suggestions;

  /// No description provided for @snooze_reminder.
  ///
  /// In en, this message translates to:
  /// **'Snooze Reminder'**
  String get snooze_reminder;

  /// No description provided for @spending_forecast.
  ///
  /// In en, this message translates to:
  /// **'Spending Forecast'**
  String get spending_forecast;

  /// No description provided for @spending_insights.
  ///
  /// In en, this message translates to:
  /// **'Spending insights'**
  String get spending_insights;

  /// No description provided for @spent.
  ///
  /// In en, this message translates to:
  /// **'Spent'**
  String get spent;

  /// No description provided for @start_managing_finances.
  ///
  /// In en, this message translates to:
  /// **'Let\'s start managing your finances better'**
  String get start_managing_finances;

  /// No description provided for @status.
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// No description provided for @student_loan.
  ///
  /// In en, this message translates to:
  /// **'Student Loan'**
  String get student_loan;

  /// No description provided for @subscription.
  ///
  /// In en, this message translates to:
  /// **'Subscription'**
  String get subscription;

  /// No description provided for @subscription_cycle.
  ///
  /// In en, this message translates to:
  /// **'Cycle'**
  String get subscription_cycle;

  /// No description provided for @subscription_cycle_label.
  ///
  /// In en, this message translates to:
  /// **'Subscription Cycle'**
  String get subscription_cycle_label;

  /// No description provided for @subscription_cycle_monthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get subscription_cycle_monthly;

  /// No description provided for @subscription_cycle_weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get subscription_cycle_weekly;

  /// No description provided for @subscription_cycle_yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get subscription_cycle_yearly;

  /// No description provided for @system.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// No description provided for @take_photo.
  ///
  /// In en, this message translates to:
  /// **'Take Photo'**
  String get take_photo;

  /// No description provided for @tap_plus_to_create.
  ///
  /// In en, this message translates to:
  /// **'Tap + button to create'**
  String get tap_plus_to_create;

  /// No description provided for @target.
  ///
  /// In en, this message translates to:
  /// **'Target'**
  String get target;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @this_month.
  ///
  /// In en, this message translates to:
  /// **'This Month'**
  String get this_month;

  /// No description provided for @this_week.
  ///
  /// In en, this message translates to:
  /// **'This Week'**
  String get this_week;

  /// No description provided for @this_year.
  ///
  /// In en, this message translates to:
  /// **'This Year'**
  String get this_year;

  /// No description provided for @three_days.
  ///
  /// In en, this message translates to:
  /// **'3 days'**
  String get three_days;

  /// No description provided for @three_months.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get three_months;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @total_amount.
  ///
  /// In en, this message translates to:
  /// **'Total Amount'**
  String get total_amount;

  /// No description provided for @total_budget.
  ///
  /// In en, this message translates to:
  /// **'Total Budget'**
  String get total_budget;

  /// No description provided for @total_budgets.
  ///
  /// In en, this message translates to:
  /// **'Budgets'**
  String get total_budgets;

  /// No description provided for @total_categories.
  ///
  /// In en, this message translates to:
  /// **'Categories'**
  String get total_categories;

  /// No description provided for @total_debt.
  ///
  /// In en, this message translates to:
  /// **'Total Debt'**
  String get total_debt;

  /// No description provided for @total_expense.
  ///
  /// In en, this message translates to:
  /// **'Total Expense'**
  String get total_expense;

  /// No description provided for @total_goals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get total_goals;

  /// No description provided for @total_income.
  ///
  /// In en, this message translates to:
  /// **'Total Income'**
  String get total_income;

  /// No description provided for @total_payments.
  ///
  /// In en, this message translates to:
  /// **'Total Payments'**
  String get total_payments;

  /// No description provided for @total_transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get total_transactions;

  /// No description provided for @track_all_transactions.
  ///
  /// In en, this message translates to:
  /// **'Track all transactions'**
  String get track_all_transactions;

  /// No description provided for @transaction_deleted_successfully.
  ///
  /// In en, this message translates to:
  /// **'Transaction deleted successfully'**
  String get transaction_deleted_successfully;

  /// No description provided for @transaction_paused.
  ///
  /// In en, this message translates to:
  /// **'Transaction paused'**
  String get transaction_paused;

  /// No description provided for @transaction_rejected_insufficient_balance.
  ///
  /// In en, this message translates to:
  /// **'Transaction rejected! Your balance is insufficient for this expense.'**
  String get transaction_rejected_insufficient_balance;

  /// No description provided for @transaction_resumed.
  ///
  /// In en, this message translates to:
  /// **'Transaction resumed'**
  String get transaction_resumed;

  /// No description provided for @transaction_saved_successfully.
  ///
  /// In en, this message translates to:
  /// **'Transaction saved successfully!'**
  String get transaction_saved_successfully;

  /// No description provided for @transactions.
  ///
  /// In en, this message translates to:
  /// **'Transactions'**
  String get transactions;

  /// No description provided for @transfer.
  ///
  /// In en, this message translates to:
  /// **'Transfer'**
  String get transfer;

  /// No description provided for @transportation.
  ///
  /// In en, this message translates to:
  /// **'Transportation'**
  String get transportation;

  /// No description provided for @try_again.
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get try_again;

  /// No description provided for @type.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get type;

  /// No description provided for @understood.
  ///
  /// In en, this message translates to:
  /// **'Understood'**
  String get understood;

  /// No description provided for @unknown_date.
  ///
  /// In en, this message translates to:
  /// **'Unknown date'**
  String get unknown_date;

  /// No description provided for @upcoming.
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get upcoming;

  /// No description provided for @use_biometric.
  ///
  /// In en, this message translates to:
  /// **'Use Biometric'**
  String get use_biometric;

  /// No description provided for @use_face_id.
  ///
  /// In en, this message translates to:
  /// **'Use Face ID'**
  String get use_face_id;

  /// No description provided for @use_fingerprint.
  ///
  /// In en, this message translates to:
  /// **'Use Fingerprint'**
  String get use_fingerprint;

  /// No description provided for @use_iris.
  ///
  /// In en, this message translates to:
  /// **'Use Iris'**
  String get use_iris;

  /// No description provided for @use_pin_to_unlock.
  ///
  /// In en, this message translates to:
  /// **'Use this PIN to quickly unlock the app every time you log in'**
  String get use_pin_to_unlock;

  /// No description provided for @user_profile.
  ///
  /// In en, this message translates to:
  /// **'User Profile'**
  String get user_profile;

  /// No description provided for @utilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get utilities;

  /// No description provided for @vacation.
  ///
  /// In en, this message translates to:
  /// **'Vacation'**
  String get vacation;

  /// No description provided for @vehicle.
  ///
  /// In en, this message translates to:
  /// **'Vehicle'**
  String get vehicle;

  /// No description provided for @view_today_financial_activity.
  ///
  /// In en, this message translates to:
  /// **'View your financial activity today'**
  String get view_today_financial_activity;

  /// No description provided for @visit.
  ///
  /// In en, this message translates to:
  /// **'Visit'**
  String get visit;

  /// No description provided for @visual_progress_tracking.
  ///
  /// In en, this message translates to:
  /// **'Visual progress tracking'**
  String get visual_progress_tracking;

  /// No description provided for @voice_input_not_available.
  ///
  /// In en, this message translates to:
  /// **'Voice input not available'**
  String get voice_input_not_available;

  /// No description provided for @wait.
  ///
  /// In en, this message translates to:
  /// **'Wait'**
  String get wait;

  /// No description provided for @wedding.
  ///
  /// In en, this message translates to:
  /// **'Wedding'**
  String get wedding;

  /// No description provided for @weekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get weekly;

  /// No description provided for @welcome.
  ///
  /// In en, this message translates to:
  /// **'Welcome'**
  String get welcome;

  /// No description provided for @yearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get yearly;

  /// No description provided for @you_need_to_login_again.
  ///
  /// In en, this message translates to:
  /// **'You need to login again with email and password.'**
  String get you_need_to_login_again;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'id'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'id':
      return AppLocalizationsId();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
