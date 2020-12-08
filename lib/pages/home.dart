import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:socialmedia/models/user.dart';
import 'package:socialmedia/pages/activity_feed.dart';
import 'package:socialmedia/pages/create_account.dart';
import 'package:socialmedia/pages/profile.dart';
import 'package:socialmedia/pages/search.dart';
import 'package:socialmedia/pages/timeline.dart';
import 'package:socialmedia/pages/upload.dart';

final GoogleSignIn googlesingin = GoogleSignIn();
final userRef = FirebaseFirestore.instance.collection('users');
final postsRef = FirebaseFirestore.instance.collection('posts');
final Reference storageRef = FirebaseStorage.instance.ref();
final commentsRef = FirebaseFirestore.instance.collection('comments');
final activityFeedRef = FirebaseFirestore.instance.collection('feed');
final followersRef = FirebaseFirestore.instance.collection('followers');
final followingRef = FirebaseFirestore.instance.collection('following');
final timelineRef = FirebaseFirestore.instance.collection('timeline');

final DateTime timestamp = DateTime.now();
User currentUser;

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool isAuth = false;
  PageController pageController;
  int pageindex = 0;
  @override
  initState() {
    super.initState();
    pageController = PageController();
    googlesingin.onCurrentUserChanged.listen((account) {
      handleSigin(account);
    }, onError: (err) {
      // ignore: unnecessary_brace_in_string_interps
      print("Error Sign In:${err}");
    });
    googlesingin.signInSilently(suppressErrors: false).then((account) {
      handleSigin(account);
    }).catchError((err) {
      // ignore: unnecessary_brace_in_string_interps
      print("Error Sign In:${err}");
    });
  }

  handleSigin(GoogleSignInAccount account) {
    if (account != null) {
      // ignore: unnecessary_brace_in_string_interps
      // print("User Signed in!:${account}");
      createUserinFirestore();
      setState(() {
        isAuth = true;
      });
    } else {
      setState(() {
        isAuth = false;
      });
    }
  }

  createUserinFirestore() async {
    // checking if user collection is already available or not according to their id
    final GoogleSignInAccount user = googlesingin.currentUser;
    DocumentSnapshot doc = await userRef.doc(user.id).get();
    if (!doc.exists) {
      // if the user is not exits simple navigate to the next form
      final username = await Navigator.push(
          context, MaterialPageRoute(builder: (context) => CreateAccount()));
      userRef.doc(user.id).set({
        "id": user.id,
        "username": username,
        "photoUrl": user.photoUrl,
        "email": user.email,
        "displayName": user.displayName,
        "bio": "",
        "timestamp": timestamp
      });
      doc = await userRef.doc(user.id).get();
    }
    currentUser = User.fromdocument(doc);
    print(currentUser);
    print(currentUser.username);
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  login() {
    googlesingin.signIn();
  }

  logout() {
    googlesingin.signOut();
  }

  onPagechnaged(int pageindex) {
    setState(() {
      this.pageindex = pageindex;
    });
  }

  onTap(int pageindex) {
    pageController.animateToPage(pageindex,
        duration: Duration(milliseconds: 200), curve: Curves.easeInOut);
  }

  Scaffold buildAuthscreen() {
    return Scaffold(
      body: PageView(
        children: <Widget>[
          Timeline(currentUser: currentUser),
          ActivityFeed(),
          Upload(currentUser: currentUser),
          Search(),
          Profile(profileId: currentUser?.id)
        ],
        controller: pageController,
        onPageChanged: onPagechnaged,
        physics: NeverScrollableScrollPhysics(),
      ),
      bottomNavigationBar: CupertinoTabBar(
        currentIndex: pageindex,
        onTap: onTap,
        activeColor: Theme.of(context).primaryColor,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.whatshot)),
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active)),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.photo_camera,
              size: 35.0,
            ),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search),
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
          )
        ],
      ),
    );
    // return RaisedButton(child: Text("Logout"),onPressed: logout);
  }

  Scaffold buildUnAuthScreen() {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
              colors: [
                Theme.of(context).accentColor,
                Theme.of(context).primaryColor
              ]),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              "Flutter App",
              style: TextStyle(
                  fontFamily: "Signatra", fontSize: 90.0, color: Colors.white),
            ),
            GestureDetector(
              onTap: login,
              child: Container(
                width: 260.0,
                height: 60.0,
                decoration: BoxDecoration(
                    image: DecorationImage(
                        image: AssetImage(
                          "assets/images/google_signin_button.png",
                        ),
                        fit: BoxFit.cover)),
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return isAuth ? buildAuthscreen() : buildUnAuthScreen();
  }
}
