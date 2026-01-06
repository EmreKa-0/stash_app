import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // --- Normal Login ---
  Future<String?> loginUser({required String email, required String password}) async {
    try {
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return null; // No error, login successful
    } on FirebaseAuthException catch (e) {
      return e.message ?? "An error occurred.";
    } catch (e) {
      return "Login failed: $e";
    }
  }

  // --- Google Sign-In ---
  Future<String?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return "Google sign-in canceled.";

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } catch (e) {
      return "Google sign-in failed: $e";
    }
  }

  // --- Fetch User Data ---
  Future<Map<String, dynamic>?> getUserData() async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return doc.data() as Map<String, dynamic>;
      }
    }
    return null;
  }

  // --- Visitor Registration ---
  Future<String?> registerVisitor({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    required String phone,
    required String idOrPassport,
    required String gender,
    required int age,
  }) async {
    try {
      // 1. Create Firebase Auth User
      UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Save to Firestore
      String uid = userCredential.user!.uid;
      
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'userType': 'visitor', // User type visitor
        'name': '$firstName $lastName', // Full name
        'firstName': firstName,
        'lastName': lastName,
        'email': email,
        'phone': phone,
        'idOrPassport': idOrPassport,
        'gender': gender,
        'age': age,
        'createdAt': FieldValue.serverTimestamp(),
      });

      return null; // Successful
    } on FirebaseAuthException catch (e) {
      return e.message ?? "Registration failed.";
    } catch (e) {
      return "An error occurred: $e";
    }
  }
}