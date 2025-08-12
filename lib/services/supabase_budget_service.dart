import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBudgetService {
  final SupabaseClient client = Supabase.instance.client;
  final String table = 'budgets';

  Future<List<Map<String, dynamic>>> fetchBudgets() async {
    final response = await client.from(table).select().then((value) => value);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addBudget(Map<String, dynamic> data) async {
    await client.from(table).insert(data);
  }

  Future<void> updateBudget(int id, Map<String, dynamic> data) async {
    await client.from(table).update(data).eq('id', id);
  }

  Future<void> deleteBudget(int id) async {
    await client.from(table).delete().eq('id', id);
  }
}
