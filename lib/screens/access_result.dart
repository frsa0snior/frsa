import 'package:flutter/material.dart';

class AccessResultScreen extends StatelessWidget {
  final bool isSuccess;

  const AccessResultScreen({super.key, required this.isSuccess});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Access ${isSuccess ? 'Granted' : 'Denied'}'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSuccess ? Icons.check_circle : Icons.error,
              color: isSuccess ? Colors.green : Colors.red,
              size: 100,
            ),
            const SizedBox(height: 20),
            Text(
              isSuccess ? 'Access Granted' : 'Access Denied',
              style: const TextStyle(fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (isSuccess) {
                  Navigator.pushNamed(context, '/user-data');
                } else {
                  Navigator.pop(context);
                }
              },
              child: Text(isSuccess ? 'View Data' : 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
