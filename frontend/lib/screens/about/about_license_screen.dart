import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutLicenseScreen extends StatelessWidget {
  const AboutLicenseScreen({super.key});

  Future<String> _loadLicense() async {
    return await rootBundle.loadString('assets/licenses/mit.txt');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('License'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<String>(
          future: _loadLicense(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Failed to load license.',
                  style: TextStyle(color: Colors.red),
                ),
              );
            }

            return SingleChildScrollView(
              child: SelectableText(
                snapshot.data!,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
