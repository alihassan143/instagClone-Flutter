import 'package:flutter/material.dart';

 AppBar header(context,{bool isApptitle  =false,String texttitle}) {
  return AppBar(
    title:Text( isApptitle?"Flutter Firebase":texttitle,
    style: TextStyle(
      color: Colors.white,
      fontFamily: "Signatra",
      fontSize: 50.0
    ),
    ),
    centerTitle: true,
    backgroundColor: Theme.of(context).accentColor,
    
  );
}
