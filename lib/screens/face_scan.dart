import 'package:flutter/material.dart';

class FaceScanScreen extends StatelessWidget {
  const FaceScanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Scan'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Face scanning in progress...'),
            // Implement face scanning functionality here
            ElevatedButton(
              onPressed: () {
                // After scanning, navigate to access result
                Navigator.pushNamed(context, '/access-result');
              },
              child: const Text('Proceed'),
            ),
          ],
        ),
      ),
    );
  }
}
