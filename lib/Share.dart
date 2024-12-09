import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ShareUtils {
  static Future<void> injectJavaScriptForSharing(InAppWebViewController webViewController) async {
    await webViewController.evaluateJavascript(
        source: '''
        window.NativeShare = function (url = '', title = '', text = '') {
          const shareData = { title, text, url };
          if (navigator.share) {
            if (navigator.canShare && navigator.canShare(shareData)) {
              navigator.share(shareData)
                .then(() => console.log('Share was successful.'))
                .catch((error) => console.error('Sharing failed:', error));
            } else {
              console.warn('Your content cannot be shared.');
            }
          } else {
            console.warn("Your system doesn't support sharing files SKRTSKRT.");
          }
        };
      '''
    );
  }

  static Future<void> triggerNativeShare(
      InAppWebViewController webViewController,
      String url,
      String title,
      String text,
      ) async {
    await webViewController.evaluateJavascript(
        source: 'NativeShare("$url", "$title", "$text");'
    );
  }
}