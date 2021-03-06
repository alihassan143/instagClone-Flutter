import 'dart:async';

import 'package:animator/animator.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:socialmedia/models/user.dart';
import 'package:socialmedia/pages/activity_feed.dart';
import 'package:socialmedia/pages/comments.dart';
import 'package:socialmedia/pages/home.dart';
import 'package:socialmedia/widgets/custom_image.dart';
import 'package:socialmedia/widgets/progress.dart';

class Post extends StatefulWidget {
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  final dynamic likes;
  Post({
    this.postId,
    this.ownerId,
    this.username,
    this.location,
    this.description,
    this.mediaUrl,
    this.likes,
  });
  factory Post.fromDocument(DocumentSnapshot doc) {
    return Post(
      postId: doc['postId'],
      ownerId: doc['ownerId'],
      username: doc['username'],
      location: doc['location'],
      description: doc['description'],
      mediaUrl: doc['mediaUrl'],
      likes: doc['likes'],
    );
  }
  int getLikesCount(like) {
    if (likes == null) {
      return 0;
    }
    int count = 0;
    likes.values.forEach((val) {
      if (val == true) {
        count += 1;
      }
    });
    return count;
  }

  @override
  _PostState createState() => _PostState(
        postId: this.postId,
        ownerId: this.ownerId,
        username: this.username,
        location: this.location,
        description: this.description,
        mediaUrl: this.mediaUrl,
        likes: this.likes,
        likeCount: getLikesCount(this.likes),
      );
}

class _PostState extends State<Post> {
  final String currentuserId = currentUser?.id;
  final String postId;
  final String ownerId;
  final String username;
  final String location;
  final String description;
  final String mediaUrl;
  bool isLiked;
  bool showlikedonpicture = false;
  int likeCount;
  Map likes;

  _PostState(
      {this.postId,
      this.ownerId,
      this.username,
      this.location,
      this.description,
      this.mediaUrl,
      this.likes,
      this.likeCount});
  buildPostHeader() {
    return FutureBuilder(
      future: userRef.doc(ownerId).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return circularProgress();
        }
        User user = User.fromdocument(snapshot.data);
        bool isPostOwner = currentuserId == ownerId;
        return ListTile(
          leading: CircleAvatar(
            backgroundImage: CachedNetworkImageProvider(user.photoUrl),
            backgroundColor: Colors.grey,
          ),
          title: GestureDetector(
            onTap: () => showProfile(context, profileId: user.id),
            child: Text(
              user.username,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          subtitle: Text(location),
          trailing: isPostOwner
              ? IconButton(
                  onPressed: () => handleDeletePost(context),
                  icon: Icon(Icons.more_vert),
                )
              : Text(''),
        );
      },
    );
  }

  handleDeletePost(BuildContext parentContext) {
    return showDialog(
        context: parentContext,
        builder: (context) {
          return SimpleDialog(
            title: Text("Remove This Post"),
            children: <Widget>[
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context);
                  deletePost();
                },
                child: Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cencel',
                ),
              ),
            ],
          );
        });
  }

  deletePost() async {
    postsRef
        .doc(ownerId)
        .collection("usersPosts")
        .doc(postId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
    storageRef.child("post_$postId.jpg").delete();
    QuerySnapshot activityfeedSnapshot = await activityFeedRef
        .doc(ownerId)
        .collection('feedItems')
        .where('postId', isEqualTo: postId)
        .get();
    activityfeedSnapshot.docs.forEach((element) {
      if (element.exists) {
        element.reference.delete();
      }
    });
   QuerySnapshot commentSnapshot= await commentsRef.doc(postId).collection('comments').get();
     commentSnapshot.docs.forEach((element) {
      if (element.exists) {
        element.reference.delete();
      }
    });
  }

  handleLikeButton() {
    bool _isLiked = likes[currentuserId] == true;
    if (_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('usersPosts')
          .doc(postId)
          .update({'likes.$currentuserId': false});
      setState(() {
        likeCount -= 1;
        isLiked = false;
        likes[currentuserId] = false;
        removeLikefromActivityFeed();
      });
    } else if (!_isLiked) {
      postsRef
          .doc(ownerId)
          .collection('usersPosts')
          .doc(postId)
          .update({'likes.$currentuserId': false});
      setState(() {
        likeCount += 1;
        isLiked = true;
        likes[currentuserId] = true;
        showlikedonpicture = true;
        addLiketoActivityFeed();
      });
      Timer(Duration(milliseconds: 500), () {
        setState(() {
          showlikedonpicture = false;
        });
      });
    }
  }

  removeLikefromActivityFeed() {
    bool isnotPostOwner = currentuserId != ownerId;
    if (isnotPostOwner) {
      activityFeedRef
          .doc(ownerId)
          .collection('feedItems')
          .doc(postId)
          .get()
          .then((value) {
        if (value.exists) {
          value.reference.delete();
        }
      });
    }
  }

  addLiketoActivityFeed() {
    bool isnotPostOwner = currentuserId != ownerId;
    if (isnotPostOwner) {
      activityFeedRef.doc(ownerId).collection('feedItems').doc(postId).set({
        'type': 'like',
        'username': currentUser.username,
        'userId': currentUser.id,
        'userProfileImage': currentUser.photoUrl,
        "postId": postId,
        'mediaUrl': mediaUrl,
        'timestamp': timestamp
      });
    }
  }

  buildPostImage() {
    return GestureDetector(
      onDoubleTap: handleLikeButton,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          cachedNetworkImage(mediaUrl),
          showlikedonpicture
              ? Animator(
                  duration: Duration(milliseconds: 300),
                  tween: Tween(begin: 0.7, end: 1.7),
                  curve: Curves.easeOutQuint,
                  cycles: 0,
                  builder: ((BuildContext context, AnimatorState<double> anim,
                          Widget widget) =>
                      Transform.scale(
                          scale: anim.value,
                          child: Icon(
                            Icons.favorite,
                            size: 80.0,
                            color: Colors.red,
                          ))))
              : Text('')
          // showlikedonpicture? Icon(
          //   Icons.favorite,
          //   size: 80.0,
          //   color: Colors.red,
          //   ):Text('')
        ],
      ),
    );
  }

  buildPostFooter() {
    return Column(
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Padding(padding: EdgeInsets.only(top: 40.0, left: 20.0)),
            GestureDetector(
              onTap: handleLikeButton,
              child: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                size: 28.0,
                color: Colors.pink,
              ),
            ),
            Padding(padding: EdgeInsets.only(right: 20.0)),
            GestureDetector(
              onTap: () => showComments(context,
                  postId: postId, ownerId: ownerId, mediaUrl: mediaUrl),
              child: Icon(
                Icons.message,
                size: 28.0,
                color: Colors.blue[900],
              ),
            ),
          ],
        ),
        Row(
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$likeCount likes ",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          ],
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Container(
              margin: EdgeInsets.only(left: 20.0),
              child: Text(
                "$username",
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Expanded(child: Text(description))
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    isLiked = (likes[currentuserId] == true);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        buildPostHeader(),
        buildPostImage(),
        buildPostFooter(),
      ],
    );
  }

  showComments(BuildContext context,
      {String postId, String ownerId, String mediaUrl}) {
    return Navigator.push(context, MaterialPageRoute(builder: (context) {
      return Comments(
          postId: postId, postOwnerId: ownerId, postMediaUrl: mediaUrl);
    }));
  }
}
