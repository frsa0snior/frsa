// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/user.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<User?> getUserByFaceEmbedding(List<double> embedding) async {
    try {
      QuerySnapshot query = await _firestore
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
}
