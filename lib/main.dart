// ignore_for_file: sized_box_for_whitespace, use_build_context_synchronously, avoid_print

import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'models/user.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'dart:math';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'dart:io';
import 'dart:async';
import 'package:firebase_storage/firebase_storage.dart';
//import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

Future<List<Face>> detectFaces(InputImage inputImage) async {
  final options = FaceDetectorOptions(
    enableContours: true,
    enableLandmarks: true,
  );

  final faceDetector = FaceDetector(options: options);
  final List<Face> faces = await faceDetector.processImage(inputImage);

  faceDetector.close();
  return faces;
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();

  // Select the front camera, if available.
  CameraDescription? frontCamera;
  for (var camera in cameras) {
    if (camera.lensDirection == CameraLensDirection.front) {
      frontCamera = camera;
      break;
    }
  }

  // If a front camera is found, pass it to the app; otherwise, handle accordingly.
  if (frontCamera != null) {
    runApp(MyApp(camera: frontCamera));
  } else {
    // Handle the case where no front camera is found.
    runApp(MyApp(camera: cameras.first)); // Default to the first camera.
  }
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

Future<User?> getUserByFaceEmbedding(List<double> embedding) async {
  try {
    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('faceEmbedding', isEqualTo: embedding)
        .get();

    if (query.docs.isNotEmpty) {
      return User.fromFirestore(
          query.docs.first.data() as Map<String, dynamic>);
    } else {
      print("User not found");
      return null;
    }
  } catch (e) {
    print("Error retrieving user: $e");
    return null;
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
                      id: Random().nextInt(10),
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
  Future<void> saveUserToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .add(user.toFirestore());
      print("User saved successfully!");
    } catch (e) {
      print("Error saving user: $e");
    }
  }

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
                          id: Random().nextInt(10),
                        );

                        // Navigate to FaceScanPage with the user data
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
  String _overlaySvg = 'svgs/Camera_Frame.svg'; // Default overlay
  Timer? _scanTimer;
  Timer? _faceDetectionTimer;
  bool _faceDetected =
      false; // Flag to ensure only one image is captured per scan
  bool _scanSuccess = false; // Flag to track scan success
  bool _isDetecting = false; // Flag to track if detection is active

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

    _initializeControllerFuture = _controller.initialize().then((_) {
      // Start face detection automatically
      _startFaceDetection();
    });
  }

  @override
  void dispose() {
    _stopFaceDetection();
    _controller.dispose();
    _scanTimer?.cancel();
    _faceDetectionTimer?.cancel();
    super.dispose();
  }

  void _startFaceDetection() {
    if (_isDetecting) return; // Prevent multiple detection loops
    _isDetecting = true;

    _faceDetectionTimer =
        Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (!_isDetecting) {
        timer.cancel();
        return;
      }

      try {
        // Capture an image from the camera
        final image = await _controller.takePicture();
        final inputImage = InputImage.fromFilePath(image.path);

        // Detect faces in the image
        final List<Face> faces = await detectFaces(inputImage);
        print("Faces detected: ${faces.length}");

        if (faces.isNotEmpty) {
          if (!_faceDetected) {
            _faceDetected = true;
            setState(() {
              _overlaySvg = 'svgs/Camera_Frame_Face_Detected.svg';
            });

            // Start a timer to move to stage 2 after 1 second
            _scanTimer = Timer(const Duration(seconds: 1), () {
              if (_faceDetected) {
                _startScanning();
              }
            });
          }
        } else {
          _faceDetected = false;
          setState(() {
            _overlaySvg = 'svgs/Camera_Frame_Face_Not_Detected.svg';
          });
          _scanTimer?.cancel(); // Stop scanning if face is not detected
        }
      } catch (e) {
        print("Error during face detection: $e");
      }
    });
  }

  void _stopFaceDetection() {
    _isDetecting = false;
    _faceDetectionTimer?.cancel();
  }

  void _startScanning() async {
    setState(() {
      _stage = 2; // Move to scanning stage
    });

    // Capture the image
    try {
      final image = await _controller.takePicture();
      print("Image captured successfully.");

      // Save the image to a temporary directory
      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/temp_face';
      await Directory(tempPath).create(recursive: true);
      String filePath =
          '$tempPath/${widget.user.name}_${widget.user.surname}.jpg';
      File file = File(filePath);
      await file.writeAsBytes(await image.readAsBytes());

      // Upload image to Firebase Storage
      String downloadURL = await _uploadImageToStorage(file);

      // Store the download URL in Firestore as "faceEmbedding"
      if (widget.isNewUser) {
        FirestoreService firestoreService = FirestoreService();
        await firestoreService.saveFaceEmbedding(widget.user.id, downloadURL);
        print("Image URL sent to Firestore.");
      }

      // Proceed to the next stage
      _scanSuccess = true;
      _onScanComplete();
    } catch (e) {
      print("Error capturing image: $e");
      _scanSuccess = false;
      _onScanComplete();
    }
  }

  Future<String> _uploadImageToStorage(File file) async {
    try {
      // Create a reference to the location you want to upload to in Firebase Storage
      String fileName = '${widget.user.name}_${widget.user.surname}.jpg';
      Reference ref =
          FirebaseStorage.instance.ref().child('faceEmbedding/$fileName');

      // Upload the file to Firebase Storage
      await ref.putFile(file);

      // Get the download URL
      String downloadURL = await ref.getDownloadURL();
      print('Upload successful. Download URL: $downloadURL');
      return downloadURL;
    } catch (e) {
      print('Error occurred while uploading: $e');
      rethrow;
    }
  }

  void _onScanComplete() {
    setState(() {
      _stage = 3; // Move to completion stage
    });

    // Determine the outcome and update the overlay SVG and text
    if (_scanSuccess) {
      _overlaySvg = 'svgs/Camera_Frame_Face_Recognized.svg';
    } else {
      _overlaySvg = 'svgs/Camera_Frame_Face_Not_Recognized.svg';
    }

    // Proceed to the next page after a short delay
    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () {
      if (widget.isNewUser) {
        // Save the new user to the database
        FirestoreService firestoreService = FirestoreService();
        firestoreService.saveUserToFirestore(widget.user).then((_) async {
          Directory appDocDir = await getApplicationDocumentsDirectory();
          String filePath = '${appDocDir.path}/temp_image.jpg';

          deleteTempImage(filePath); // Pass the file path to deleteTempImage
          Navigator.push(
            context,
            _createRoute(UserCreationResultPage(
              isSuccess: _scanSuccess,
              camera: widget.camera,
            )),
          );
        }).catchError((error) {
          print("Error saving user: $error");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving user: $error")),
          );
        });
      } else {
        Navigator.push(
          context,
          _createRoute(
              UserProfilePage(user: widget.user, camera: widget.camera)),
        );
      }
    });
  }

  void deleteTempImage(String filePath) {
    final file = File(filePath);
    if (file.existsSync()) {
      file.deleteSync();
      print("Temporary image deleted: $filePath");
    }
  }

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
                                _overlaySvg,
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
                                : _scanSuccess
                                    ? 'Scan completed Successfully!'
                                    : 'Scan Failed',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _stage == 3 && !_scanSuccess
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
                              _startFaceDetection();
                            } else if (_stage == 3) {
                              if (widget.isNewUser) {
                                Navigator.push(
                                  context,
                                  _createRoute(UserCreationResultPage(
                                    isSuccess: _scanSuccess,
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

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      // Update the user object with new values
      widget.user.name = _nameController.text;
      widget.user.surname = _surnameController.text;
      widget.user.birthDate = _birthDateController.text;
      widget.user.placeOfStudy = _placeOfStudyController.text;
      widget.user.cityOfLiving = _cityOfLivingController.text;

      // Save updated user to Firestore
      FirestoreService firestoreService = FirestoreService();
      try {
        await firestoreService.updateUserInFirestore(widget.user);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Changes saved successfully")),
        );
      } catch (error) {
        print("Error updating user: $error");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving changes: $error")),
        );
      }
    }
  }

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
                  width: 160,
                  child: ElevatedButton.icon(
                    onPressed: _saveChanges,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Save Changes',
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
              const SizedBox(height: 16),
              Center(
                child: Container(
                  height: 48,
                  width: 160,
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

class FirestoreService {
  Future<void> saveUserToFirestore(User user) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .add(user.toFirestore());
      print("User saved successfully!");
    } catch (e) {
      print("Error saving user: $e");
      rethrow;
    }
  }

  Future<User?> getUserByFaceEmbedding(List<double> embedding) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('faceEmbedding', isEqualTo: embedding)
          .get();

      if (query.docs.isNotEmpty) {
        return User.fromFirestore(
            query.docs.first.data() as Map<String, dynamic>);
      } else {
        print("User not found");
        return null;
      }
    } catch (e) {
      print("Error retrieving user: $e");
      return null;
    }
  }

  Future<User?> getUserById(int id) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: id)
          .get();

      if (query.docs.isNotEmpty) {
        return User.fromFirestore(
            query.docs.first.data() as Map<String, dynamic>);
      } else {
        print("User not found");
        return null;
      }
    } catch (e) {
      print("Error retrieving user: $e");
      return null;
    }
  }

  Future<void> updateUserInFirestore(User user) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: user.id)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update(user.toFirestore());
        print("User updated successfully!");
      } else {
        print("User not found for update");
      }
    } catch (e) {
      print("Error updating user: $e");
      rethrow;
    }
  }

  Future<void> saveFaceEmbedding(int userId, String downloadURL) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: userId)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'faceEmbedding': downloadURL,
        });
        print("Face embedding URL saved successfully!");
      } else {
        print("User not found for saving face embedding");
      }
    } catch (e) {
      print("Error saving face embedding: $e");
      rethrow;
    }
  }
}
