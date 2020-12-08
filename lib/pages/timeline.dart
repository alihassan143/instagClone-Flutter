import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

import 'package:socialmedia/models/user.dart';
import 'package:socialmedia/pages/home.dart';
import 'package:socialmedia/widgets/header.dart';
import 'package:socialmedia/widgets/post.dart';
import 'package:socialmedia/widgets/progress.dart';

final userref = FirebaseFirestore.instance.collection("users");

class Timeline extends StatefulWidget {
  final User currentUser;
  const Timeline({
    this.currentUser,
  });

  @override
  _TimelineState createState() => _TimelineState();
}

class _TimelineState extends State<Timeline> {
  List<Post> posts;
  @override
  void initState() {
    // ignore: todo
    // TODO: implement initState
    super.initState();
    getTimeLine();
  }

  getTimeLine() async {
    QuerySnapshot snapshot = await timelineRef
        .doc(widget.currentUser.id)
        .collection('timelinePosts')
        .orderBy('timestamp', descending: true)
        .get();
    List<Post> posts =
        snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    setState(() {
      this.posts = posts;
    });
  }

  // @override
  // void initState() {
  //   getUser();
  //   // ignore: todo
  // ignore: todo
  //   // TODO: implement initState
  //   super.initState();
  // }

  // getUser() {
  //   // final QuerySnapshot snapshot = await userref
  //   //     .where("postcount", isLessThan: 2)
  //   //     .where('username', isEqualTo: "Ali")
  //   //     .get();
  //   // snapshot.docs.forEach((DocumentSnapshot snapshot) {
  //   //   // Map<String, dynamic> data = snapshot.data();
  //   //   print(snapshot.data.t);
  //   // });
  //   userref.get().then((QuerySnapshot value) {
  //     value.docs.forEach((DocumentSnapshot doc) {
  //       Map<String, dynamic> data = doc.data();
  //       print(data);
  //     });
  //   });
  // }
  buildTimeLine() {
    if (posts == null) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Center(
        child: Container(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                "assets/images/no_content.svg",
                height: 150,
              ),
              Padding(
                padding: EdgeInsets.only(top: 20.0),
                child: Text(
                  "No posts",
                  style: TextStyle(
                      color: Colors.redAccent,
                      fontSize: 40,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return ListView(
        children: posts,
      );
    }
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: header(context, isApptitle: true),
      body: RefreshIndicator(
        onRefresh: () => getTimeLine(),
        child: buildTimeLine(),
      ),
    );
  }
}
