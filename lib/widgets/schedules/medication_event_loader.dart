import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<Map<DateTime, List<String>>> loadMedicationEvents() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return {};

  final snapshot = await FirebaseFirestore.instance
      .collection('medication_schedules')
      .where('user_id', isEqualTo: user.uid)
      .get();

  Map<DateTime, List<String>> events = {};

  for (var doc in snapshot.docs) {
    final data = doc.data();
    final start = (data['start_date'] as Timestamp).toDate();
    final end = (data['until_date'] as Timestamp).toDate();
    final name = data['medication_name'] ?? 'Medication';
    final interval = (data['interval'] ?? '').toString().toLowerCase();

    int step = 1;
    if (interval.contains('every other')) {
      step = 2;
    }

    for (DateTime date = start;
        !date.isAfter(end);
        date = date.add(Duration(days: step))) {
      final key = DateTime(date.year, date.month, date.day);
      if (!events.containsKey(key)) {
        events[key] = [];
      }
      events[key]!.add(name);
    }
  }

  return events;
}

