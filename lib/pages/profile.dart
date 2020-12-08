 

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:socialmedia/models/user.dart';
import 'package:socialmedia/pages/edit_profile.dart';
import 'package:socialmedia/widgets/header.dart';
import 'package:socialmedia/pages/home.dart';
import 'package:socialmedia/widgets/post.dart';
import 'package:socialmedia/widgets/post_tile.dart';
import 'package:socialmedia/widgets/progress.dart';

class Profile extends StatefulWidget {
  final String profileId;
  Profile({this.profileId});
  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  bool isFollowing = false;
  final String currentUserId = currentUser?.id;
  String postOrientation = 'grid';
  bool isLoading = false;
  int postCount = 0;
  int followersCount = 0;
  int followingCount = 0;
  List<Post> posts = [];
  @override
  void initState() {
    super.initState();
    getProfilePost();
    getFollower();
    getFollowing();
    checkFollowing();
  }
    getFollowing()async{
       QuerySnapshot querySnapshot = await followingRef
        .doc(widget.profileId)
        .collection('usersFollowing')
        .get();
    setState(() {
      followingCount = querySnapshot.docs.length;
    });
    }

  getFollower() async {
    QuerySnapshot querySnapshot = await followersRef
        .doc(widget.profileId)
        .collection('usersFollowers')
        .get();
    setState(() {
      followersCount = querySnapshot.docs.length;
    });
  }

  checkFollowing() async {
    DocumentSnapshot snapshot = await followersRef
        .doc(widget.profileId)
        .collection('usersFollowers')
        .doc(currentUserId)
        .get();
    setState(() {
      isFollowing = snapshot.exists;
    });
  }

  getProfilePost() async {
    setState(() {
      isLoading = true;
    });
    QuerySnapshot snapshot = await postsRef
        .doc(widget.profileId)
        .collection('usersPosts')
        .orderBy('timestamp', descending: true)
        .get();
    setState(() {
      isLoading = false;
      postCount = snapshot.docs.length;
      posts = snapshot.docs.map((doc) => Post.fromDocument(doc)).toList();
    });
  }

  Container buildButton({String text, Function function}) {
    return Container(
      padding: EdgeInsets.only(top: 2.0),
      child: FlatButton(
        onPressed: function,
        child: Container(
          width: 200,
          height: 27,
          child: Text(
            text,
            style: TextStyle(
                color: isFollowing ? Colors.black : Colors.white,
                fontWeight: FontWeight.bold),
          ),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isFollowing ? Colors.white : Colors.blue,
            border: Border.all(
              color: isFollowing ? Colors.grey : Colors.blue,
            ),
            borderRadius: BorderRadius.circular(5.0),
          ),
        ),
      ),
    );
  }

  editProfile() {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => EditProfile(currentUserId: currentUserId)));
  }

  buildprofileButton() {
    bool isprofileOwner = currentUserId == widget.profileId;
    if (isprofileOwner) {
      return buildButton(text: "EditProfile", function: editProfile);
    } else if (isFollowing) {
      return buildButton(text: "Unfollow", function: handleUnfollowUser);
    } else if (!isFollowing) {
      return buildButton(text: "Follow", function: handleFollowUser);
    }
  }

  handleFollowUser() {
    setState(() {
      isFollowing = true;
    });
    followersRef
        .doc(widget.profileId)
        .collection('usersFollowers')
        .doc(currentUserId)
        .set({});
    followingRef
        .doc(currentUserId)
        .collection('usersFollowing')
        .doc(widget.profileId)
        .set({});
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .set({
      'type': 'follow',
      'ownerId': widget.profileId,
      'username': currentUser.username,
      'userId': currentUserId,
      'userProfileImage': currentUser.photoUrl,
      'timestamp': timestamp,
    });
  }

  handleUnfollowUser() {
    setState(() {
      isFollowing = false;
    });
    followersRef
        .doc(widget.profileId)
        .collection('usersFollowers')
        .doc(currentUserId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
    followingRef
        .doc(currentUserId)
        .collection('usersFollowing')
        .doc(widget.profileId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
    
    activityFeedRef
        .doc(widget.profileId)
        .collection('feedItems')
        .doc(currentUserId)
        .get()
        .then((value) {
      if (value.exists) {
        value.reference.delete();
      }
    });
  }

  Column buildCountColumn(String label, int count) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Text(
          count.toString(),
          style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold),
        ),
        Container(
          margin: EdgeInsets.only(top: 4.0),
          child: Text(
            label,
            style: TextStyle(
                color: Colors.grey,
                fontSize: 15.0,
                fontWeight: FontWeight.w400),
          ),
        )
      ],
    );
  }

  buildProfilePost() {
    if (isLoading) {
      return circularProgress();
    } else if (posts.isEmpty) {
      return Container(
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
      );
    } else if (postOrientation == 'grid') {
      List<GridTile> gridTiles = [];
      posts.forEach((post) {
        gridTiles.add(GridTile(
            child: PostTile(
          post: post,
        )));
      });
      return GridView.count(
        crossAxisCount: 3,
        childAspectRatio: 1.0,
        mainAxisSpacing: 1.5,
        crossAxisSpacing: 1.5,
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        children: gridTiles,
      );
    } else if (postOrientation == 'list') {
      return Column(
        children: posts,
      );
    }
  }

  setpostOrientation(String postorientation) {
    setState(() {
      this.postOrientation = postorientation;
    });
  }

  buildTogglePostOrientation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          onPressed: () => setpostOrientation('grid'),
          icon: Icon(
            Icons.grid_on,
            color: postOrientation == 'grid'
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ),
        IconButton(
          onPressed: () => setpostOrientation('list'),
          icon: Icon(
            Icons.list,
            color: postOrientation == 'list'
                ? Theme.of(context).primaryColor
                : Colors.grey,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: header(context, texttitle: "Profile"),
      body: ListView(
        children: <Widget>[
          buildProfileHeader(),
          Divider(),
          buildTogglePostOrientation(),
          Divider(
            height: 0.0,
          ),
          buildProfilePost()
        ],
      ),
    );
  }

  buildProfileHeader() {
    return FutureBuilder(
        future: userRef.doc(widget.profileId).get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          User user = User.fromdocument(snapshot.data);
          return Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    CircleAvatar(
                      radius: 40.0,
                      backgroundColor: Colors.grey,
                      backgroundImage:
                          CachedNetworkImageProvider(user.photoUrl),
                    ),
                    Expanded(
                        child: Column(
                      children: <Widget>[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          mainAxisSize: MainAxisSize.max,
                          children: <Widget>[
                            buildCountColumn("posts", postCount),
                            buildCountColumn("followers", followersCount),
                            buildCountColumn("following", followingCount),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            buildprofileButton(),
                          ],
                        ),
                      ],
                    ))
                  ],
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    user.username,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.0,
                    ),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 5.0),
                  child: Text(
                    user.displayName,
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  alignment: Alignment.centerLeft,
                  padding: EdgeInsets.only(top: 5.0),
                  child: Text(
                    user.bio,
                  ),
                )
              ],
            ),
          );
        });
  }
}
