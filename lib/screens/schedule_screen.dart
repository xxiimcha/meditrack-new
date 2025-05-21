import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:table_calendar/table_calendar.dart';

import '../widgets/schedules/medication_event_loader.dart';
import '../widgets/schedules/calendar_card.dart';
import '../widgets/custom_bottom_navbar.dart';

class ScheduleScreen extends StatefulWidget {
  @override
  _ScheduleScreenState createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime selectedDate = DateTime.now();
  Map<DateTime, List<String>> _medicationEvents = {};

  @override
  void initState() {
    super.initState();
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    final events = await loadMedicationEvents();
    setState(() {
      _medicationEvents = events;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(
            primary: Colors.green.shade700,
            onPrimary: Colors.white,
            onSurface: Colors.black,
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(foregroundColor: Colors.green),
          ),
        ),
        child: child!,
      ),
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() => selectedDate = pickedDate);
      _showScheduleDialog(context);
    }
  }

void _showScheduleDialog(BuildContext context) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final snapshot = await FirebaseFirestore.instance
      .collection('medication_schedules')
      .where('user_id', isEqualTo: user.uid)
      .get();

  final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
  final selectedStr = DateFormat('yyyy-MM-dd').format(selectedDate);

  final filtered = snapshot.docs.where((doc) {
    final start = doc['start_date'] as Timestamp?;
    final until = doc['until_date'] as Timestamp?;
    return _isDateInRange(selectedDate, start, until);
  }).toList();

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: const EdgeInsets.all(20),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                DateFormat('EEEE, MMM d, yyyy').format(selectedDate),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              filtered.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Text("No medications scheduled.",
                          style: TextStyle(fontSize: 16, color: Colors.grey)),
                    )
                  : SizedBox(
                      width: double.maxFinite,
                      height: 400,
                      child: ListView.separated(
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final doc = filtered[index];
                          final data = doc.data() as Map<String, dynamic>;
                          final docId = doc.id;

                          return FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('medication_schedules')
                                .doc(docId)
                                .collection('medication_intakes')
                                .doc(selectedStr)
                                .get(),
                            builder: (context, snapshot) {
                              final alreadyTaken = snapshot.data?.exists == true;

                              return Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F9F9),
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['medication_name'] ?? 'Medication',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF2F5D50),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    if (data['instruction'] != null)
                                      Text("Instruction: ${data['instruction']}"),
                                    if (data['frequency'] != null)
                                      Text("Frequency: ${data['frequency']}"),
                                    if (data['interval'] != null)
                                      Text("Interval: ${data['interval']}"),
                                    if (data['time'] != null)
                                      Text("Time: ${data['time']}"),
                                    const SizedBox(height: 12),
                                    if (selectedStr == todayStr)
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: ElevatedButton.icon(
                                          onPressed: alreadyTaken
                                              ? null
                                              : () async {
                                                  await FirebaseFirestore.instance
                                                      .collection('medication_schedules')
                                                      .doc(docId)
                                                      .collection('medication_intakes')
                                                      .doc(selectedStr)
                                                      .set({
                                                    'taken': true,
                                                    'taken_at': Timestamp.now(),
                                                  });

                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(
                                                      content: Text('Marked as taken'),
                                                    ),
                                                  );

                                                  Navigator.pop(context);
                                                  _showScheduleDialog(context);
                                                },
                                          icon: Icon(alreadyTaken ? Icons.check : Icons.add_task),
                                          label: Text(alreadyTaken
                                              ? "Already Taken"
                                              : "Mark as Taken"),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor:
                                                alreadyTaken ? Colors.grey : Colors.green,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 16, vertical: 12),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close", style: TextStyle(color: Colors.red)),
                ),
              )
            ],
          ),
        ),
      );
    },
  );
}


  bool _isDateInRange(DateTime selected, Timestamp? start, Timestamp? until) {
    final startDate = start?.toDate();
    final untilDate = until?.toDate();
    if (startDate == null || untilDate == null) return false;
    return selected.isAfter(startDate.subtract(const Duration(days: 1))) &&
        selected.isBefore(untilDate.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: BackButton(color: Colors.black),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications, color: Colors.black),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Calendar",
                style: TextStyle(
                    fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            const SizedBox(height: 16),
            CalendarCard(
              selectedDate: selectedDate,
              events: _medicationEvents,
              onDateChanged: (date) {
                setState(() => selectedDate = date);
                _showScheduleDialog(context);
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}
