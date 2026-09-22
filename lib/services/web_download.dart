// Web-only file download through an <a download> anchor.
import 'dart:html' as html;

bool downloadTextFile(String filename, String contents, String mime) {
  final blob = html.Blob([contents], mime);
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return true;
}
