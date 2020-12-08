import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import "package:flutter/material.dart";
import 'package:socialmedia/models/user.dart';
import 'package:socialmedia/pages/home.dart';
import 'package:socialmedia/widgets/progress.dart';

class EditProfile extends StatefulWidget {
  final String currentUserId;
  EditProfile({this.currentUserId});
  @override
  _EditProfileState createState() => _EditProfileState();
}

class _EditProfileState extends State<EditProfile> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController displayNameController = TextEditingController();
  TextEditingController bioController = TextEditingController();
  bool isLoading = false;
  User user;
  bool _displaynameValid = true;
  bool _bioValid = true;

  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    super.initState();
    getUser();
  }

  getUser() async {
    setState(() {
      isLoading = true;
    });
    DocumentSnapshot documentSnapshot =
        await userRef.doc(widget.currentUserId).get();
    user = User.fromdocument(documentSnapshot);
    displayNameController.text = user.displayName;
    bioController.text = user.bio;
    setState(() {
      isLoading = false;
    });
  }

  logout() async {
    await googlesingin.signOut();
    Navigator.push(context, MaterialPageRoute(builder: (context) => Home()));
  }

  Column buildDisplayNameField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Display Name",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: displayNameController,
          decoration: InputDecoration(
              hintText: "Update Display Name",
              errorText:
                  _displaynameValid ? null : "Display Name is Too Short"),
        )
      ],
    );
  }

  buildbioField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: EdgeInsets.only(top: 12.0),
          child: Text(
            "Bio",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        TextField(
          controller: bioController,
          decoration: InputDecoration(
              hintText: "Update Your Bio",
              errorText: _bioValid ? null : "Enter the Valid Bio"),
        )
      ],
    );
  }

  updateProfileData() {
    setState(() {
      displayNameController.text.trim().length < 3 ||
              displayNameController.text.isEmpty
          ? _displaynameValid = false
          : _displaynameValid = true;
      bioController.text.trim().length > 100
          ? _bioValid = false
          : _bioValid = true;
    });
    if (_displaynameValid && _bioValid) {
      userRef.doc(widget.currentUserId).update({
        "displayName": displayNameController.text,
        "bio": bioController.text,
      });
      SnackBar snackBar = SnackBar(content: Text("Profle Updated"));
      _scaffoldKey.currentState.showSnackBar(snackBar);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: Text(
          'Edit Profile',
          style: TextStyle(
            color: Colors.black,
          ),
        ),
        actions: <Widget>[
          IconButton(
              icon: Icon(
                Icons.done,
                size: 30.0,
                color: Colors.green,
              ),
              onPressed: () => Navigator.pop(context))
        ],
      ),
      body: isLoading
          ? circularProgress()
          : ListView(
              children: <Widget>[
                Container(
                  child: Column(
                    children: <Widget>[
                      Padding(
                        child: CircleAvatar(
                          backgroundImage: CachedNetworkImageProvider(
                            user.photoUrl,
                          ),
                          radius: 50.0,
                        ),
                        padding: EdgeInsets.only(
                          top: 16,
                          bottom: 8,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          children: <Widget>[
                            buildDisplayNameField(),
                            buildbioField()
                          ],
                        ),
                      ),
                      RaisedButton(
                        onPressed: updateProfileData,
                        child: Text(
                          'Update Profile',
                          style: TextStyle(
                              color: Theme.of(context).primaryColor,
                              fontSize: 20.0,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(16),
                        child: FlatButton.icon(
                            onPressed:  logout,
                            icon: Icon(
                              Icons.cancel,
                              color: Colors.red,
                            ),
                            label: Text('Logout',
                                style: TextStyle(
                                    color: Colors.red, fontSize: 20.0))),
                      )
                    ],
                  ),
                )
              ],
            ),
    );
  }
}
