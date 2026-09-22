import 'package:flutter/material.dart';

class IncomeIcon extends StatelessWidget {
  const IncomeIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.green.withOpacity(0.12),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Icon(Icons.arrow_downward, size: 22, color: Colors.green.shade700),
    );
  }
}
