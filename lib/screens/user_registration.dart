import 'package:flutter/material.dart';

class UserRegistrationScreen extends StatefulWidget {
  const UserRegistrationScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _UserRegistrationScreenState createState() => _UserRegistrationScreenState();
}

class _UserRegistrationScreenState extends State<UserRegistrationScreen> {
  int _currentStep = 0;
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _studyPlaceController = TextEditingController();
  final _livingPlaceController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Registration'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 2) {
            setState(() {
              _currentStep += 1;
            });
          } else {
            if (_formKey.currentState!.validate()) {
              Navigator.pushNamed(context, '/face-scan');
            }
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep -= 1;
            });
          }
        },
        steps: [
          Step(
            title: const Text('Personal Information'),
            content: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Name'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _surnameController,
                    decoration: const InputDecoration(labelText: 'Surname'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your surname';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _birthDateController,
                    decoration: const InputDecoration(labelText: 'Birth Date'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your birth date';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _studyPlaceController,
                    decoration:
                        const InputDecoration(labelText: 'Place of Study'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your place of study';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _livingPlaceController,
                    decoration:
                        const InputDecoration(labelText: 'Place of Living'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter your place of living';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: const Text('Face Scan'),
            content: Column(
              children: [
                const Text('Please scan your face to complete registration.'),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/face-scan');
                  },
                  child: const Text('Scan Face'),
                ),
              ],
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: const Text('Confirmation'),
            content: Column(
              children: [
                const Text('Review your information and submit.'),
                ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.pushNamed(context, '/access-result');
                    }
                  },
                  child: const Text('Submit'),
                ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
        ],
      ),
    );
  }
}
