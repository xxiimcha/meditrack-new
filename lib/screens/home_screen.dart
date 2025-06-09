import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/custom_bottom_navbar.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const String apiBaseUrl = 'https://meditrack-ai.onrender.com';

  List<QueryDocumentSnapshot> todayMedications = [];
  Map<String, List<Map<String, dynamic>>> intakeHistories = {};
  bool isLoading = true;
  String userFullName = "Loading...";
  Map<String, dynamic>? patientData;

  @override
  void initState() {
    super.initState();
    loadUserData();
    checkPatientsAndLoad();
  }

  Future<void> loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          userFullName = "${data['first_name']} ${data['last_name']}";
        });
      }
    }
  }

  Future<void> checkPatientsAndLoad() async {
    setState(() => isLoading = true);
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('patients')
        .where('user_id', isEqualTo: user.uid)
        .get();

    if (snapshot.docs.isEmpty) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Text('No Patient Found'),
          content: const Text('You have no registered patients yet. Please fill out the form.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/patient_form');
              },
              child: const Text('Proceed to Form'),
            ),
          ],
        ),
      );
    } else {
      setState(() => patientData = snapshot.docs.first.data());
      await fetchTodayMedicationsWithIntakeStatus();
    }

    setState(() => isLoading = false);
  }

  Future<void> fetchTodayMedicationsWithIntakeStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('medication_schedules')
        .where('user_id', isEqualTo: user.uid)
        .get();

    List<QueryDocumentSnapshot> meds = snapshot.docs;
    Map<String, List<Map<String, dynamic>>> statusMap = {};

    final response = await http.post(
      Uri.parse('$apiBaseUrl/check_intake_status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'user_id': user.uid}),
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body);

      for (var item in responseData) {
        final medName = item['medication'];
        final intakeList = item['intake_status'] as List<dynamic>;

        for (var doc in meds) {
          if ((doc['medication_name'] ?? '').toLowerCase() == medName.toLowerCase()) {
            statusMap[doc.id] = intakeList.cast<Map<String, dynamic>>();
          }
        }
      }
    }

    setState(() {
      todayMedications = meds;
      intakeHistories = statusMap;
    });
  }

Widget _buildPillCard(Map<String, dynamic> data, bool isPrimary, {List<Map<String, dynamic>>? history}) {
  return GestureDetector(
    onTap: () {
      if (history != null && history.isNotEmpty) {
        final today = DateTime.now();
        final filtered = history.where((log) {
          final logDate = DateTime.parse(log['datetime']);
          return logDate.isBefore(today.add(const Duration(days: 1)));
        }).toList();

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Intake Log: ${data['medication_name']}'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final log = filtered[index];
                  return ListTile(
                    title: Text(log['datetime'].toString().split('T')[0]),
                    subtitle: Text(
                      '${log['status']} – Expected at: ${DateTime.parse(log['datetime']).toLocal().hour.toString().padLeft(2, '0')}:${DateTime.parse(log['datetime']).toLocal().minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Icon(
                      log['status'] == 'Missed'
                          ? Icons.close
                          : log['status'] == 'Wrong Medication'
                              ? Icons.warning
                              : Icons.check,
                      color: log['status'] == 'Missed'
                          ? Colors.red
                          : log['status'] == 'Wrong Medication'
                              ? Colors.orange
                              : Colors.green,
                    ),
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Close"))
            ],
          ),
        );
      }
    },
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isPrimary ? const Color(0xFF2F5D50) : const Color(0xFFF8F3EA),
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['medication_name'] ?? 'Unnamed',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isPrimary ? Colors.white : const Color(0xFF2F5D50),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            data['instruction'] ?? '',
            style: TextStyle(
              color: isPrimary ? Colors.white70 : const Color(0xFF78917C),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(children: [
                Text('Dosage', style: _pillSubLabelStyle(isPrimary)),
                const SizedBox(height: 4),
                Text('20mg', style: _pillSubTextStyle(isPrimary)),
              ]),
              Column(children: [
                Text('Time', style: _pillSubLabelStyle(isPrimary)),
                const SizedBox(height: 4),
                Text('10:00 am', style: _pillSubTextStyle(isPrimary)),
              ]),
              Column(children: [
                Text('Takes', style: _pillSubLabelStyle(isPrimary)),
                const SizedBox(height: 4),
                Text('3 left', style: _pillSubTextStyle(isPrimary)),
              ]),
            ],
          ),
          if (history != null && history.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Recent Logs:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            for (var log in history
                .where((log) => DateTime.parse(log['datetime']).isBefore(DateTime.now().add(const Duration(days: 1))))
                .take(5))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Text(
                  "• ${log['datetime'].toString().split('T')[0]} – ${log['status']}",
                  style: TextStyle(
                    color: log['status'] == "Missed"
                        ? Colors.red
                        : log['status'] == "Wrong Medication"
                            ? Colors.orange
                            : Colors.green,
                    fontSize: 13,
                  ),
                ),
              ),
          ],
        ],
      ),
    ),
  );
}


  TextStyle _pillSubLabelStyle(bool isPrimary) => TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: isPrimary ? Colors.white : Colors.black,
      );

  TextStyle _pillSubTextStyle(bool isPrimary) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: isPrimary ? Colors.white : const Color(0xFF2F5D50),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: CircleAvatar(
            backgroundColor: Colors.purple[100],
            radius: 25,
            child: const Icon(Icons.person, color: Colors.black),
          ),
        ),
        title: Text(
          "Hello, $userFullName",
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16.0),
            child: Icon(Icons.notifications, color: Colors.black),
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pills for today', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  if (todayMedications.isNotEmpty) ...[
                    _buildPillCard(
                      todayMedications[0].data() as Map<String, dynamic>,
                      true,
                      history: intakeHistories[todayMedications[0].id],
                    ),
                    const SizedBox(height: 20),
                    const Text('Additional Vitamins', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    for (int i = 1; i < todayMedications.length; i++)
                      _buildPillCard(
                        todayMedications[i].data() as Map<String, dynamic>,
                        false,
                        history: intakeHistories[todayMedications[i].id],
                      ),
                  ] else
                    const Text("No medication schedules for today."),
                ],
              ),
            ),
      bottomNavigationBar: const CustomBottomNavBar(),
    );
  }
}
