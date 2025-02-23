import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService{
  //Firebase Authentication Instance
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //FireStore Instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //function to handle user Signup

  Future <String?> signup ({
    required String email,
    required String name,
    required String password,
    required String role,
  })async{
    try{
      //Create a user in Firebase Authentication with email and Password
      UserCredential userCredential= await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
       password: password.trim(),
      );
      //Save Additional UserData in firestore (name,role,email)
      await _firestore
      .collection("users")
      .doc(userCredential.user!.uid)
      .set({
          'name':name.trim(),
          'email':email.trim(),
          "role":role,
      });
      return null;//success: No error message!
    }catch(e){
      return e.toString();
    }
  }

  //function to handle user Login
  Future <String?> login ({
    required String email,
    required String password,
  })async{
    try{
      //Sign in user using Firebase Authentication with email and Password
      UserCredential userCredential= await _auth.signInWithEmailAndPassword(
        email: email.trim(),
       password: password.trim(),
      );
      //fetching the user's role from firestore to determine access level
      DocumentSnapshot userDoc= await _firestore
      .collection("users")
      .doc(userCredential.user!.uid)
      .get();
      
      return userDoc['role'];//return the user's role(admin/user)
    }catch(e){
      return e.toString();
    }
  }
  
  //for resetting password in case of Forgot Password
  Future<String?> resetPassword({required String email}) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    return "Password reset email sent";
  } on FirebaseAuthException catch (e) {
    return e.message;
  } catch (e) {
    return e.toString();
  }
}

  //For retrieving UserId
  Future<String?> getCurrentUserId() async {
    try {
      final User? user = _auth.currentUser;
      return user?.uid;
    } catch (e) {
      print("Error getting user ID: $e");
      return null;
    }
  }
  //for User LogOut
  signOut() async{
    _auth.signOut();
  }
}