import 'package:flutter/material.dart';
import 'about/about_app_screen.dart';
import 'about/about_license_screen.dart';

class AboutMenuScreen extends StatelessWidget {
  const AboutMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        centerTitle: true,
      ),
      body: ListView(
        children: [
          const SizedBox(height: 8),

          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About App'),
            subtitle: const Text('Application information'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutAppScreen(),
                ),
              );
            },
          ),

          const Divider(height: 1),

          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('License'),
            subtitle: const Text('MIT License'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const AboutLicenseScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
