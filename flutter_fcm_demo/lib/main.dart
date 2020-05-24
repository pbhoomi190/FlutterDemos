import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {

  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String textValue = "Hello world";
  FirebaseMessaging _firebaseMessaging = FirebaseMessaging();

  void configureFirebaseMessaging() {
    _firebaseMessaging.configure(
        onLaunch: (Map<String, dynamic> msg) async{
          print('On Launch');
         // _showItemDialog(msg);
        },
        onMessage: (Map<String, dynamic> msg) async{
          print('On Message');
          _showItemDialog(msg);
        },
        onResume: (Map<String, dynamic> msg) async{
          print('On Resume');
         // _showItemDialog(msg);
        }
    );
  }

  void _showItemDialog(Map<String, dynamic> message) {
    print('show dialog');
   showDialog(context: context, builder: (context) {
     return AlertDialog(
        title: Text('Alert!'),
       content: Text('You have tapped on a notification'),
     );
   });
  }

  void settingUpFirebaseForIOS() {
    _firebaseMessaging.requestNotificationPermissions(
        const IosNotificationSettings(badge: true, sound: true, alert: true)
    );
    _firebaseMessaging.onIosSettingsRegistered.listen((IosNotificationSettings setting) {
      print('IOS settings $setting');
     }
    );
    _firebaseMessaging.getToken().then((token) {
      update(token);
    });
  }

  void update(String token) {
    print(token);
    setState(() {
      textValue = token;
    });
  }


  @override
  void initState() {
    configureFirebaseMessaging();
    settingUpFirebaseForIOS();
    super.initState();
  }

  @override
  void dispose() {
      super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: Scaffold(
          appBar: AppBar(
            title: Text('Firebase notifications'),
          ),
          body: Center(
            child: Column(
              children: <Widget>[
                Text('FCM demo'),
                Text('Token: $textValue'),
              ],
            ),
       ),
     ),
    );
  }
}


