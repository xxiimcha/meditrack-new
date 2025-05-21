import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

Widget capsuleAdditionHistory(String docId) {
  if (docId.isEmpty) {
    return const Text("Unable to load history. Document ID missing.");
  }

  return StreamBuilder<QuerySnapshot>(
    stream: FirebaseFirestore.instance
        .collection('medication_schedules')
        .doc(docId)
        .collection('capsule_additions')
        .orderBy('added_at', descending: true)
        .snapshots(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return const Center(child: CircularProgressIndicator());
      }

      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
        return const Text("No addition history found.");
      }

      return Column(
        children: snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final count = data['added_count'] ?? 0;
          final date = (data['added_at'] as Timestamp).toDate().add(const Duration(hours: 8));

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_circle_outline, color: Colors.green),
            title: Text("+$count capsule(s)"),
            subtitle: Text("$date"),
          );
        }).toList(),
      );
    },
  );
}
