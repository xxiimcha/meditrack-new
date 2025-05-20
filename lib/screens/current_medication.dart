import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class CurrentMedicationsScreen extends StatefulWidget {
  @override
  _CurrentMedicationsScreenState createState() => _CurrentMedicationsScreenState();
}

class _CurrentMedicationsScreenState extends State<CurrentMedicationsScreen> {
  bool isLoading = true;
  List<Map<String, dynamic>> activeMedications = [];

  @override
  void initState() {
    super.initState();
    fetchActiveMedications();
  }

  Future<void> fetchActiveMedications() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('medication_schedules')
        .where('user_id', isEqualTo: user.uid)
        .get();

    final filtered = snapshot.docs.where((doc) {
      final data = doc.data();
      final start = (data['start_date'] as Timestamp).toDate();
      final end = (data['until_date'] as Timestamp).toDate();
      return now.isAfter(start.subtract(const Duration(days: 1))) &&
             now.isBefore(end.add(const Duration(days: 1)));
    }).map((doc) => doc.data()).toList();

    setState(() {
      activeMedications = filtered;
      isLoading = false;
    });
  }

  Widget buildMedicationCard(Map<String, dynamic> data) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(data['medication_name'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          if (data['instruction'] != null)
            Text("Instruction: ${data['instruction']}"),
          if (data['frequency'] != null)
            Text("Frequency: ${data['frequency']}"),
          if (data['interval'] != null)
            Text("Interval: ${data['interval']}"),
          if (data['start_date'] != null && data['until_date'] != null)
            Text(
              "Schedule: ${DateFormat.yMMMd().format((data['start_date'] as Timestamp).toDate())} to ${DateFormat.yMMMd().format((data['until_date'] as Timestamp).toDate())}",
              style: const TextStyle(fontSize: 13, color: Colors.grey),
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
        title: const Text("Current Medications"),
        backgroundColor: Colors.green,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : activeMedications.isEmpty
              ? const Center(child: Text("No active medications found."))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: activeMedications.length,
                  itemBuilder: (context, index) =>
                      buildMedicationCard(activeMedications[index]),
                ),
    );
  }
}
