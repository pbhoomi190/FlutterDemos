import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutternotificationsdemo/localnotification.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:async';
import 'package:rxdart/subjects.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
FlutterLocalNotificationsPlugin();

// Streams are created so that app can respond to notification-related events since the plugin is initialised in the `main` function
final BehaviorSubject<ReceivedNotification> didReceiveLocalNotificationSubject =
BehaviorSubject<ReceivedNotification>();

final BehaviorSubject<String> selectNotificationSubject =
BehaviorSubject<String>();

NotificationAppLaunchDetails notificationAppLaunchDetails;

class ReceivedNotification {
  final int id;
  final String title;
  final String body;
  final String payload;

  ReceivedNotification({
    @required this.id,
    @required this.title,
    @required this.body,
    @required this.payload,
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  notificationAppLaunchDetails =
  await flutterLocalNotificationsPlugin.getNotificationAppLaunchDetails();

  var androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  var iOSSettings = IOSInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      onDidReceiveLocalNotification:
          (int id, String title, String body, String payload) async {
        didReceiveLocalNotificationSubject.add(ReceivedNotification(
            id: id, title: title, body: body, payload: payload));
      });
  var initializationSettings = InitializationSettings(
      androidSettings, iOSSettings);
  await flutterLocalNotificationsPlugin.initialize(initializationSettings,
      onSelectNotification: (String payload) async {
        if (payload != null) {
          debugPrint('notification payload: ' + payload);
        }
        selectNotificationSubject.add(payload);
      });
  // Setup for local notifications goes here...
  runApp(MaterialApp(
    home: MyApp(),
  ));
}

class MyApp extends StatefulWidget {
  // This widget is the root of your application.
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  final MethodChannel platform = MethodChannel('crossingthestreams.io/resourceResolver');

  @override
  void initState() {
    // Request permission for iOS
    super.initState();
    _requestIOSPermissions();
    _configureDidReceiveLocalNotificationSubject();
    _configureSelectNotificationSubject();
  }

  void _requestIOSPermissions() {
    flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _configureDidReceiveLocalNotificationSubject() {
    didReceiveLocalNotificationSubject.stream
        .listen((ReceivedNotification receivedNotification) async {
      await showDialog(
        context: context,
        builder: (BuildContext context) => CupertinoAlertDialog(
          title: receivedNotification.title != null
              ? Text(receivedNotification.title)
              : null,
          content: receivedNotification.body != null
              ? Text(receivedNotification.body)
              : null,
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text('Ok'),
              onPressed: () async {
                Navigator.of(context, rootNavigator: true).pop();
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SecondScreen(text: receivedNotification.payload,)
                  ),
                );
              },
            )
          ],
        ),
      );
    });
  }

  void _configureSelectNotificationSubject() {
    selectNotificationSubject.stream.listen((String payload) async {
      print('select notification subjecct $payload');
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => SecondScreen(text: payload,)),
      );
    });
  }

  @override
  void dispose() {
    didReceiveLocalNotificationSubject.close();
    selectNotificationSubject.close();
    super.dispose();
  }

  Future<String> _downloadAndSaveFile(String url, String fileName) async {
    var directory = await getApplicationDocumentsDirectory();
    var filePath = '${directory.path}/$fileName';
    var response = await http.get(url);
    var file = File(filePath);
    await file.writeAsBytes(response.bodyBytes);
    return filePath;
  }

  Future<void> showNotification() async {
    var androidNotification = AndroidNotificationDetails('Channel ID', 'Channel Name', 'Channel Description');
    var iOSNotification = IOSNotificationDetails();
    var notificationDetail = NotificationDetails(androidNotification, iOSNotification);
    await flutterLocalNotificationsPlugin.show(0, "1st notification", "Simple text notification", notificationDetail, payload: 'This is payload');
  }

  Future<void> showNotificationWithoutBody() async {
    var androidNotification = AndroidNotificationDetails('Channel ID', 'Channel Name', 'Channel Description');
    var iOSNotification = IOSNotificationDetails();
    var notificationDetail = NotificationDetails(androidNotification, iOSNotification);
    await flutterLocalNotificationsPlugin.show(
        0, 'plain title', null, notificationDetail,
        payload: 'Notification without body');
  }

  Future<void> _cancelNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  Future<void> showNotificationWithUpdatedChannelDescription() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id',
        'your channel name',
        'your updated channel description',
        importance: Importance.Max,
        priority: Priority.High,
        channelAction: AndroidNotificationChannelAction.Update);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0,
        'updated notification channel',
        'check settings to see updated channel description',
        platformChannelSpecifics,
        payload: 'item x');
  }

  Future<void> showPublicNotificationOnLockScreen() async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max,
        priority: Priority.High,
        ticker: 'ticker',
        visibility: NotificationVisibility.Public);
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(0, 'public notification title',
        'public notification body', platformChannelSpecifics,
        payload: 'Notification shows on locked device');
  }

  Future<void> showBigTextNotification() async {

    var bigTextStyleInformation = BigTextStyleInformation(
        'Lorem <i>ipsum dolor sit</i> amet, consectetur <b>adipiscing elit</b>, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum.',
        htmlFormatBigText: true,
        contentTitle: 'Message from <b>DemoApp</b> check:',
        htmlFormatContentTitle: true,
        summaryText: 'Summary: <i>Register today...</i>',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'big text channel id',
        'big text channel name',
        'big text channel description',
        styleInformation: bigTextStyleInformation);
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics);
  }

  Future<void> showBigPictureNotification() async {
    var largeIconPath = await _downloadAndSaveFile(
        'http://via.placeholder.com/48x48', 'largeIcon'); // This will be the small icon like image in the left
    var bigPicturePath = await _downloadAndSaveFile(
        'http://via.placeholder.com/400x800', 'bigPicture'); // This will be shown as bigger sized image below text
    var bigPictureStyleInformation = BigPictureStyleInformation(
        FilePathAndroidBitmap(bigPicturePath),
        largeIcon: FilePathAndroidBitmap(largeIconPath),
        contentTitle: 'This is <b>HTML</b> text title',
        htmlFormatContentTitle: true,
        summaryText: 'This will be <i>below</i> the text content',
        htmlFormatSummaryText: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'id',
        'name',
        '',
        styleInformation: bigPictureStyleInformation);
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'big text title', 'silent body', platformChannelSpecifics);
  }

  Future<void> showMediaNotification() async {
    var largeIconPath = await _downloadAndSaveFile(
        'http://via.placeholder.com/128x128/00FF00/000000', 'largeIcon');
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
      'id',
      'name',
      'description',
      largeIcon: FilePathAndroidBitmap(largeIconPath),
      styleInformation: MediaStyleInformation(htmlFormatTitle: true, htmlFormatContent: true),
    );
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, '<b>MediaTitle</b>', '<i>Media body</i>', platformChannelSpecifics);
  }

  Future<void> showInboxNotification() async {
    var lines = List<String>();
    lines.add('line <b>1</b>');
    lines.add('line <i>2</i>');
    var inboxStyleInformation = InboxStyleInformation(lines, htmlFormatLines: true);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'inbox channel id', 'inboxchannel name', 'inbox channel description',
        styleInformation: inboxStyleInformation);
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        1, 'inbox title', 'inbox body', platformChannelSpecifics);
  }

  Future<void> showMessagingNotification() async {

    var messages = List<Message>();
    // First two person objects will use icons that part of the Android app's drawable resources
    var me = Person(
      name: 'Me',
      key: '1',
      uri: 'tel:1234567890',
    );
    var friend = Person(
      name: 'Pranjal',
      key: '2',
      uri: 'tel:9876543210',
    );

    messages.add(Message('Hi', DateTime.now(), null));
    messages.add(Message(
        'What\'s up?', DateTime.now().add(Duration(seconds: 5)), friend));
    messages.add(Message(
        'Lunch?', DateTime.now().add(Duration(seconds: 10)), null,));

    var messagingStyle = MessagingStyleInformation(me,
        groupConversation: true,
        conversationTitle: 'Lunch',
        htmlFormatContent: false,
        htmlFormatTitle: false,
        messages: messages);
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'id',
        'name',
        'description',
        category: 'msg',
        styleInformation: messagingStyle);
    var platformChannelSpecifics =
    NotificationDetails(androidPlatformChannelSpecifics, null);
    await flutterLocalNotificationsPlugin.show(
        0, 'message title', 'message body', platformChannelSpecifics);

    // wait 10 seconds and add another message to simulate another response
    await Future.delayed(Duration(seconds: 10), () async {
      messages.add(
          Message('Thai', DateTime.now().add(Duration(seconds: 15)), friend));
      messages.add(
          Message('No....', DateTime.now().add(Duration(minutes: 11)), me));
      await flutterLocalNotificationsPlugin.show(
          0, 'message title', 'message body', platformChannelSpecifics);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Local Notification Demo'),
        ),
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              RaisedButton(
                child: Text('Show simple text notification', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showNotification();
                },
              ),
              RaisedButton(
                child: Text('Notification without body', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showNotificationWithoutBody();
                },
              ),
              RaisedButton(
                child: Text('Payload and update channel description', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showNotificationWithUpdatedChannelDescription();
                },
              ),
              RaisedButton(
                child: Text('Show plain notification on lock screen', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showPublicNotificationOnLockScreen();
                },
              ),
              RaisedButton(
                child: Text('Big text notification - Android only', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showBigTextNotification();
                },
              ),
              RaisedButton(
                child: Text('Big picture notification - Android only', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showBigPictureNotification();
                },
              ),
              RaisedButton(
                child: Text('Media notification - Android only', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showMediaNotification();
                },
              ),
              RaisedButton(
                child: Text('Inbox notification - Android only', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showInboxNotification();
                },
              ),
              RaisedButton(
                child: Text('Messaging notification - Android only', textAlign: TextAlign.center,),
                onPressed: () async {
                  await showMessagingNotification();
                },
              ),
            ],
          ),
        )
    );
  }
}
