import 'package:flutter/material.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text('Privacy Policy', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('We value your privacy. Your data is stored securely and never shared with third parties. You can delete your account and data at any time.'),
              SizedBox(height: 16),
              Text('Data Usage:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('- Your vocabulary, progress, and lessons are stored locally and on our secure servers.'),
              Text('- We use OpenAI/Gemini for AI features, but do not share personal info.'),
              SizedBox(height: 16),
              Text('Contact us for any privacy concerns.'),
              SizedBox(height: 16),
              Text('Your privacy is important to us. We do not store your audio or personal data without consent. All sensitive data is encrypted and transmitted securely. For more details, visit our website or contact support.'),
            ],
          ),
        ),
      ),
    );
  }
}
