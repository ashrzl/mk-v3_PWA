import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masjidkitaflutter/main.dart';
import 'package:open_file/open_file.dart';

class NotificationService {
  static Future<void> createNotificationChannel() async {
    const AndroidNotificationChannel channel = AndroidNotificationChannel(
      'download_channel',
      'File Download',
      description: 'Notification channel for file downloads',
      importance: Importance.high,
    );

    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);
  }

  static Future<void> showDownloadNotification(String fileName, String filePath) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
    AndroidNotificationDetails(
      'download_channel', // Channel ID
      'File Download', // Channel Name
      channelDescription: 'Notification for completed file download',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
    );

    const NotificationDetails platformChannelSpecifics =
    NotificationDetails(android: androidPlatformChannelSpecifics);

    await flutterLocalNotificationsPlugin.show(
      0, // Notification ID
      'Download Complete',
      '$fileName has been downloaded.',
      platformChannelSpecifics,
      payload: filePath, // Optional payload for handling clicks
    );
  }

  static Future<void> onSelectNotification(String? payload) async {
    if (payload != null && payload.isNotEmpty) {
      // Open the file using the payload, which is the file path
      final result = await OpenFile.open(payload);

      // Handle any errors or issues during file opening (optional)
      // if (result.type != ResultType.done) {
      //   // Handle the error (e.g., show an error message)
      //   print('Error opening file: ${result.message}');
      // }
    } else {
      print('No file path provided in the notification payload.');
    }
  }
}
