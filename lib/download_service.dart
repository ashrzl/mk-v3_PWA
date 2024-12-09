import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path_provider/path_provider.dart';
import 'notification_service.dart'; // Import the NotificationService class

//added by hizam
import 'dart:async';

class FileDownloader {
  static Future<void> onDownloadStartRequest(
      InAppWebViewController controller,
      DownloadStartRequest request,
      InAppWebViewController webViewController
      ) async {
    // Extract relevant information
    final WebUri url = request.url;
    final String mimeType = request.mimeType ?? '';
    final String suggestedFilename = request.suggestedFilename ?? '';

    //tes name value
    final String suggestedFilesName = request.suggestedFilename!;
    print("The suggested filename is $suggestedFilesName");

    // Function to determine file type based on MIME type or suggested filename
    String determineFileType(String mimeType, String suggestedFilename, WebUri url) {
      if (mimeType.contains('application/pdf') || suggestedFilename.endsWith('.pdf')) {
        return 'PDF';
      } else if (mimeType.contains('text/csv') || suggestedFilename.endsWith('.csv')) {
        return 'CSV';
      } else if (mimeType.contains('application/octet-stream')) {
        if (suggestedFilename.endsWith('.pdf')) {
          return 'PDF';
        } else if (suggestedFilename.endsWith('.csv')) {
          return 'CSV';
        } else if (url.toString().contains('base64,')) {
          return 'Binary File';
        } else if (suggestedFilename.endsWith('.zip')) {
          return 'ZIP';
        }
      } else if (mimeType.contains('application/zip')){
        return 'ZIP';
      }
      return 'Unknown';
    }

    // Determine file type
    String fileType = determineFileType(mimeType, suggestedFilename, url);
    print('Detected file type: $fileType');
    print('URL: $url');

    if (fileType == 'PDF') {
      webViewController.evaluateJavascript(source: """
      (async function() {
        try {
          const response = await fetch('$url');
          const blob = await response.blob();
          const reader = new FileReader();
          reader.onloadend = function() {
            const base64Data = reader.result.split(',')[1];
            window.flutter_inappwebview.callHandler('blobHandler', base64Data, 'Downloaded.pdf');
          };
          reader.readAsDataURL(blob);
        } catch (error) {
          console.error('Error fetching blob data:', error);
        }
      })();
      """);
    } else if (fileType == 'CSV') {
      webViewController.evaluateJavascript(source: """
      (async function() {
        try {
          const response = await fetch('$url');
          const csvData = await response.text();
          window.flutter_inappwebview.callHandler('csvHandler', csvData, 'Downloaded.csv');
        } catch (error) {
          console.error('Error fetching CSV data:', error);
        }
      })();
      """);
    } else if (fileType == 'Binary File') {
      webViewController.evaluateJavascript(source: """
      (async function() {
        try {
          const response = await fetch('$url');
          const blob = await response.blob();
          const reader = new FileReader();
          reader.onloadend = function() {
            const base64Data = reader.result.split(',')[1];
            window.flutter_inappwebview.callHandler('blobHandler', base64Data, 'Downloaded.pdf');
          };
          reader.readAsDataURL(blob);
        } catch (error) {
          console.error('Error fetching blob data:', error);
        }
      })();
      """);
    } else if(fileType == 'ZIP'){
      webViewController.evaluateJavascript(source: """
      (async function() {
        try {
          const response = await fetch('$url');
          const blob = await response.blob();
          const reader = new FileReader();
          reader.onloadend = function() {
            const base64Data = reader.result.split(',')[1];
            window.flutter_inappwebview.callHandler('blobHandler', base64Data, 'Downloaded.zip');
          };
          reader.readAsDataURL(blob);
        } catch (error) {
          console.error('Error fetching blob data:', error);
        }
      })();
      """);
    } else {
      print('Something wrong');
    }
  }

  static Future<void> saveFile(List<int> bytes, String fileName) async {
    try {
      final directory = await getExternalStorageDirectory();
      final downloadPath = "${directory?.path}/Download";
      final downloadDir = Directory(downloadPath);

      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }

      String fullPath = "${downloadDir.path}/$fileName";
      String newFileName = fileName;
      int fileNumber = 1;

      // Check if the file already exists and increment the file name if it does
      while (await File(fullPath).exists()) {
        final extension = fileName.contains('.')
            ? fileName.substring(fileName.lastIndexOf('.'))
            : '';
        final baseName = fileName.replaceAll(extension, '');

        newFileName = "$baseName($fileNumber)$extension";
        fullPath = "${downloadDir.path}/$newFileName";
        fileNumber++;
      }

      final file = File(fullPath);
      await file.writeAsBytes(bytes);

      // Show notification after file is successfully saved
      await NotificationService.showDownloadNotification(newFileName, fullPath);

      print("File successfully saved to $fullPath");
    } catch (e) {
      print("Error saving file: $e");
    }
  }

}
