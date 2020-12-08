import 'dart:async';

import 'package:flutter/material.dart';
import 'package:socialmedia/widgets/header.dart';

class CreateAccount extends StatefulWidget {
  @override
  _CreateAccountState createState() => _CreateAccountState();
}

class _CreateAccountState extends State<CreateAccount> {
  final scaffold = GlobalKey<ScaffoldState>();
  final _formkey = GlobalKey<FormState>();
  String username;
  submit() {
    final form = _formkey.currentState;
    if (form.validate()) {
      form.save();
      // ignore: unnecessary_brace_in_string_interps
      SnackBar snackBar = SnackBar(content: Text("Welcome ${username}"));
      scaffold.currentState.showSnackBar(snackBar);
      Timer(Duration(seconds: 2), () {
         Navigator.pop(context, username);

      });
     
    }
  }

  @override
  Widget build(BuildContext parentContext) {
    return Scaffold(
      key: scaffold,
      appBar: header(context, texttitle: "Set Up Your Profile"),
      body: ListView(
        children: <Widget>[
          Container(
            child: Column(
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(top: 25.0),
                  child: Center(
                    child: Text(
                      "Create a UserName",
                      style: TextStyle(fontSize: 25.0),
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Form(
                    autovalidateMode: AutovalidateMode.always,
                    key: _formkey,
                    child: TextFormField(
                      validator: (val) {
                        if (val.trim().length < 3 || val.isEmpty) {
                          return "username too short";
                        } else if (val.trim().length > 12) {
                          return "username too long";
                        } else {
                          return null;
                        }
                      },
                      onSaved: (val) => username = val,
                      decoration: InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "username",
                          labelStyle: TextStyle(fontSize: 15.0),
                          hintText: "Must be At Least 3 Characters"),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: submit,
                  child: Container(
                    height: 50,
                    width: 100,
                    decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(7.0)),
                    child: Center(
                      child: Text(
                        "Submit",
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.0,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
