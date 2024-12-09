import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/src/scheduler/binding.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:masjidkitaflutter/download_service.dart';
import 'package:permission_handler/permission_handler.dart';
import 'notification_service.dart';

//added by hizam
import 'dart:async';
import 'package:flutter_downloader/flutter_downloader.dart';

Future<void> checkPermissions() async {
  final storageStatus = await Permission.storage.status;
  if (!storageStatus.isGranted) {
    final resultStorage = await Permission.storage.request();
    if (resultStorage.isGranted) {
      print("Storage permission granted.");
    } else {
      print("Storage permission denied.");
    }
  } else {
    print("Storage permission already granted.");
  }

  // final cameraStatus = await Permission.camera.status;
  // if(!cameraStatus.isGranted){
  //   final resultCamera = await Permission.camera.request();
  //   if(resultCamera.isGranted){
  //     print('Camera permission is granted.');
  //   }
  //   else{
  //     print('Camera Permission is denied.');
  //   }
  // } else{
  //   print('Camera permission already granted');
  // }

  final notificationStatus = await Permission.notification.status;
  if(!notificationStatus.isGranted){
    final resultNotification = await Permission.notification.request();
    if(resultNotification.isGranted){
      print('Notification permission is granted.');
    }
    else{
      print('Notification Permission is denied.');
    }
  } else{
    print('Notification permission already granted');
  }
}

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const AndroidInitializationSettings initializationSettingsAndroid =
  AndroidInitializationSettings('@mipmap/playstore');

  final InitializationSettings initializationSettings =
  InitializationSettings(android: initializationSettingsAndroid);

  await flutterLocalNotificationsPlugin.initialize(
    initializationSettings,
    onDidReceiveNotificationResponse: (NotificationResponse response) async {
      // Handle the notification response
      await NotificationService.onSelectNotification(response.payload);
    },
  );

  await checkPermissions(); // Ensure this method is defined elsewhere in your code

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky); //Hide status bar

  // Plugin must be initialized before using
  await FlutterDownloader.initialize(
      debug: true, // optional: set to false to disable printing logs to console (default: true)
      ignoreSsl: true // option: set to false to disable working with http links (default: false)
  );

  runApp(MyApp());
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext conxtext) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'MasjidKITA',
      home: WebViewScreen(),
    );
  }
}
class WebViewScreen extends StatefulWidget {
  @override
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  late InAppWebViewController _webViewController;
  final WebUri _initialUrl = WebUri("https://cmsb-env3.com.my/");
  bool isNativeApp = true; //Flag to indicate if the app is running natively

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PopScope(
        canPop: false,
        onPopInvoked: (didpop) async{
          if (await _webViewController.canGoBack()){
            _webViewController.goBack();
          }
          WidgetsBinding.instance.addPostFrameCallback((){
            Navigator.pop(context);
          } as FrameCallback);

        },
        child: InAppWebView(
          initialUrlRequest: URLRequest(
            url: _initialUrl,
          ),
          initialSettings: InAppWebViewSettings(
            allowFileAccess: true,
            allowUniversalAccessFromFileURLs: true,
            allowsBackForwardNavigationGestures: false,
            cacheEnabled: true,
            saveFormData: true,
            javaScriptEnabled: true,
            domStorageEnabled: true,
            useOnDownloadStart: true,
          ),
          onReceivedServerTrustAuthRequest: (controller, challenge) async {
            return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
          },
          onWebViewCreated: (controller) {
            _webViewController = controller;

            //Expose the flag from flutter
            _webViewController.evaluateJavascript(source: '''
              window.IsWebView = true;
              ''');

            _webViewController.addJavaScriptHandler(
              handlerName: 'blobHandler',
              callback: (args) async {
                final base64Data = args[0] as String;
                final fileName = args[1] as String;
                final bytes = base64Decode(base64Data);
                await FileDownloader.saveFile(bytes, fileName);
              },
            );

            _webViewController.addJavaScriptHandler(
              handlerName: 'csvHandler',
              callback: (args) async {
                final csvData = args[0] as String;
                final fileName = args[1] as String;
                final bytes = utf8.encode(csvData);
                await FileDownloader.saveFile(bytes, fileName);
              },
            );

            _webViewController.addJavaScriptHandler(
              handlerName: 'zipHandler',
              callback: (args) async {
                final base64Data = args[0] as String;
                final fileName = args[1] as String;
                final bytes = base64Decode(base64Data);
                await FileDownloader.saveFile(bytes, fileName);
              },
            );

          },
          onDownloadStartRequest: (controller, request) async {
            await FileDownloader.onDownloadStartRequest(controller, request, _webViewController);
          },
          onLoadStart: (controller, url) async {
            print("Started loading : ${url?.toString()}");
          },
          onLoadStop: (controller, url) async {
            // Inject the JavaScript code to set isWebView and call the visibility function
            await controller.evaluateJavascript(source: """
              window.isWebView = function () {
                return true; // This ensures the web page knows it's inside a WebView
              };
            """);
          },
          onReceivedError: (controller, request, error) {
            print('Error loading URL ${request.url}');
            print('Error description : ${error.description}');
          },
          onConsoleMessage: (controller, consoleMessage) {
            print("Console message: ${consoleMessage.message}");
          },
          onPermissionRequest: (controller, request) async {
            return PermissionResponse(
              resources: request.resources,
              action: PermissionResponseAction.GRANT,
            );
          },
        ),
      ),
    );
  }
}
