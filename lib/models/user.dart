// import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String id;
  final String username;
  final String photoUrl;
  final String email;
  final String displayName;
  final String bio;
  User(
      {this.id,
      this.username,
      this.email,
      this.displayName,
      this.photoUrl,
      this.bio});
  factory User.fromdocument(DocumentSnapshot doc) {
    return User(
      id: doc['id'],
      username: doc['username'],
      photoUrl: doc['photoUrl'],
      email: doc['email'],
      displayName: doc['displayName'],
      bio: doc['bio']
    );
  }
}
