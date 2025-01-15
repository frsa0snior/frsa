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
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;
import 'package:googleapis/vision/v1.dart' as vision;
import 'package:googleapis_auth/auth_io.dart';
import 'dart:convert';

Future<List<Face>> detectFaces(InputImage inputImage) async {
  print("Starting face detection...");
  final options = FaceDetectorOptions(
    enableContours: true,
    enableLandmarks: true,
  );

  final faceDetector = FaceDetector(options: options);
  final List<Face> faces = await faceDetector.processImage(inputImage);
  print("Face detection completed. Faces found: ${faces.length}");

  faceDetector.close();
  return faces;
}

Future<void> main() async {
  print("Initializing Flutter app...");
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Firebase initialized.");

  // Obtain a list of the available cameras on the device.
  final cameras = await availableCameras();
  print("Available cameras: ${cameras.length}");

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
    print("Front camera selected.");
    runApp(MyApp(camera: frontCamera));
  } else {
    print("No front camera found. Using default camera.");
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
        scaffoldBackgroundColor: Colors.white,
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
            overlayColor:
                WidgetStateProperty.all<Color>(Colors.blue.withOpacity(0.1)),
          ),
        ),
      ),
      home: MainPage(camera: camera),
    );
  }
}

Future<User?> getUserByFaceEmbedding(List<double> embedding) async {
  try {
    // Simplify the query by using a hash or a simplified version of the embedding
    // For example, you could store a hash of the embedding in Firestore
    String embeddingHash = embedding.join(',');

    QuerySnapshot query = await FirebaseFirestore.instance
        .collection('users')
        .where('embeddingHash', isEqualTo: embeddingHash)
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
                height: 36.0,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
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
                _buildCustomFormField(
                    'University Name', _placeOfStudyController),
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
                            id: 1000000 + Random().nextInt(9000000),
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
          firstDate: DateTime(1900),
          lastDate: DateTime.now(),
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
  FaceScanPageState createState() => FaceScanPageState();
}

class FaceScanPageState extends State<FaceScanPage> {
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
// Path to store the temporary face image

  @override
  void initState() {
    super.initState();
    print("Initializing camera...");
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
    );

    _initializeControllerFuture = _controller.initialize().then((_) {
      if (mounted) {
        setState(() {});
        print("Camera initialized.");
        _startFaceDetection();
      }
    });
  }

  @override
  void dispose() {
    // Make sure to dispose of the controller when leaving the page
    _stopFaceDetection();
    _controller.dispose();
    _scanTimer?.cancel();
    _faceDetectionTimer?.cancel();
    super.dispose();
  }

  void didChangeAppLifecycleState(AppLifecycleState state) {
    final CameraController cameraController = _controller;

    // App state changed before we got the chance to initialize.
    if (!cameraController.value.isInitialized) {
      return;
    }

    if (state == AppLifecycleState.inactive) {
      // Free up memory when camera not active
      cameraController.dispose();
    } else if (state == AppLifecycleState.resumed) {
      // Reinitialize the camera with same properties
      _initializeCamera();
    }
  }

  void _startFaceDetection() {
    if (_isDetecting) return; // Prevent multiple detection loops
    _isDetecting = true;
    print("Starting face detection loop...");

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

            // Stop the detection timer before starting the scan
            _faceDetectionTimer?.cancel();
            _isDetecting = false;

            // Start a timer to move to stage 2 after 1 second
            _scanTimer = Timer(const Duration(seconds: 1), () {
              if (_faceDetected) {
                print("Face detected. Starting scan...");
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

  Future<List<double>> getFaceEmbedding(String imagePath) async {
    try {
      // Load the model
      final interpreter = await Interpreter.fromAsset(
          'assets/Primary_Recognition_float32.tflite');

      // Read and process the image
      final imageData = File(imagePath).readAsBytesSync();
      final image = img.decodeImage(imageData);
      if (image == null) throw Exception('Failed to decode image');

      // Resize image to model input size (assuming 112x112)
      final processedImage = img.copyResize(image, width: 112, height: 112);

      // Convert image to float32 array and normalize
      var inputArray = Float32List(1 * 112 * 112 * 3);
      var pixelIndex = 0;
      for (var y = 0; y < processedImage.height; y++) {
        for (var x = 0; x < processedImage.width; x++) {
          var pixel = processedImage.getPixel(x, y);
          // Get RGB values directly from the pixel
          final r = pixel.r;
          final g = pixel.g;
          final b = pixel.b;

          // Normalize to [-0.5, 0.5] range
          inputArray[pixelIndex] = (r / 255.0) - 0.5; // Red
          inputArray[pixelIndex + 1] = (g / 255.0) - 0.5; // Green
          inputArray[pixelIndex + 2] = (b / 255.0) - 0.5; // Blue
          pixelIndex += 3;
        }
      }

      // Reshape input array
      var input = inputArray.reshape([1, 112, 112, 3]);

      // Prepare output array
      var output = List.filled(1 * 512, 0).reshape([1, 512]);

      // Run inference
      interpreter.run(input, output);

      // Convert output to list of doubles
      List<double> embedding = output[0].cast<double>();

      interpreter.close();
      return embedding;
    } catch (e) {
      print('Error getting face embedding: $e');
      rethrow;
    }
  }

  void _startScanning() async {
    setState(() {
      _stage = 2;
    });

    try {
      _stopFaceDetection();
      await Future.delayed(const Duration(milliseconds: 500));

      final XFile capturedImage = await _controller.takePicture();
      print("Step 1: Image captured successfully");

      Directory tempDir = await getTemporaryDirectory();
      String tempPath = '${tempDir.path}/temp_face';
      await Directory(tempPath).create(recursive: true);
      String tempFilePath =
          '$tempPath/${DateTime.now().millisecondsSinceEpoch}.jpg';
      File tempFile = File(tempFilePath);
      await tempFile.writeAsBytes(await capturedImage.readAsBytes());
      print("Step 2: Image saved to temporary folder: $tempFilePath");

      await _processScanResult(tempFile);
    } catch (e) {
      print("Error during scanning: $e");
      setState(() {
        _scanSuccess = false;
      });
      _onScanComplete();
    }
  }

  void _onScanComplete() {
    setState(() {
      _stage = 3;
      if (_scanSuccess) {
        _overlaySvg = 'svgs/Camera_Frame_Face_Recognized.svg';
        print("Scan completed successfully.");
      } else {
        _overlaySvg = 'svgs/Camera_Frame_Face_Not_Recognized.svg';
        print("Scan failed.");
      }
    });

    Future.delayed(const Duration(seconds: 1, milliseconds: 500), () async {
      if (widget.isNewUser) {
        Directory appDocDir = await getApplicationDocumentsDirectory();
        String filePath = '${appDocDir.path}/temp_image.jpg';
        deleteTempImage(filePath);

        Navigator.pushReplacement(
          context,
          _createRoute(UserCreationResultPage(
            isSuccess: _scanSuccess,
            camera: widget.camera,
          )),
        );
      } else {
        if (_scanSuccess) {
          Navigator.pushReplacement(
            context,
            _createRoute(
                UserProfilePage(user: widget.user, camera: widget.camera)),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Face not recognized. Please try again.')),
          );
          Navigator.pop(context);
        }
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

  double calculateEuclideanDistance(
      List<double> embedding1, List<double> embedding2) {
    if (embedding1.length != embedding2.length) {
      throw Exception('Embeddings must have same length');
    }

    double sumSquared = 0;
    for (int i = 0; i < embedding1.length; i++) {
      double diff = embedding1[i] - embedding2[i];
      sumSquared += diff * diff;
    }
    return sqrt(sumSquared);
  }

  Future<void> _processScanResult(File? tempFile) async {
    if (!widget.isNewUser) {
      // Existing login logic with Vision AI...
      try {
        print("\n=== Starting Vision AI Demo ===");
        final imageBytes = await tempFile!.readAsBytes();
        final base64Image = base64Encode(imageBytes);

        final apiClient =
            clientViaApiKey('AIzaSyCP0oSQd-5tqWBgdjz2Itvp4CQLRmU7q9w');
        final visionApi = vision.VisionApi(apiClient);

        final request = vision.BatchAnnotateImagesRequest(requests: [
          vision.AnnotateImageRequest(
            image: vision.Image(content: base64Image),
            features: [vision.Feature(type: 'FACE_DETECTION', maxResults: 1)],
          ),
        ]);

        final response = await visionApi.images.annotate(request);
        print("Vision AI response received");

        if (response.responses != null &&
            response.responses!.isNotEmpty &&
            response.responses!.first.faceAnnotations != null &&
            response.responses!.first.faceAnnotations!.isNotEmpty) {
          FirestoreService firestoreService = FirestoreService();
          User? mostRecentUser = await firestoreService.getMostRecentUser();

          if (mostRecentUser != null) {
            setState(() {
              _scanSuccess = true;
              widget.user.name = mostRecentUser.name;
              widget.user.surname = mostRecentUser.surname;
              widget.user.birthDate = mostRecentUser.birthDate;
              widget.user.placeOfStudy = mostRecentUser.placeOfStudy;
              widget.user.cityOfLiving = mostRecentUser.cityOfLiving;
              widget.user.id = mostRecentUser.id;
              widget.user.imageUrl = mostRecentUser.imageUrl;
            });
          } else {
            setState(() {
              _scanSuccess = false;
            });
          }
        }
        apiClient.close();
      } catch (e) {
        print("Error in face comparison: $e");
        setState(() {
          _scanSuccess = false;
        });
      }
    } else {
      // New user creation logic - simplified without Vision AI
      if (tempFile == null || !tempFile.existsSync()) {
        print("Error: No image file available");
        setState(() {
          _scanSuccess = false;
        });
        _onScanComplete();
        return;
      }

      try {
        print("Starting user creation process...");

        // Create a new user with the input data
        FirestoreService firestoreService = FirestoreService();

        // Save user data and image
        await firestoreService.saveUserToFirestore(widget.user, tempFile.path);
        print("User data and image saved successfully!");

        setState(() {
          _scanSuccess = true;
        });
      } catch (e) {
        print("Error creating new user: $e");
        setState(() {
          _scanSuccess = false;
        });
      }
    }
    _onScanComplete();
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
  UserProfilePageState createState() => UserProfilePageState();
}

class UserProfilePageState extends State<UserProfilePage> {
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
                  width: 1000,
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

class FirestoreService {
  Future<void> saveUserToFirestore(User user, String imagePath) async {
    try {
      print("Starting user creation in Firestore...");

      // 1. Upload image to Cloud Storage
      final String fileName = '${user.id}_face.jpg';
      final storageRef =
          FirebaseStorage.instance.ref().child('faceEmbedding').child(fileName);

      // Upload the file
      await storageRef.putFile(File(imagePath));
      print("Image uploaded to Storage");

      // Get the download URL
      final String downloadURL = await storageRef.getDownloadURL();
      print("Image URL retrieved: $downloadURL");

      // 2. Save user data to Firestore
      user.imageUrl = downloadURL;
      await FirebaseFirestore.instance
          .collection('users')
          .add(user.toFirestore());

      print("User created successfully in Firestore!");
    } catch (e) {
      print("Error creating user: $e");
      rethrow;
    }
  }

  Future<User?> getUserByFaceEmbedding(List<double> embedding) async {
    try {
      // Simplify the query by using a hash or a simplified version of the embedding
      // For example, you could store a hash of the embedding in Firestore
      String embeddingHash = embedding.join(',');

      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('embeddingHash', isEqualTo: embeddingHash)
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
        // Create a new user document without an image
        await FirebaseFirestore.instance
            .collection('users')
            .add(user.toFirestore());
        print("New user created without image");
      }
    } catch (e) {
      print("Error updating user: $e");
      rethrow;
    }
  }

  Future<void> saveFaceEmbedding(int userId, List<double> embedding) async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .where('id', isEqualTo: userId)
          .get();

      if (query.docs.isNotEmpty) {
        await query.docs.first.reference.update({
          'faceEmbedding': embedding,
        });
        print("Face embedding saved successfully!");
      } else {
        print("User not found for saving face embedding. Creating new user...");
        // Create a new user if not found
        User newUser = User(
          id: userId,
          name: "New User",
          surname: "Surname",
          birthDate: "01/01/2000",
          placeOfStudy: "University",
          cityOfLiving: "City",
          imageUrl: "",
        );
        // Create user document without image first
        await FirebaseFirestore.instance
            .collection('users')
            .add(newUser.toFirestore());
        await saveFaceEmbedding(userId, embedding); // Retry saving embedding
      }
    } catch (e) {
      print("Error saving face embedding: $e");
      rethrow;
    }
  }

  Future<User?> getMostRecentUser() async {
    try {
      QuerySnapshot query = await FirebaseFirestore.instance
          .collection('users')
          .orderBy('id', descending: true)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        return User.fromFirestore(
            query.docs.first.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print("Error retrieving most recent user: $e");
      return null;
    }
  }
}

List<double> generateFaceEmbedding(String imagePath) {
  // Simulate the generation of face embeddings
  // In a real scenario, you would use a model to generate these
  final random = Random();
  return List<double>.generate(512, (_) => random.nextDouble());
}
