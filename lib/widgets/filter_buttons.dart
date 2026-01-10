import 'package:flutter/material.dart';

class FilterButton extends StatelessWidget {
  final String label;
  final String type;
  final bool isSelected;
  final VoidCallback onTap;

  const FilterButton({
    super.key,
    required this.label,
    required this.type,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
        color: isSelected 
            ? Colors.deepPurpleAccent 
            : (Theme.of(context).brightness == Brightness.dark 
                ? const Color(0xFF1F1F1F) 
                : Colors.grey[300]),
        borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected 
              ? Colors.black 
              : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}