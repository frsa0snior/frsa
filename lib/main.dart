// ignore_for_file: sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'models/user.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final cameras = await availableCameras();
  final frontCamera = cameras.firstWhere(
    (camera) => camera.lensDirection == CameraLensDirection.front,
  );

  runApp(MyApp(camera: frontCamera));
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
            overlayColor: WidgetStateProperty.all<Color>(
                Colors.blue.withOpacity(0.1)), // Button press effect
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70.0,
        actions: [
          IconButton(
            icon: const Icon(Icons.person, color: Color(0xFF1A6BD4)),
            iconSize: 32,
            padding: const EdgeInsets.all(20),
            onPressed: () {
              Navigator.push(
                context,
                _createRoute(CreateNewUserPage(camera: camera)),
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
                      _createRoute(FaceScanPage(user: user, camera: camera)),
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

Route _createRoute(Widget page) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      const begin = Offset(1.0, 0.0);
      const end = Offset.zero;
      const curve = Curves.ease;

      var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));

      var offsetAnimation = animation.drive(tween);

      return SlideTransition(
        position: offsetAnimation,
        child: child,
      );
    },
  );
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
      backgroundColor: Colors.white,
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
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please, fill in your personal information',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 71, 71, 71),
                ),
              ),
              const SizedBox(height: 40),
              _buildCustomFormField('Your Name', _nameController),
              const SizedBox(height: 20),
              _buildCustomFormField('Your Surname', _surnameController),
              const SizedBox(height: 20),
              _buildCustomDateField('Birth Date', _birthDateController),
              const SizedBox(height: 20),
              _buildCustomFormField('University Name', _placeOfStudyController),
              const SizedBox(height: 20),
              _buildCustomFormField('City', _cityOfLivingController),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  height: 48,
                  width: 1000,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        final user = User(
                          name: _nameController.text,
                          surname: _surnameController.text,
                          birthDate: _birthDateController.text,
                          placeOfStudy: _placeOfStudyController.text,
                          cityOfLiving: _cityOfLivingController.text,
                        );
                        Navigator.push(
                          context,
                          _createRoute(FaceScanPage(
                            user: user,
                            camera: widget.camera,
                            isNewUser: true,
                          )),
                        );
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

  Widget _buildCustomDateField(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900), // Earliest selectable date
          lastDate: DateTime.now(), // Latest selectable date
        );

        if (pickedDate != null) {
          // Format the date (e.g., DD/MM/YYYY)
          String formattedDate =
              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          controller.text = formattedDate;
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB3D9FF)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF1A6BD4)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your $label';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCustomFormField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB3D9FF)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF1A6BD4)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class FaceScanPage extends StatefulWidget {
  final User user;
  final bool isNewUser;
  final CameraDescription camera;

  const FaceScanPage({
    super.key,
    required this.user,
    this.isNewUser = false,
    required this.camera,
  });

  @override
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
      _stage = 2; // Scanning phase
    });

    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        _stage = 3; // Scan complete (success or failure)
      });
    });
  }

  String _getOverlaySvg() {
    switch (_stage) {
      case 2: // Scanning detected phase
        return 'svgs/Camera_Frame_Face_Detected.svg';
      case 3: // Completed (success or failure)
        return widget.isNewUser
            ? 'svgs/Camera_Frame_Face_Recognized.svg'
            : 'svgs/Camera_Frame_Face_Not_Recognized.svg';
      default: // Initial scanning frame
        return 'svgs/Camera_Frame.svg';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        toolbarHeight: 70,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: SvgPicture.asset(
                'Icons/Logo.svg',
                height: 36.0,
              ),
            ),
          ],
        ),
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Column(
              children: [
                // Camera preview with rounded corners and overlay
                SizedBox(
                  height: 600,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: ClipRRect(
                      borderRadius:
                          BorderRadius.circular(16.0), // Rounded edges
                      child: AspectRatio(
                        aspectRatio: _controller.value.aspectRatio,
                        child: Stack(
                          children: [
                            Container(
                                height: 600, child: CameraPreview(_controller)),
                            Positioned.fill(
                              child: SvgPicture.asset(
                                _getOverlaySvg(),
                                fit: BoxFit
                                    .cover, // Ensure overlay matches preview size
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // White background section with text and button
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16.0, vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _stage == 1
                            ? 'Please, look into the camera'
                            : _stage == 2
                                ? 'Scanning...'
                                : widget.isNewUser
                                    ? 'Scan Successful!'
                                    : 'Scan Failed!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _stage == 3 && !widget.isNewUser
                              ? Colors.red
                              : Colors.black,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      Container(
                        height: 48,
                        width: 160,
                        child: ElevatedButton(
                          onPressed: () {
                            if (_stage == 1) {
                              _startScan();
                            } else if (_stage == 3) {
                              if (widget.isNewUser) {
                                Navigator.push(
                                  context,
                                  _createRoute(UserCreationResultPage(
                                    isSuccess: true,
                                    camera: widget.camera,
                                  )),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  _createRoute(UserProfilePage(
                                    user: widget.user,
                                    camera: widget.camera,
                                  )),
                                );
                              }
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32.0, vertical: 12.0),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50.0),
                            ),
                          ),
                          child: Text(
                            _stage == 1
                                ? 'Start Scan'
                                : _stage == 2
                                    ? 'Skip'
                                    : 'Next',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // Show a loading spinner while the camera is initializing
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
      backgroundColor: Colors.white,
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
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Center(
                child: SvgPicture.asset(
                  isSuccess
                      ? 'Icons/Profile_Create_Successful.svg'
                      : 'Icons/Profile_Create_Failed.svg',
                  height: 130.0, // Adjust the size to match your design
                ),
              ),
              Text(
                isSuccess
                    ? 'Your Profile created successfully!'
                    : 'Your Profile could not be created',
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 20),
              Container(
                height: 48,
                width: 128,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      _createRoute(MainPage(camera: camera)),
                      (route) => false,
                    );
                  },
                  child: const Text('Go Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UserProfilePage extends StatefulWidget {
  final User user;
  final CameraDescription camera;

  const UserProfilePage({super.key, required this.user, required this.camera});

  @override
  // ignore: library_private_types_in_public_api
  _UserProfilePageState createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _surnameController;
  late final TextEditingController _birthDateController;
  late final TextEditingController _placeOfStudyController;
  late final TextEditingController _cityOfLivingController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _surnameController = TextEditingController(text: widget.user.surname);
    _birthDateController = TextEditingController(text: widget.user.birthDate);
    _placeOfStudyController =
        TextEditingController(text: widget.user.placeOfStudy);
    _cityOfLivingController =
        TextEditingController(text: widget.user.cityOfLiving);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _birthDateController.dispose();
    _placeOfStudyController.dispose();
    _cityOfLivingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
                'Edit User Profile',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This is your profile information. You can edit it if you want.',
                style: TextStyle(
                  fontSize: 14,
                  color: Color.fromARGB(255, 71, 71, 71),
                ),
              ),
              const SizedBox(height: 40),
              _buildCustomFormField('Your Name', _nameController),
              const SizedBox(height: 20),
              _buildCustomFormField('Your Surname', _surnameController),
              const SizedBox(height: 20),
              _buildCustomDateField('Birth Date', _birthDateController),
              const SizedBox(height: 20),
              _buildCustomFormField('University Name', _placeOfStudyController),
              const SizedBox(height: 20),
              _buildCustomFormField('City', _cityOfLivingController),
              const SizedBox(height: 32),
              Center(
                child: Container(
                  height: 48,
                  width: 1000,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        _createRoute(MainPage(camera: widget.camera)),
                        (route) => false,
                      );
                    },
                    icon: const Icon(Icons.logout, color: Colors.white),
                    label: const Text(
                      'Log Out',
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

  Widget _buildCustomDateField(String label, TextEditingController controller) {
    return GestureDetector(
      onTap: () async {
        FocusScope.of(context).requestFocus(FocusNode()); // Dismiss keyboard
        DateTime? pickedDate = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(1900), // Earliest selectable date
          lastDate: DateTime.now(), // Latest selectable date
        );

        if (pickedDate != null) {
          // Format the date (e.g., DD/MM/YYYY)
          String formattedDate =
              "${pickedDate.day}/${pickedDate.month}/${pickedDate.year}";
          controller.text = formattedDate;
        }
      },
      child: AbsorbPointer(
        child: TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB3D9FF)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF1A6BD4)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select your $label';
            }
            return null;
          },
        ),
      ),
    );
  }

  Widget _buildCustomFormField(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
            contentPadding:
                const EdgeInsets.symmetric(vertical: 16.0, horizontal: 28.0),
            enabledBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFFB3D9FF)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Color(0xFF1A6BD4)),
              borderRadius: BorderRadius.circular(100.0),
            ),
            errorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderSide: const BorderSide(color: Colors.red),
              borderRadius: BorderRadius.circular(100.0),
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please enter your $label';
            }
            return null;
          },
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
