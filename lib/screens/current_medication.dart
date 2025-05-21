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
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade100,
            child: Icon(Icons.medication, color: Colors.green.shade800),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data['medication_name'] ?? '',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                if (data['instruction'] != null)
                  Text.rich(TextSpan(
                    text: "Instruction: ",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    children: [TextSpan(text: data['instruction'], style: const TextStyle(fontWeight: FontWeight.normal))],
                  )),
                if (data['frequency'] != null)
                  Text.rich(TextSpan(
                    text: "Frequency: ",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    children: [TextSpan(text: data['frequency'], style: const TextStyle(fontWeight: FontWeight.normal))],
                  )),
                if (data['interval'] != null)
                  Text.rich(TextSpan(
                    text: "Interval: ",
                    style: const TextStyle(fontWeight: FontWeight.w500),
                    children: [TextSpan(text: data['interval'], style: const TextStyle(fontWeight: FontWeight.normal))],
                  )),
                if (data['start_date'] != null && data['until_date'] != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      "Schedule: ${DateFormat.yMMMd().format((data['start_date'] as Timestamp).toDate())} → ${DateFormat.yMMMd().format((data['until_date'] as Timestamp).toDate())}",
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA),
      appBar: AppBar(
        title: const Text("Current Medications"),
        backgroundColor: Colors.green,
        elevation: 0,
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
