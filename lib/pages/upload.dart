import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:socialmedia/models/user.dart';
import 'package:socialmedia/pages/home.dart';
import 'package:socialmedia/widgets/progress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:image/image.dart' as Im;
import 'package:uuid/uuid.dart';

class Upload extends StatefulWidget {
  final User currentUser;
  Upload({this.currentUser});
  @override
  _UploadState createState() => _UploadState();
}

class _UploadState extends State<Upload> {
  File selectedfile;
  bool isuploading = false;
  TextEditingController locationController = TextEditingController();
  TextEditingController captionController = TextEditingController();
  String postId = Uuid().v4();
  void handleCamera() async {
    Navigator.pop(context);

    await Permission.photos.request();
    var permission = await Permission.photos.status;
    if (permission.isGranted) {
      // final picker = ImagePicker();
      PickedFile pickedfile =
          await ImagePicker().getImage(source: ImageSource.camera);
      File file = File(pickedfile.path);
      // File file = await ImagePicker.platform
      //     .pickImage(source: ImageSource.camera, maxHeight: 675, maxWidth: 970)
      //     .then((value) => null);
      setState(() {
        this.selectedfile = file;
      });
    } else {
      Widget okButton = FlatButton(
        child: Text("OK"),
        onPressed: () => Navigator.pop(context),
      );
      return showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: AlertDialog(
              title: Text("Permissons"),
              content: Text("Please grant the access permission."),
              actions: [
                okButton,
              ],
            ),
          );
        },
      );
    }
  }

  void handleGallery() async {
    Navigator.pop(context);
    await Permission.photos.request();

    var permission = await Permission.photos.status;
    if (permission.isGranted) {
      PickedFile pickedfile =
          await ImagePicker().getImage(source: ImageSource.gallery);
      File file = File(pickedfile.path);
      setState(() {
        this.selectedfile = file;
      });
    } else {
      Widget okButton = FlatButton(
        child: Text("OK"),
        onPressed: () => Navigator.pop(context),
      );
      return showDialog(
        context: context,
        builder: (context) {
          return Center(
            child: AlertDialog(
              title: Text("Permissons"),
              content: Text("Please grant the access permission."),
              actions: [
                okButton,
              ],
            ),
          );
        },
      );
    }

    // final picker = ImagePicker();
    // PickedFile pickedfile = await picker.getImage(source: ImageSource.gallery);
    // file = File(pickedfile.path);
  }

  selectImage(parentcontext) {
    return showDialog(
        context: parentcontext,
        builder: (context) {
          return SimpleDialog(
            title: Text("create post"),
            children: <Widget>[
              SimpleDialogOption(
                child: Text("Select From Camera"),
                onPressed: () => handleCamera(),
              ),
              SimpleDialogOption(
                child: Text("Select From Gallery"),
                onPressed: () => handleGallery(),
              ),
              SimpleDialogOption(
                child: Text("Cancel"),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          );
        });
  }

  Container splashScreen() {
    return Container(
      color: Theme.of(context).accentColor.withOpacity(0.5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          SvgPicture.asset(
            "assets/images/upload.svg",
            height: 150,
          ),
          Padding(
            padding: EdgeInsets.only(top: 20.0),
            child: RaisedButton(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0)),
              onPressed: () => selectImage(context),
              color: Colors.deepOrange,
              child: Text(
                "Upload Image",
                style: TextStyle(color: Colors.white, fontSize: 22.0),
              ),
            ),
          )
        ],
      ),
    );
  }

  clearImage() {
    setState(() {
      selectedfile = null;
    });
  }

  compressImage() async {
    final tempdirectory = await getTemporaryDirectory();
    final path = tempdirectory.path;
    Im.Image imagefile = Im.decodeImage(selectedfile.readAsBytesSync());
    final compressedImageFile = File('$path/img_$postId.jpg')
      ..writeAsBytesSync(Im.encodeJpg(imagefile, quality: 85));
    setState(() {
      selectedfile = compressedImageFile;
    });
  }

  Future<String> uploadImage(imageFile) async {
    UploadTask uploadTask =
        storageRef.child('post_$postId.jpg').putFile(imageFile);
    TaskSnapshot storageSnap = await uploadTask.whenComplete(() => null);
    String downloadUrl = await storageSnap.ref.getDownloadURL();
    return downloadUrl;
  }

  createPostinFirestore(
      {String mediaUrl, String location, String description}) {
    postsRef
        .doc(widget.currentUser.id)
        .collection('usersPosts')
        .doc(postId)
        .set({
      "postId": postId,
      "ownerId": widget.currentUser.id,
      "username": widget.currentUser.username,
      "mediaUrl": mediaUrl,
      "description": description,
      "location": location,
      "timestamp": timestamp,
      "likes": {},
    });
  }

  handleSubmit() async {
    setState(() {
      isuploading = true;
    });
    await compressImage();
    String mediaUrl = await uploadImage(selectedfile);
    createPostinFirestore(
        mediaUrl: mediaUrl,
        location: locationController.text,
        description: captionController.text);
    captionController.clear();
    locationController.clear();
    setState(() {
      selectedfile = null;
      isuploading = false;
    });
  }

  Scaffold buildUploadForm() {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.black,
          ),
          onPressed: clearImage,
        ),
        title: Text(
          "Caption Post",
          style: TextStyle(color: Colors.black),
        ),
        actions: [
          FlatButton(
            onPressed: isuploading ? null : () => handleSubmit(),
            child: Text(
              'Post',
              style: TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.bold,
                  fontSize: 20.0),
            ),
          )
        ],
      ),
      body: ListView(
        children: <Widget>[
          isuploading ? linearProgress() : Text(""),
          Container(
            height: 220.0,
            width: MediaQuery.of(context).size.width * 0.8,
            child: Center(
                child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    fit: BoxFit.cover,
                    image: FileImage(selectedfile),
                  ),
                ),
              ),
            )),
          ),
          Padding(padding: EdgeInsets.only(top: 10.0)),
          ListTile(
            leading: CircleAvatar(
              backgroundImage:
                  CachedNetworkImageProvider(widget.currentUser.photoUrl),
            ),
            title: Container(
                width: 250.0,
                child: TextField(
                  controller: captionController,
                  decoration: InputDecoration(
                      hintText: "Write Caption", border: InputBorder.none),
                )),
          ),
          Divider(),
          ListTile(
            leading: Icon(
              Icons.pin_drop,
              color: Colors.orange,
              size: 35.0,
            ),
            title: Container(
              width: 250.0,
              child: TextField(
                controller: locationController,
                decoration: InputDecoration(
                    hintText: "Where was the photo taken",
                    border: InputBorder.none),
              ),
            ),
          ),
          Container(
            width: 200.0,
            height: 100.0,
            alignment: Alignment.center,
            child: RaisedButton.icon(
              onPressed: () {
                userCurrentLocation();
              },
              icon: Icon(
                Icons.my_location,
                color: Colors.white,
              ),
              label: Text(
                "Use Current Location",
                style: TextStyle(color: Colors.white),
              ),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0)),
              color: Colors.blue,
            ),
          )
        ],
      ),
    );
  }

  userCurrentLocation() async {
    final geocodingPlatform = GeocodingPlatform.instance;
    Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);
    List<Placemark> placemarks = await geocodingPlatform
        .placemarkFromCoordinates(position.latitude, position.longitude);
    Placemark placemark = placemarks[0];
    String completeadress =
        '${placemark.country},${placemark.administrativeArea},${placemark.subThoroughfare},${placemark.subLocality},${placemark.locality},${placemark.subAdministrativeArea},${placemark.postalCode}';
    print(completeadress);
    String formattedaddress = "${placemark.locality},${placemark.country}";
    locationController.text = formattedaddress;
  }

  @override
  Widget build(BuildContext context) {
    return selectedfile == null ? splashScreen() : buildUploadForm();
  }
}
