import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_bottom_navbar.dart';

class RecordIntakeScreen extends StatefulWidget {
  @override
  _RecordIntakeScreenState createState() => _RecordIntakeScreenState();
}

class _RecordIntakeScreenState extends State<RecordIntakeScreen> {
  bool isLoading = true;
  Map<String, List<Map<String, dynamic>>> groupedSchedules = {};
  Set<String> recorded = {}; // Format: "{docId}_{yyyy-MM-dd}"

  @override
  void initState() {
    super.initState();
    loadSchedules();
  }

  Future<void> loadSchedules() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('medication_schedules')
        .where('user_id', isEqualTo: user.uid)
        .get();

    final now = DateTime.now();
    final dateRange = List.generate(7, (i) => now.add(Duration(days: i)));
    Map<String, List<Map<String, dynamic>>> grouped = {};
    Set<String> recordedIntakes = {};

    for (final date in dateRange) {
      final key = DateFormat('yyyy-MM-dd').format(date);
      grouped[key] = [];
    }

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final docId = doc.id;
      final start = (data['start_date'] as Timestamp).toDate();
      final until = (data['until_date'] as Timestamp).toDate();

      for (final date in dateRange) {
        if (date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(until.add(const Duration(days: 1)))) {
          final key = DateFormat('yyyy-MM-dd').format(date);
          grouped[key]?.add({...data, 'id': docId});
        }
      }

      // Load intakes for today and past
      for (final date in dateRange) {
        final dateKey = DateFormat('yyyy-MM-dd').format(date);
        if (date.isAfter(now)) continue;

        final intakeDoc = await FirebaseFirestore.instance
            .collection('medication_schedules')
            .doc(docId)
            .collection('medication_intakes')
            .doc(dateKey)
            .get();

        if (intakeDoc.exists) {
          recordedIntakes.add("${docId}_$dateKey");
        }
      }
    }

    // Auto-log missed intakes
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    for (final entry in grouped.entries) {
      final dateKey = entry.key;
      if (dateKey.compareTo(today) >= 0) continue;

      for (final med in entry.value) {
        final docId = med['id'];
        final logKey = "${docId}_$dateKey";

        if (!recordedIntakes.contains(logKey)) {
          await FirebaseFirestore.instance
              .collection('medication_schedules')
              .doc(docId)
              .collection('medication_intakes')
              .doc(dateKey)
              .set({
            'taken': false,
            'taken_at': null,
            'status': 'missed',
            'created_at': Timestamp.now(),
          });
          recordedIntakes.add(logKey);
        }
      }
    }

    setState(() {
      groupedSchedules = grouped;
      recorded = recordedIntakes;
      isLoading = false;
    });
  }

  Future<void> recordIntake(Map<String, dynamic> data, String dateKey) async {
    final docId = data['id'];
    await FirebaseFirestore.instance
        .collection('medication_schedules')
        .doc(docId)
        .collection('medication_intakes')
        .doc(dateKey)
        .set({
      'taken': true,
      'taken_at': Timestamp.now(),
      'status': 'taken',
      'created_at': Timestamp.now(),
    });

    setState(() {
      recorded.add("${docId}_$dateKey");
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content:
            Text("Recorded intake for ${data['medication_name']} on $dateKey"),
      ),
    );
  }

  Widget buildScheduleCard(Map<String, dynamic> data, String dateKey) {
    final docId = data['id'];
    final logKey = "${docId}_$dateKey";
    final isRecorded = recorded.contains(logKey);
    final isTodayOrPast = DateTime.parse(dateKey)
        .isBefore(DateTime.now().add(const Duration(days: 1)));

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['medication_name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          if (data['instruction'] != null)
            Text("Instruction: ${data['instruction']}",
                style: const TextStyle(fontSize: 13)),
          if (data['frequency'] != null)
            Text("Frequency: ${data['frequency']}",
                style: const TextStyle(fontSize: 13)),
          if (data['interval'] != null)
            Text("Interval: ${data['interval']}",
                style: const TextStyle(fontSize: 13)),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: isTodayOrPast
                ? ElevatedButton.icon(
                    onPressed: isRecorded
                        ? null
                        : () => recordIntake(data, dateKey),
                    icon:
                        Icon(isRecorded ? Icons.check : Icons.add_task_outlined),
                    label: Text(isRecorded ? "Recorded" : "Mark as Taken"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          isRecorded ? Colors.grey : Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  )
                : OutlinedButton.icon(
                    onPressed: null,
                    icon: const Icon(Icons.schedule),
                    label: const Text("Upcoming"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.grey,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title:
            const Text("Record Intake", style: TextStyle(color: Colors.black)),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: groupedSchedules.entries.map((entry) {
                final date = entry.key;
                final meds = entry.value;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d')
                          .format(DateTime.parse(date)),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (meds.isEmpty)
                      const Text("No medications scheduled.",
                          style: TextStyle(color: Colors.grey))
                    else
                      ...meds.map((m) => buildScheduleCard(m, date)).toList(),
                    const SizedBox(height: 20),
                  ],
                );
              }).toList(),
            ),
    );
  }
}
