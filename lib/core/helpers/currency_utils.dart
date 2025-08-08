import '../../services/currency_service.dart';

String getCurrencySymbol() {
  return CurrencyService.getCurrent().symbol;
}
