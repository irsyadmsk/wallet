import 'package:flutter/material.dart';

class ExpenseIcon extends StatelessWidget {
  const ExpenseIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.red.withOpacity(0.12),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Icon(Icons.arrow_upward, size: 22, color: Colors.red.shade700),
    );
  }
}
