import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../widgets/custom_bottom_navbar.dart';
import 'medication_detail_screen.dart'; // ✅ Create this file separately

class MedicationScheduleListScreen extends StatelessWidget {
  const MedicationScheduleListScreen({Key? key}) : super(key: key);

  Stream<QuerySnapshot> getUserSchedulesStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return const Stream.empty();

    return FirebaseFirestore.instance
        .collection('medication_schedules')
        .where('user_id', isEqualTo: user.uid)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      bottomNavigationBar: const CustomBottomNavBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Medication Schedules',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: getUserSchedulesStream(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No schedules found.\nTap + to add your first schedule!",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      );
                    }

                    final schedules = snapshot.data!.docs;

                    return ListView.builder(
                      itemCount: schedules.length,
                      itemBuilder: (context, index) {
                        final doc = schedules[index];
                        final data = doc.data() as Map<String, dynamic>;

                        final name = data['medication_name'] ?? 'No name';
                        final frequency = data['frequency'] ?? '';
                        final instruction = data['instruction'] ?? '';
                        final interval = data['interval'] ?? '';
                        final startDate = (data['start_date'] as Timestamp?)?.toDate();
                        final untilDate = (data['until_date'] as Timestamp?)?.toDate();

                        return InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MedicationDetailScreen(data: data),
                              ),
                            );
                          },
                          child: Card(
                            elevation: 4,
                            margin: const EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.medication, color: Color(0xFF2F5D50)),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2F5D50),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.black54),
                                        onPressed: () {
                                          _showEditDialog(context, doc.id, data);
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  _buildInfoRow("Frequency", frequency),
                                  _buildInfoRow("Interval", interval),
                                  _buildInfoRow("Instruction", instruction),
                                  if (startDate != null)
                                    _buildInfoRow("Start Date", DateFormat.yMMMd().format(startDate)),
                                  if (untilDate != null)
                                    _buildInfoRow("Until Date", DateFormat.yMMMd().format(untilDate)),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              "$label:",
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(BuildContext context, String docId, Map<String, dynamic> data) {
    final TextEditingController nameController =
        TextEditingController(text: data['medication_name']);
    final TextEditingController frequencyController =
        TextEditingController(text: data['frequency']);
    final TextEditingController instructionController =
        TextEditingController(text: data['instruction']);
    String interval = data['interval'] ?? 'Everyday';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Schedule"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: "Medication Name"),
                ),
                TextField(
                  controller: frequencyController,
                  decoration: const InputDecoration(labelText: "Frequency"),
                ),
                TextField(
                  controller: instructionController,
                  decoration: const InputDecoration(labelText: "Instruction"),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: interval,
                  decoration: const InputDecoration(labelText: "Interval"),
                  items: const [
                    DropdownMenuItem(value: 'Everyday', child: Text('Everyday')),
                    DropdownMenuItem(value: 'Every Other Day', child: Text('Every Other Day')),
                    DropdownMenuItem(value: 'Every 3 Days', child: Text('Every 3 Days')),
                    DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      interval = value;
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                await FirebaseFirestore.instance
                    .collection('medication_schedules')
                    .doc(docId)
                    .update({
                  'medication_name': nameController.text.trim(),
                  'frequency': frequencyController.text.trim(),
                  'instruction': instructionController.text.trim(),
                  'interval': interval,
                });

                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Schedule updated successfully')),
                );
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
