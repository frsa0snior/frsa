import 'package:flutter/material.dart';

class UserDataScreen extends StatelessWidget {
  final Map<String, String> userData = {
    'Name': 'John',
    'Surname': 'Doe',
    'Birth Date': '01/01/1990',
    'Place of Study': 'University of Flutter',
    'Place of Living': 'Flutter City',
  };

  UserDataScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Data'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.builder(
          itemCount: userData.length,
          itemBuilder: (context, index) {
            String key = userData.keys.elementAt(index);
            return ListTile(
              title: Text(key),
              subtitle: Text(userData[key]!),
            );
          },
        ),
      ),
    );
  }
}
