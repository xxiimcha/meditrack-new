import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class PatientFormScreen extends StatefulWidget {
  const PatientFormScreen({Key? key}) : super(key: key);

  @override
  State<PatientFormScreen> createState() => _PatientFormScreenState();
}

class _PatientFormScreenState extends State<PatientFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  DateTime? _birthDate;

  String _gender = 'Male';
  bool _isLoading = false;

  Future<void> _submitPatient() async {
    if (!_formKey.currentState!.validate() || _birthDate == null) return;

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not logged in');

      final age = DateTime.now().year - _birthDate!.year -
          (DateTime.now().month < _birthDate!.month ||
                  (DateTime.now().month == _birthDate!.month &&
                      DateTime.now().day < _birthDate!.day)
              ? 1
              : 0);

      await FirebaseFirestore.instance.collection('patients').add({
        'user_id': user.uid,
        'name': _nameController.text.trim(),
        'birthdate': Timestamp.fromDate(_birthDate!),
        'age': age,
        'gender': _gender,
        'created_at': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Patient registered successfully')),
      );

      Navigator.pop(context);
    } catch (e) {
      print('Error saving patient: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: Navigator.of(context).overlay!.context,
      builder: (_) => AlertDialog(
        title: const Text('About this Form'),
        content: const SingleChildScrollView(
          child: Text(
            'This form allows a user to register a patient under their Firebase account. '
            'Each patient record includes personal details, such as name, gender, and birthdate. '
            'The system automatically calculates the patient\'s age based on the selected birthdate. '
            'All submissions are securely stored in Firestore and linked to the authenticated user\'s ID.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectBirthDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2010),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _birthDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final birthDateText =
        _birthDate != null ? DateFormat.yMMMd().format(_birthDate!) : 'Select Birthdate';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Patient'),
        backgroundColor: const Color(0xFF2F5D50),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showAboutDialog(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Patient Information",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF1F3F4),
                ),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectBirthDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Birthdate',
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFFF1F3F4),
                  ),
                  child: Text(birthDateText),
                ),
              ),
              if (_birthDate == null)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                    'Birthdate is required',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _gender,
                decoration: const InputDecoration(
                  labelText: 'Gender',
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Color(0xFFF1F3F4),
                ),
                items: const [
                  DropdownMenuItem(value: 'Male', child: Text('Male')),
                  DropdownMenuItem(value: 'Female', child: Text('Female')),
                ],
                onChanged: (val) => setState(() => _gender = val!),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitPatient,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2F5D50),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
