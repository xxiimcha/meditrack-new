import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/medications/pill_detail_row.dart';
import '../widgets/medications/add_capsule_dialog.dart';
import '../widgets/medications/capsule_addition_history.dart';

class MedicationDetailScreen extends StatefulWidget {
  final Map<String, dynamic> data;

  const MedicationDetailScreen({super.key, required this.data});

  @override
  State<MedicationDetailScreen> createState() => _MedicationDetailScreenState();
}

class _MedicationDetailScreenState extends State<MedicationDetailScreen> {
  late int quantityLeft;
  late int totalQuantity;
  late String docId;

  @override
  void initState() {
    super.initState();
    quantityLeft = widget.data['quantity_left'] ?? 0;
    totalQuantity = widget.data['total_quantity'] ?? 0;
    docId = widget.data['id'] ?? '';

    if (docId.isEmpty) {
      debugPrint("⚠️ ERROR: Document ID is missing.");
    } else {
      debugPrint("📄 Loaded document ID: $docId");
    }
  }

  Future<void> _consumeCapsule() async {
    if (quantityLeft <= 0 || docId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No capsules left or invalid record.')),
      );
      return;
    }

    try {
      setState(() => quantityLeft--);

      await FirebaseFirestore.instance
          .collection('medication_schedules')
          .doc(docId)
          .update({'quantity_left': quantityLeft});

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Capsule marked as taken.')),
      );
    } catch (e) {
      setState(() => quantityLeft++);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _addCapsules(int count) async {
    if (count <= 0 || docId.isEmpty) return;

    final now = Timestamp.now();

    try {
      setState(() {
        quantityLeft += count;
        totalQuantity += count;
      });

      final docRef = FirebaseFirestore.instance.collection('medication_schedules').doc(docId);

      await docRef.update({
        'quantity_left': quantityLeft,
        'total_quantity': totalQuantity,
      });

      await docRef.collection('capsule_additions').add({
        'added_count': count,
        'added_at': now,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$count capsules added and logged.')),
      );
    } catch (e) {
      setState(() {
        quantityLeft -= count;
        totalQuantity -= count;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding capsules: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final name = data['medication_name'] ?? 'Unknown';
    final dosage = data['dosage'] ?? '200 mg';
    final nextDose = data['next_dose'] ?? '3:00 pm';
    final frequency = data['frequency'] ?? '';
    final doseTimes = data['instruction'] ?? '';
    final totalWeeks = data['total_weeks'] ?? 8;
    final weeksLeft = data['weeks_left'] ?? 6;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: BackButton(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Image.asset(
                'assets/pill.png',
                height: 100,
              ),
            ),
            const SizedBox(height: 20),
            pillDetailRow("Pill Name", name),
            pillDetailRow("Pill Dosage", dosage),
            pillDetailRow("Next Dose", nextDose),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F3EA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _infoSection("Dose", "$frequency | $doseTimes"),
                  const SizedBox(height: 12),
                  _infoSection("Takes", "Total $totalWeeks weeks | $weeksLeft weeks left"),
                  const SizedBox(height: 12),
                  _infoSection("Quantity",
                      "Total $totalQuantity capsules | $quantityLeft capsules left"),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      onPressed: () => showAddCapsulesDialog(context, _addCapsules),
                      child: const Text("Add Capsules", style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text("Addition History",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 10),
            capsuleAdditionHistory(docId),
          ],
        ),
      ),
    );
  }

  Widget _infoSection(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2F5D50)),
        ),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 15)),
      ],
    );
  }
}
