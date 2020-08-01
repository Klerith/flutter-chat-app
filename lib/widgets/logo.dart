
import 'package:flutter/material.dart';

class Logo extends StatelessWidget {

  final String titulo;

  const Logo({
    Key key, 
    @required this.titulo
  }) : super(key: key);

  
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 170,
        margin: EdgeInsets.only( top: 50 ),
        child: Column(
          children: <Widget>[

            Image( image: AssetImage('assets/tag-logo.png') ),
            SizedBox( height: 20 ),
            Text( this.titulo, style: TextStyle(fontSize: 30 ))

          ],
        ),
      ),
    );
  }
}