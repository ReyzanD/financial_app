/// Utility to normalize database map keys by stripping the `_232143` suffix.
///
/// The SQLite database uses suffixed column names (e.g. `name_232143`,
/// `amount_232143`, `category_id_232143`). This normalizer converts them to
/// clean keys (`name`, `amount`, `category_id`) so that downstream code never
/// needs to know about the DB naming scheme.
///
/// Usage:
/// ```dart
/// final clean = KeyNormalizer.normalize(rawDbMap);
/// print(clean['name']);        // works
/// print(clean['amount']);      // works
/// print(clean['category_id']); // works
/// ```
class KeyNormalizer {
  /// The suffix used by the SQLite database.
  static const String suffix = '_232143';

  /// Normalize a single map by stripping the `_232143` suffix from all keys.
  ///
  /// If a clean key already exists (e.g. `'name'`), it is NOT overwritten by
  /// the suffixed version (`'name_232143'`). This preserves any explicitly
  /// set clean keys.
  static Map<String, dynamic> normalize(Map<String, dynamic> map) {
    final result = Map<String, dynamic>.from(map);
    final keysToAdd = <String, dynamic>{};

    for (final key in map.keys) {
      if (key.endsWith(suffix)) {
        final cleanKey = key.substring(0, key.length - suffix.length);
        // Only add the clean key if it doesn't already exist
        if (!result.containsKey(cleanKey)) {
          keysToAdd[cleanKey] = map[key];
        }
      }
    }

    result.addAll(keysToAdd);
    return result;
  }

  /// Normalize a list of maps.
  static List<Map<String, dynamic>> normalizeList(List<dynamic> items) {
    return items.map((item) {
      if (item is Map<String, dynamic>) {
        return normalize(item);
      }
      // Handle raw Map type (not typed as Map<String, dynamic>)
      final map = Map<String, dynamic>.from(item as Map);
      return normalize(map);
    }).toList();
  }

  /// Normalize transaction-specific maps.
  /// Applies the general normalization and adds transaction-specific fallbacks.
  ///
  /// Returns a map with these guaranteed keys:
  /// `transaction_date`, `date`, `type`, `amount`, `category_name`, `category`,
  /// `category_id`, `category_color`, `description`, `transaction_id`, `id`,
  /// `account_id`, `payment_method`.
  static List<Map<String, dynamic>> normalizeTransactions(List<dynamic> txns) {
    return txns.map((t) {
      final map = t is Map<String, dynamic> ? normalize(t) : normalize(Map<String, dynamic>.from(t as Map));

      final rawAmount = map['amount'];
      final amount = (rawAmount is num) ? rawAmount.toDouble() : 0.0;

      // Transaction-specific fallbacks after general normalization
      return {
        'transaction_date': map['transaction_date'] ?? map['date'],
        'date': map['transaction_date'] ?? map['date'],
        'type': map['type'] ?? 'expense',
        'amount': amount,
        'category_name': map['category_name'] ?? map['category'] ?? 'Lainnya',
        'category': map['category_name'] ?? map['category'] ?? 'Uncategorized',
        'category_color': map['category_color'] ?? '#8B5FBF',
        'category_id': map['category_id'] ?? map['category'],
        'description': map['description'] ?? '',
        'transaction_id': map['transaction_id'] ?? map['id'],
        'id': map['transaction_id'] ?? map['id'],
        'account_id': map['account_id'],
        'payment_method': map['payment_method'],
        ...map, // Keep all original normalized keys too
      };
    }).toList();
  }
}
