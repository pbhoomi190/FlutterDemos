import 'package:flutter/material.dart';

class SecondScreen extends StatelessWidget {
  final String text;
  SecondScreen({this.text});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Second Screen'),
      ),
      body: Center(
        child: Text(text),
      ),
    );
  }
}
