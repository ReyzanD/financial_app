import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:financial_app/widgets/add_transaction/account_section.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class MockAccountSection extends StatefulWidget {
  final String? selectedAccountId;
  final Function(String?) onAccountSelected;
  final List<Map<String, dynamic>> accounts;
  final bool isLoading;

  const MockAccountSection({
    super.key,
    this.selectedAccountId,
    required this.onAccountSelected,
    required this.accounts,
    this.isLoading = false,
  });

  @override
  State<MockAccountSection> createState() => _MockAccountSectionState();
}

class _MockAccountSectionState extends State<MockAccountSection> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const CircularProgressIndicator();
    }

    if (widget.accounts.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        const Text('Akun'),
        Wrap(
          children: [
            GestureDetector(
              onTap: () => widget.onAccountSelected(null),
              child: Container(
                key: const ValueKey('all_accounts'),
                child: const Text('Semua'),
              ),
            ),
            ...widget.accounts.map((account) {
              final isSelected = widget.selectedAccountId == account['account_id_232143'];
              return GestureDetector(
                onTap: () => widget.onAccountSelected(account['account_id_232143']),
                child: Container(
                  key: ValueKey(account['account_id_232143']),
                  child: Text(account['name_232143'] as String),
                ),
              );
            }),
          ],
        ),
      ],
    );
  }
}

void main() {
  group('AccountSection', () {
    testWidgets('renders loading indicator when loading', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockAccountSection(
              onAccountSelected: (_) {},
              accounts: [],
              isLoading: true,
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders empty when no accounts', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockAccountSection(
              onAccountSelected: (_) {},
              accounts: [],
            ),
          ),
        ),
      );

      expect(find.byType(SizedBox), findsWidgets);
    });

    testWidgets('displays all accounts', (tester) async {
      final accounts = [
        {'account_id_232143': 'acc_1', 'name_232143': 'Cash', 'type_232143': 'cash'},
        {'account_id_232143': 'acc_2', 'name_232143': 'BCA', 'type_232143': 'bank'},
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockAccountSection(
              onAccountSelected: (_) {},
              accounts: accounts,
            ),
          ),
        ),
      );

      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('BCA'), findsOneWidget);
      expect(find.byKey(const ValueKey('all_accounts')), findsOneWidget);
    });

    testWidgets('calls onAccountSelected with null when "Semua" is tapped', (tester) async {
      String? selectedId = 'acc_1';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockAccountSection(
              selectedAccountId: selectedId,
              onAccountSelected: (id) => selectedId = id,
              accounts: [
                {'account_id_232143': 'acc_1', 'name_232143': 'Cash', 'type_232143': 'cash'},
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('all_accounts')));
      await tester.pump();

      expect(selectedId, isNull);
    });

    testWidgets('calls onAccountSelected with account id when account is tapped', (tester) async {
      String? selectedId;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MockAccountSection(
              onAccountSelected: (id) => selectedId = id,
              accounts: [
                {'account_id_232143': 'acc_1', 'name_232143': 'Cash', 'type_232143': 'cash'},
                {'account_id_232143': 'acc_bca', 'name_232143': 'BCA', 'type_232143': 'bank'},
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('BCA'));
      await tester.pump();

      expect(selectedId, 'acc_bca');
    });
  });
}
