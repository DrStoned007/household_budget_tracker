import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/transaction_provider.dart';
import '../../models/transaction_model.dart';
import '../../core/widgets/transaction_tile.dart';
import '../../core/widgets/category_selector.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  String? _selectedCategory;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ChangeNotifierProvider(
      create: (_) {
        final provider = TransactionProvider();
        provider.loadTransactions();
        return provider;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Transactions'),
          backgroundColor: theme.colorScheme.primary,
          elevation: 2,
        ),
        body: Consumer<TransactionProvider>(
          builder: (context, provider, _) {
            final transactions = provider.transactions;
            final categories = transactions
                .map((tx) => tx.category)
                .toSet()
                .toList();
            final filtered = _selectedCategory == null
                ? transactions
                : transactions
                    .where((tx) => tx.category == _selectedCategory)
                    .toList();
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      child: CategorySelector(
                        categories: categories,
                        selectedCategory: _selectedCategory,
                        onChanged: (cat) {
                          setState(() => _selectedCategory = cat);
                        },
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: filtered.isEmpty
                      ? const Center(child: Text('No transactions found.'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 2,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 4),
                                child:
                                    TransactionTile(transaction: filtered[index]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
