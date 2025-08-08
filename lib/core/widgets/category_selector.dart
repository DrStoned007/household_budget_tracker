import 'package:flutter/material.dart';

class CategorySelector extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onChanged;
  const CategorySelector({super.key, required this.categories, required this.selectedCategory, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: selectedCategory == null ? Colors.blueGrey[100] : Colors.blueGrey[50],
            foregroundColor: Colors.black87,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          ),
          onPressed: () => onChanged(null),
          child: const Text('All'),
        ),
        ...categories.map((cat) => ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: selectedCategory == cat ? Colors.blue : Colors.blueGrey[100],
                foregroundColor: selectedCategory == cat ? Colors.white : Colors.black87,
                elevation: selectedCategory == cat ? 2 : 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
              onPressed: () => onChanged(cat),
              child: Text(cat),
            ))
      ],
    );
  }
}
