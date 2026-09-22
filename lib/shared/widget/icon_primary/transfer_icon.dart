import 'package:flutter/material.dart';

class TransferIcon extends StatelessWidget {
  const TransferIcon({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.blue.withOpacity(0.12),
      ),
      padding: const EdgeInsets.all(10.0),
      child: Icon(Icons.sync_alt, size: 22, color: Colors.blue.shade700),
    );
  }
}
