import 'dart:html' as html;

void downloadFileWeb(dynamic content, String filename) {
  final blob = html.Blob([content]);
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}