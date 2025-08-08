import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../transactions/transactions_page.dart';
import '../transactions/add_transaction_page.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/widgets/summary_card.dart';
import '../../core/widgets/pie_chart_widget.dart';
import '../settings/settings_page.dart';
import '../../core/helpers/currency_utils.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String currencySymbol = getCurrencySymbol();

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    setState(() {
      currencySymbol = getCurrencySymbol();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        backgroundColor: theme.colorScheme.primary,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: _openSettings,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            final transactions = provider.transactions;
            final totalIncome = transactions
                .where((tx) => tx.type == TransactionType.income)
                .fold<double>(0, (sum, tx) => sum + tx.amount);
            final totalExpense = transactions
                .where((tx) => tx.type == TransactionType.expense)
                .fold<double>(0, (sum, tx) => sum + tx.amount);
            final expenseByCategory = <String, double>{};
            for (var tx in transactions.where((tx) => tx.type == TransactionType.expense)) {
              expenseByCategory[tx.category] =
                  (expenseByCategory[tx.category] ?? 0) + tx.amount;
            }
            return SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          label: 'Total Income',
                          value: totalIncome,
                          icon: Icons.arrow_downward,
                          color: Colors.green,
                          currencySymbol: getCurrencySymbol(),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SummaryCard(
                          label: 'Total Expense',
                          value: totalExpense,
                          icon: Icons.arrow_upward,
                          color: Colors.red,
                          currencySymbol: getCurrencySymbol(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (transactions.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Expenses by Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            SizedBox(
                              height: 220,
                              child: Center(
                                child: PieChartWidget(data: expenseByCategory),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 32),
                  Wrap(
                    spacing: 16,
                    runSpacing: 12,
                    alignment: WrapAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.list),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const TransactionsPage()),
                          );
                        },
                        label: const Text('View Transactions'),
                      ),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.secondary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
                          );
                        },
                        label: const Text('Add Transaction'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
