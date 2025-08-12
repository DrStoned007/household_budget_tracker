import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseTransactionService {
  final SupabaseClient client = Supabase.instance.client;
  final String table = 'transactions';

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final response = await client.from(table).select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<int> addTransaction(Map<String, dynamic> data) async {
    // Insert and return the inserted row id
    final response = await client.from(table).insert(data).select('id').limit(1);
    final rows = List<Map<String, dynamic>>.from(response as List);
    if (rows.isNotEmpty && rows.first['id'] != null) {
      return (rows.first['id'] as num).toInt();
    }
    // Fallback: re-query last inserted by timestamp if id not returned
    final fetched = await client
        .from(table)
        .select('id')
        .order('id', ascending: false)
        .limit(1);
    final list = List<Map<String, dynamic>>.from(fetched as List);
    return list.isNotEmpty ? (list.first['id'] as num).toInt() : -1;
  }

  Future<void> updateTransaction(int id, Map<String, dynamic> data) async {
    await client.from(table).update(data).eq('id', id);
  }

  Future<void> deleteTransaction(int id) async {
    await client.from(table).delete().eq('id', id);
  }
}
