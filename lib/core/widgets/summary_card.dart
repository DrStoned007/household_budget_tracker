import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  final String currencySymbol;

  const SummaryCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
        trailing: SizedBox(
          width: 100,
          child: Text(
            '$currencySymbol${value.toStringAsFixed(2)}',
            style: TextStyle(fontSize: 18, color: color),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}
