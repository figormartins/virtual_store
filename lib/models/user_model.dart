import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:scoped_model/scoped_model.dart';

class UserModel extends Model {
  FirebaseAuth _auth = FirebaseAuth.instance;
  UserCredential firebaseUser;
  User user;
  Map<String, dynamic> userData = Map();

  bool isLoading = false;

  @override void addListener(listener) {
    super.addListener(listener);

    _loadCurrentUser();
  }

  void signUp(
      {@required Map<String, dynamic> userData,
      @required String pass,
      @required VoidCallback onSucess,
      @required VoidCallback onFail}) {
    isLoading = true;
    notifyListeners();

    _auth.createUserWithEmailAndPassword(
      email: userData["email"],
      password: pass
    ).then((userCredential) async {
      firebaseUser = userCredential;
      await _saveUserData(userData);

      onSucess();
    }).catchError((error) {
      onFail();
    });

    isLoading = false;
    notifyListeners();
  }

  void signIn({@required String email,
      @required String pass,
      @required VoidCallback onSucess,
      @required VoidCallback onFail}) async {
    isLoading = true;
    notifyListeners();
    
    await _auth.signInWithEmailAndPassword(email: email, password: pass)
      .then((userCredential) async {
        firebaseUser = userCredential;
        await _loadCurrentUser();
        onSucess();
      }).catchError((e) {
        onFail();
      });

    isLoading = false;
    notifyListeners();
  }

  bool isLoggedIn() {
    return user != null;
  }

  void signOut() async {
    await _auth.signOut();

    userData = Map();
    firebaseUser = null;
    user = null;
    notifyListeners();
  }

  void recoverPass(String email) {
    _auth.sendPasswordResetEmail(email: email);
  }

  Future<Null> _saveUserData(Map<String, dynamic> userData) async {
    this.userData = userData;

    await FirebaseFirestore.instance
      .collection("users")
      .doc(_auth.currentUser.uid)
      .set(userData);
  }

  Future<Null> _loadCurrentUser() async {
    if (user == null)
      user = _auth.currentUser;

    if (userData == null || userData.isEmpty) {
      var user = await FirebaseFirestore.instance
      .collection("users")
      .get();
      
      userData = user.docs.first.data();
    }

    notifyListeners();
  }
}
