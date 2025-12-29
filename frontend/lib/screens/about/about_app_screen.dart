import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About App'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // App Icon & Title
            Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.phone_android,
                    size: 72,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Smartphone Predict',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Version 1.01',
                    style: TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // About Section
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Smartphone Predict is an application that predicts the price range '
              'of a smartphone based on its hardware specifications. '
              'The prediction is performed using a Machine Learning model '
              'trained on a mobile price classification dataset.',
              style: TextStyle(fontSize: 14, height: 1.5),
            ),

            const SizedBox(height: 24),

            // Tech Stack Section
            const Text(
              'Tech Stack',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '• Frontend: Flutter\n'
              '• Backend: FastAPI Python\n'
              '• Machine Learning: Random Forest\n'
              '• Dataset: Mobile Price Classification (Kaggle)\n'
              '• Dataset: Mobiles Dataset (2025) (Kaggle)\n',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),

            const SizedBox(height: 24),

            // Footer
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              '© 2025 Smartphone Predict\n'
              'Built for learning and experimentation.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
