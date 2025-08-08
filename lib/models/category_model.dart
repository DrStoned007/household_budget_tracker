import 'package:hive/hive.dart';

part 'category_model.g.dart';

@HiveType(typeId: 2)
class CategoryModel extends HiveObject {
  @HiveField(0)
  String name;
  @HiveField(1)
  bool isIncome;

  CategoryModel({required this.name, required this.isIncome});
}
