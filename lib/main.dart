import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'models/user.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final firstCamera = cameras.first;

  runApp(MyApp(camera: firstCamera));
}

class MyApp extends StatelessWidget {
  final CameraDescription camera;

  const MyApp({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'FRSA',
      theme: ThemeData(
        fontFamily: 'Poppins',
        primaryColor: const Color(0xFF1A6BD4),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          iconTheme: IconThemeData(color: Color(0xFF1A6BD4)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith<Color>(
              (Set<WidgetState> states) {
                if (states.contains(WidgetState.pressed)) {
                  return const Color(0xFF1753A0);
                }
                return const Color(0xFF1A6BD4);
              },
            ),
            foregroundColor: WidgetStateProperty.all<Color>(Colors.white),
          ),
        ),
      ),
      home: MainPage(camera: camera),
    );
  }
}

class MainPage extends StatelessWidget {
  final CameraDescription camera;

  const MainPage({super.key, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFF1A6BD4)),
            iconSize: 32,
            padding: EdgeInsets.all(20),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => CreateNewUserPage(camera: camera)),
              );
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'Icons/Logo_Main_Page.svg',
                height: 138.0, // Adjust the height as needed
              ),
              const SizedBox(height: 24),
              Container(
                width: 330,
                child: const Text(
                  'Hello! Please, scan your face in order to get access to the app!',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontSize: 20),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                width: 128,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    final user = User(
                      name: '',
                      surname: '',
                      birthDate: '',
                      placeOfStudy: '',
                      cityOfLiving: '',
                    );
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              FaceScanPage(user: user, camera: camera)),
                    );
                  },
                  child: const Text('Start Scan'),
                ),
              ),
              const SizedBox(height: 60)
            ],
          ),
        ),
      ),
    );
  }
}

class CreateNewUserPage extends StatefulWidget {
  final CameraDescription camera;

  const CreateNewUserPage({super.key, required this.camera});

  @override
  CreateNewUserPageState createState() => CreateNewUserPageState();
}

class CreateNewUserPageState extends State<CreateNewUserPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _placeOfStudyController = TextEditingController();
  final _cityOfLivingController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 70,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SvgPicture.asset(
                'Icons/Logo.svg',
                height: 36.0, // Adjust the height as needed
              ),
            ),
            // Optional spacing between icon and title
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create a new User',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please, fill in your personal information',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 24),
              _buildCustomFormField('Your Name', _nameController),
              const SizedBox(height: 16),
              _buildCustomFormField('Your Surname', _surnameController),
              const SizedBox(height: 16),
              _buildCustomFormField('Birth Date', _birthDateController),
              const SizedBox(height: 16),
              _buildCustomFormField('University Name', _placeOfStudyController),
              const SizedBox(height: 24),
              _buildCustomFormField('City', _cityOfLivingController),
              const SizedBox(height: 24),
              Center(
                child: Container(
                  height: 48,
                  width: 1000,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Handle form submission here
                      }
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
                    label: const Text(
                      'Create User',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A6BD4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100.0),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomFormField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
          fontSize: 16,
          color: Colors.black87,
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFFB3D9FF)),
          borderRadius: BorderRadius.circular(30.0),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Color(0xFF1A6BD4)),
          borderRadius: BorderRadius.circular(30.0),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }
}

class FaceScanPage extends StatefulWidget {
  final User user;
  final bool isNewUser;
  final CameraDescription camera;

  const FaceScanPage(
      {super.key,
      required this.user,
      this.isNewUser = false,
      required this.camera});

  @override
  // ignore: library_private_types_in_public_api
  _FaceScanPageState createState() => _FaceScanPageState();
}

class _FaceScanPageState extends State<FaceScanPage> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  int _stage = 1;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _startScan() {
    setState(() {
      _stage = 2;
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _stage = 3;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              'Icons/Logo.svg',
              height: 24.0, // Adjust the height as needed
            ), // Optional spacing between icon and title
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                Expanded(
                  child: CameraPreview(_controller),
                ),
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      Text(
                        _stage == 1
                            ? 'Please, look into the camera'
                            : _stage == 2
                                ? 'Scanning the face'
                                : 'Face scan completed Successfully!',
                        style: const TextStyle(fontSize: 18),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _stage == 1
                            ? 'Make sure your face matches the oval'
                            : _stage == 3
                                ? 'The face could not be recognized :('
                                : '',
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () {
                          if (_stage == 1) {
                            _startScan();
                          } else if (_stage == 3) {
                            if (widget.isNewUser) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserCreationResultPage(
                                      isSuccess: true, camera: widget.camera),
                                ),
                              );
                            } else {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => UserProfilePage(
                                      user: widget.user, camera: widget.camera),
                                ),
                              );
                            }
                          }
                        },
                        child: Text(
                          _stage == 1
                              ? 'Start Scan'
                              : _stage == 2
                                  ? 'Skip'
                                  : 'Next',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }
}

class UserCreationResultPage extends StatelessWidget {
  final bool isSuccess;
  final CameraDescription camera;

  const UserCreationResultPage(
      {super.key, required this.isSuccess, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              'Icons/Logo.svg',
              height: 24.0, // Adjust the height as needed
            ), // Optional spacing between icon and title
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: <Widget>[
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 100,
              ),
              Text(
                isSuccess
                    ? 'Your Profile created successfully!'
                    : 'Your Profile could not be created',
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(
                        builder: (context) => MainPage(camera: camera)),
                    (route) => false,
                  );
                },
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfilePage extends StatelessWidget {
  final User user;
  final CameraDescription camera;

  const UserProfilePage({super.key, required this.user, required this.camera});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SvgPicture.asset(
              'Icons/Logo.svg',
              height: 24.0, // Adjust the height as needed
            ), // Optional spacing between icon and title
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextFormField(
              initialValue: user.name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextFormField(
              initialValue: user.surname,
              decoration: const InputDecoration(labelText: 'Surname'),
            ),
            TextFormField(
              initialValue: user.birthDate,
              decoration: const InputDecoration(labelText: 'Birth Date'),
            ),
            TextFormField(
              initialValue: user.placeOfStudy,
              decoration: const InputDecoration(labelText: 'Place of Study'),
            ),
            TextFormField(
              initialValue: user.cityOfLiving,
              decoration: const InputDecoration(labelText: 'City of Living'),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MainPage(camera: camera)),
                  (route) => false,
                );
              },
              child: const Text('Log Out'),
            ),
          ],
        ),
      ),
    );
  }
}
