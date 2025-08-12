import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseCategoryService {
  final SupabaseClient client = Supabase.instance.client;
  final String table = 'categories';

  Future<List<Map<String, dynamic>>> fetchCategories() async {
    final response = await client.from(table).select().then((value) => value);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> addCategory(Map<String, dynamic> data) async {
    await client.from(table).insert(data);
  }

  Future<void> updateCategory(int id, Map<String, dynamic> data) async {
    await client.from(table).update(data).eq('id', id);
  }

  Future<void> deleteCategory(int id) async {
    await client.from(table).delete().eq('id', id);
  }
}
