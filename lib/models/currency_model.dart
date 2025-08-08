import 'package:hive/hive.dart';

part 'currency_model.g.dart';

@HiveType(typeId: 3)
class CurrencyModel extends HiveObject {
  @HiveField(0)
  String code;
  @HiveField(1)
  String symbol;

  CurrencyModel({required this.code, required this.symbol});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CurrencyModel &&
          runtimeType == other.runtimeType &&
          code == other.code &&
          symbol == other.symbol;

  @override
  int get hashCode => code.hashCode ^ symbol.hashCode;
}
