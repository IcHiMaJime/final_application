import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // FIX: Idinagdag ito para makuha ang UID ng user
  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<String> getCurrentUsername() async {
    try {
      User? user = _auth.currentUser;
      if (user != null) {
        DocumentSnapshot doc = await _firestore.collection('users').doc(user.uid).get();
        return doc['username'] ?? "Artist";
      }
      return "Guest";
    } catch (e) {
      return "Artist";
    }
  }

  Future<bool> isUsernameTaken(String username) async {
    final query = await _firestore.collection('users').where('username', isEqualTo: username).get();
    return query.docs.isNotEmpty;
  }

  Future<User?> register(String email, String password, String username) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      User? user = result.user;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'username': username,
          'email': email,
          'createdAt': DateTime.now(),
        });
      }
      return user;
    } catch (e) { throw e.toString(); }
  }

  Future<User?> loginWithUsername(String username, String password) async {
    try {
      var userQuery = await _firestore.collection('users').where('username', isEqualTo: username).limit(1).get();
      if (userQuery.docs.isEmpty) throw 'Username not found.';
      String email = userQuery.docs.first.get('email');
      UserCredential result = await _auth.signInWithEmailAndPassword(email: email, password: password);
      return result.user;
    } catch (e) { throw e.toString(); }
  }

  Future<void> signOut() async => await _auth.signOut();
}