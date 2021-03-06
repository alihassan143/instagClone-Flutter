import 'package:flutter/material.dart';
import 'package:socialmedia/pages/home.dart';
import 'package:socialmedia/widgets/header.dart';
import 'package:socialmedia/widgets/post.dart';
import 'package:socialmedia/widgets/progress.dart';

class PostScreen extends StatelessWidget {
  final String userId;
  final String postId;
  const PostScreen({
    this.userId,
    this.postId,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: postsRef.doc(userId).collection('usersPosts').doc(postId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        Post post = Post.fromDocument(snapshot.data);
        return Center(
          child: Scaffold(
            appBar: header(context,texttitle: post.description),
            body: ListView(
              children: <Widget>[
                Container(
                  child: post,
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
