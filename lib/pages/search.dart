import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:socialmedia/models/user.dart';
import 'package:socialmedia/pages/activity_feed.dart';
import 'package:socialmedia/pages/home.dart';
import 'package:socialmedia/widgets/progress.dart';

class Search extends StatefulWidget {
  @override
  _SearchState createState() => _SearchState();
}

class _SearchState extends State<Search> {
  TextEditingController searchcontroller = TextEditingController();
  Future<QuerySnapshot> searchResults;
  handleSearch(String query) {
    Future<QuerySnapshot> users =
        userRef.where('displayName', isGreaterThanOrEqualTo: query).get();
    setState(() {
      searchResults = users;
    });
  }

  AppBar buildSearchField() {
    return AppBar(
      backgroundColor: Colors.white,
      title: TextFormField(
        decoration: InputDecoration(
            hintText: "search for users...",
            filled: true,
            prefixIcon: Icon(
              Icons.account_box,
              size: 28.0,
            ),
            suffixIcon: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                searchcontroller.clear();
              },
            )),
        onFieldSubmitted: handleSearch,
        controller: searchcontroller,
      ),
    );
  }

  Container buildnoContent() {
    return Container(
      child: Center(
        child: ListView(
          children: <Widget>[
            SvgPicture.asset(
              "assets/images/search.svg",
              height: 300.0,
            ),
            Text(
              "Find Users",
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Colors.white,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                  fontSize: 60.0),
            )
          ],
        ),
      ),
    );
  }

  buildSearchResults() {
    return FutureBuilder(
        future: searchResults,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return circularProgress();
          }
          List<UserResult> searchuser = [];
          snapshot.data.documents.forEach((doc) {
            User user = User.fromdocument(doc);
            UserResult searchusers = UserResult(user);
            searchuser.add(searchusers);
          });
          return ListView(
            children: searchuser,
          );
        });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor.withOpacity(0.8),
      appBar: buildSearchField(),
      body: searchResults == null ? buildnoContent() : buildSearchResults(),
    );
  }
}

class UserResult extends StatelessWidget {
  final User user;
  UserResult(this.user);

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).primaryColor.withOpacity(0.7),
        child: Column(
          children: <Widget>[
            GestureDetector(
            onTap: ()=>showProfile(context,profileId: user.id),
            child: ListTile(
              leading: CircleAvatar(
                backgroundImage: CachedNetworkImageProvider(user.photoUrl),
                backgroundColor: Colors.grey
              ),
              title: Text(user.displayName,style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold
              ),
              ),
              subtitle: Text(user.username,style: TextStyle(
                color: Colors.white,
              ),),
              
              
            ),
            ),
            Divider(
              height: 2.0,
              color: Colors.black,
            )
          ],
        ),

      );
  }
}
