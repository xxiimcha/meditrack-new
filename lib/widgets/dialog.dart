import 'package:flutter/material.dart';

class AboutDialogBox {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'About',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Welcome to MediTrack, your personal assistant for managing medications safely and effectively.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'We understand how important it is to take medications on time and as prescribed—whether it’s for daily vitamins, ongoing prescriptions, or short-term treatments. MediTrack is designed to simplify your health routine by helping you stay on top of your medication schedule.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'With MediTrack, you can:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Set personalized medication reminders'),
                    Text('• Track your dosage history'),
                    Text('• Monitor dates'),
                    Text('• View daily, weekly, and monthly logs'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text(
                'Whether you\'re managing your own medication or assisting a loved one, MediTrack provides a simple and secure way to take control of your health.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text(
                'Your health matters. Let us help you take care of it—one reminder at a time.',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.green,
                ),
              ),
            ],
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
}

class HelpDialogBox {
  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Help',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                'Need assistance with MediTrack? You’re in the right place! Here’s a quick guide to get you started and answer common questions.',
                style: TextStyle(height: 1.5),
              ),
              SizedBox(height: 16),
              Text('Getting Started', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Padding(
                padding: EdgeInsets.only(left: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('• Add a Medication: Tap the “+” icon to enter your medication name, dosage, frequency, and schedule.'),
                    Text('• Set Reminders: Customize alert times and notification settings so you never miss a dose.'),
                    Text('• View Your Schedule: Use the calendar or timeline view to see your upcoming doses.'),
                  ],
                ),
              ),
              SizedBox(height: 16),
              Text('Common Questions', style: TextStyle(fontWeight: FontWeight.bold)),
              SizedBox(height: 12),
              Text('Q: How do I edit or delete a medication?'),
              Text('A: Go to the medication list, tap the medication you want to update, and choose “Edit” or “Delete.”'),
              SizedBox(height: 10),
              Text('Q: Can I track multiple users?'),
              Text('A: Yes! You can manage multiple profiles from the settings menu—perfect for caregivers or families.'),
              SizedBox(height: 10),
              Text('Q: What if I miss a dose?'),
              Text('A: Don’t worry. You can log a missed dose manually, or choose to skip it. MediTrack will keep a record for you.'),
              SizedBox(height: 10),
              Text('Q: Is my data private?'),
              Text('A: Absolutely. Your data is securely stored and never shared without your permission. You can learn more in our Privacy Policy.'),
              SizedBox(height: 16),
              Text('Still need help?', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Reach out to our support team at Meditracksystem@gmail.com\nor visit our FAQ page (#) for more information.'),
              SizedBox(height: 16),
              Text('We\'re here to help—every step of the way.', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
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
}
