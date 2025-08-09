import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../transactions/transactions_page.dart';
import '../transactions/add_transaction_page.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/widgets/summary_card.dart';
import '../../core/widgets/pie_chart_widget.dart';
import '../../core/widgets/transaction_tile.dart';
import '../settings/settings_page.dart';
import '../../core/helpers/currency_utils.dart';
import '../budget/budget_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  String currencySymbol = getCurrencySymbol();
    DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SettingsPage()),
    );
    setState(() {
      currencySymbol = getCurrencySymbol();
    });
  }

  // Reserved for future use: quick-create with preselected type

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
        actions: [
          IconButton(
            tooltip: 'Budgets',
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BudgetPage()));
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            final transactions = provider.transactions
                .where((tx) => tx.date.year == _selectedMonth.year && tx.date.month == _selectedMonth.month)
                .toList();
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
                        child: Text(
                          'Overview',
                          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      _MonthPicker(
                        selectedMonth: _selectedMonth,
                        onChanged: (date) => setState(() => _selectedMonth = date),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: SummaryCard(
                          label: 'Total Income',
                          value: totalIncome,
                          icon: Icons.arrow_downward,
                          color: Colors.green,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SummaryCard(
                          label: 'Total Expense',
                          value: totalExpense,
                          icon: Icons.arrow_upward,
                          color: Colors.red,
                          currencySymbol: currencySymbol,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SummaryCard(
                    label: 'Net Balance',
                    value: totalIncome - totalExpense,
                    icon: Icons.account_balance_wallet,
                    color: (totalIncome - totalExpense) >= 0 ? Colors.blue : Colors.red,
                    currencySymbol: currencySymbol,
                  ),
                  const SizedBox(height: 24),
                  if (provider.isLoading)
                    _DashboardSkeleton()
                  else if (transactions.isNotEmpty)
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Expenses by Category', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8, right: 8),
                              child: LayoutBuilder(
                                builder: (context, c) {
                                  final h = c.maxWidth < 420 ? 360.0 : 320.0;
                                  return SizedBox(
                                    height: h,
                                    child: PieChartWidget(
                                      data: expenseByCategory,
                                      centerLabel: 'Total',
                                      maxSegments: 6,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (!provider.isLoading && transactions.isEmpty)
                    Card(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No transactions yet for ${DateFormat('MMMM').format(_selectedMonth)} ${_selectedMonth.year}. Tap "Add Transaction" to get started.',
                                style: theme.textTheme.bodyMedium,
                              ),
                            )
                          ],
                        ),
                      ),
                    ),
                  if (!provider.isLoading && transactions.isNotEmpty) ...[
                    const SizedBox(height: 24),
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text('Recent Transactions',
                                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (context) => const TransactionsPage()),
                                    );
                                  },
                                  child: const Text('See All'),
                                )
                              ],
                            ),
                            const SizedBox(height: 8),
                            Builder(
                              builder: (context) {
                                final sorted = transactions.toList()
                                  ..sort((a, b) => b.date.compareTo(a.date));
                                final count = sorted.length > 5 ? 5 : sorted.length;
                                return ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: count,
                                  separatorBuilder: (context, index) => const SizedBox(height: 8),
                                  itemBuilder: (context, index) {
                                    final tx = sorted[index];
                                    return TransactionTile(transaction: tx);
                                  },
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  _DashboardActions(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _MonthPicker extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;
  const _MonthPicker({required this.selectedMonth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final monthLabel = '${_monthName(selectedMonth.month)} ${selectedMonth.year}';
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      onPressed: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: selectedMonth,
          firstDate: DateTime(now.year - 3),
          lastDate: DateTime(now.year + 3),
          helpText: 'Select a date in the month',
        );
        if (picked != null) {
          onChanged(DateTime(picked.year, picked.month));
        }
      },
      icon: const Icon(Icons.calendar_month),
      label: Text(monthLabel),
    );
  }

  String _monthName(int m) {
    const names = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[m - 1];
  }
}

class _DashboardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).colorScheme.surfaceContainerHighest;
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _shimmerBox(base, height: 84)),
            const SizedBox(width: 16),
            Expanded(child: _shimmerBox(base, height: 84)),
          ],
        ),
        const SizedBox(height: 24),
        _shimmerBox(base, height: 280),
      ],
    );
  }

  Widget _shimmerBox(Color color, {double height = 60}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}

class _DashboardActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget buildActionCard({
      required IconData icon,
      required String title,
      required String subtitle,
      required Color color,
      required VoidCallback onTap,
    }) {
      return InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color.withValues(alpha: 0.12), color.withValues(alpha: 0.06)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.18)),
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.16),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(subtitle, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.7))),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 640;
        final spacing = 16.0;
        final children = [
          buildActionCard(
            icon: Icons.list_alt,
            title: 'View Transactions',
            subtitle: 'See all your incomes and expenses',
            color: theme.colorScheme.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TransactionsPage()),
              );
            },
          ),
          buildActionCard(
            icon: Icons.add_circle_outline,
            title: 'Add Transaction',
            subtitle: 'Quickly record income or expense',
            color: theme.colorScheme.secondary,
            onTap: () {
              showModalBottomSheet(
                context: context,
                showDragHandle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                ),
                builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Add', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
                        const SizedBox(height: 8),
                        ListTile(
                          leading: const Icon(Icons.arrow_upward, color: Colors.red),
                          title: const Text('Expense'),
                          subtitle: const Text('Record a new expense'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddTransactionPage(initialType: TransactionType.expense)),
                            );
                          },
                        ),
                        const SizedBox(height: 6),
                        ListTile(
                          leading: const Icon(Icons.arrow_downward, color: Colors.green),
                          title: const Text('Income'),
                          subtitle: const Text('Record a new income'),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddTransactionPage(initialType: TransactionType.income)),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ];

        if (isWide) {
          return Row(
            children: [
              Expanded(child: children[0]),
              SizedBox(width: spacing),
              Expanded(child: children[1]),
            ],
          );
        }
        return Column(
          children: [
            children[0],
            SizedBox(height: spacing),
            children[1],
          ],
        );
      },
    );
  }
}
