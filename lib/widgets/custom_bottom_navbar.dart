import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../services/notification_service.dart';

class CustomBottomNavBar extends StatelessWidget {
  const CustomBottomNavBar({Key? key}) : super(key: key);

  void _showAddScheduleDialog(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController frequencyController = TextEditingController();
    final TextEditingController instructionController = TextEditingController();
    final TextEditingController intervalPerHourController = TextEditingController();

    String intervalOption = 'Everyday';
    DateTime? startDate;
    DateTime? untilDate;
    TimeOfDay? firstIntakeTime;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            backgroundColor: const Color(0xFFFDFBF9),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            titlePadding: const EdgeInsets.only(top: 20),
            title: const Center(
              child: Text(
                'Add Medication Schedule',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2F5D50),
                ),
              ),
            ),
            content: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(),
                    const SizedBox(height: 10),
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Medication Name',
                        prefixIcon: const Icon(Icons.medication_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: frequencyController,
                      decoration: InputDecoration(
                        labelText: 'Frequency (e.g. 3 times a day)',
                        prefixIcon: const Icon(Icons.repeat),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: intervalPerHourController,
                      decoration: InputDecoration(
                        labelText: 'Interval Per Hour (e.g. every 6 hours)',
                        prefixIcon: const Icon(Icons.timelapse),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: intervalOption,
                      decoration: InputDecoration(
                        labelText: 'Interval',
                        prefixIcon: const Icon(Icons.schedule),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Everyday', child: Text('Everyday')),
                        DropdownMenuItem(value: 'Every Other Day', child: Text('Every Other Day')),
                        DropdownMenuItem(value: 'Every 3 Days', child: Text('Every 3 Days')),
                        DropdownMenuItem(value: 'Weekly', child: Text('Weekly')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            intervalOption = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: instructionController,
                      decoration: InputDecoration(
                        labelText: 'Instruction (e.g. After eating)',
                        prefixIcon: const Icon(Icons.notes),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(Icons.calendar_today),
                      title: Text(startDate == null
                          ? 'Start Date'
                          : DateFormat.yMMMd().format(startDate!)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => startDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.calendar_month),
                      title: Text(untilDate == null
                          ? 'Until Date'
                          : DateFormat.yMMMd().format(untilDate!)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 1)),
                          firstDate: DateTime(2023),
                          lastDate: DateTime(2100),
                        );
                        if (picked != null) {
                          setState(() => untilDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      leading: const Icon(Icons.access_time),
                      title: Text(firstIntakeTime == null
                          ? 'Select First Intake Time'
                          : firstIntakeTime!.format(context)),
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setState(() => firstIntakeTime = picked);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            actionsAlignment: MainAxisAlignment.spaceBetween,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(foregroundColor: Colors.grey.shade700),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("User not logged in.")),
                    );
                    return;
                  }

                  try {
                    final patientSnapshot = await FirebaseFirestore.instance
                        .collection('patients')
                        .where('user_id', isEqualTo: user.uid)
                        .limit(1)
                        .get();

                    if (patientSnapshot.docs.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("No patient profile found.")),
                      );
                      return;
                    }

                    final patientId = patientSnapshot.docs.first.id;

                    await FirebaseFirestore.instance.collection('medication_schedules').add({
                      'patient_id': patientId,
                      'user_id': user.uid,
                      'medication_name': nameController.text.trim(),
                      'frequency': frequencyController.text.trim(),
                      'interval_per_hour': int.tryParse(intervalPerHourController.text.trim()),
                      'interval': intervalOption,
                      'instruction': instructionController.text.trim(),
                      'start_date': startDate != null ? Timestamp.fromDate(startDate!) : null,
                      'until_date': untilDate != null ? Timestamp.fromDate(untilDate!) : null,
                      'first_intake_time': firstIntakeTime != null
                          ? '${firstIntakeTime!.hour.toString().padLeft(2, '0')}:${firstIntakeTime!.minute.toString().padLeft(2, '0')}'
                          : null,
                      'created_at': Timestamp.now(),
                    });

                    // 🔔 Test reminder
                    DateTime reminderTime = DateTime.now().add(const Duration(seconds: 10));
                    await NotificationService.scheduleReminder(
                      id: reminderTime.hashCode,
                      title: 'Time to take your medication',
                      body: nameController.text.trim(),
                      time: reminderTime,
                    );

                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Schedule saved successfully.")),
                    );
                  } catch (e) {
                    print('Error saving schedule: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Error: $e")),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2F5D50),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Save"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.green,
      unselectedItemColor: Colors.grey,
      onTap: (index) {
        switch (index) {
          case 0:
            Navigator.pushNamed(context, '/');
            break;
          case 1:
            Navigator.pushNamed(context, '/schedule');
            break;
          case 2:
            _showAddScheduleDialog(context);
            break;
          case 3:
            Navigator.pushNamed(context, '/list');
            break;
          case 4:
            Navigator.pushNamed(context, '/profile');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
        BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: "Schedule"),
        BottomNavigationBarItem(icon: Icon(Icons.add), label: "Add"),
        BottomNavigationBarItem(icon: Icon(Icons.list), label: "List"),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
      ],
    );
  }
}
