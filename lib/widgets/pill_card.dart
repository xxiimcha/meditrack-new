import 'package:flutter/material.dart';

class PillCard extends StatelessWidget {
  final String title;
  final String dosage;
  final String time;
  final String takes;

  const PillCard({
    required this.title,
    required this.dosage,
    required this.time,
    required this.takes,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.green.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Dosage: $dosage"),
              Text("Time: $time"),
              Text("Takes: $takes"),
            ],
          ),
        ],
      ),
    );
  }
}
