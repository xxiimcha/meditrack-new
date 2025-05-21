import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<DateTime, List<String>>> loadMedicationEvents() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  final snapshot = await FirebaseFirestore.instance
      .collection('medication_schedules')
      .where('user_id', isEqualTo: user.uid)
      .get();

  final events = <DateTime, List<String>>{};

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final start = (data['start_date'] as Timestamp).toDate();
    final end = (data['until_date'] as Timestamp).toDate();

    for (DateTime date = start;
        !date.isAfter(end);
        date = date.add(const Duration(days: 1))) {
      final normalized = DateTime(date.year, date.month, date.day);
      events[normalized] = events[normalized] ?? [];
      events[normalized]!.add(data['medication_name'] ?? 'Medication');
    }
  }

  return events;
}
