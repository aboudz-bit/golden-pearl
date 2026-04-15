// Web-only HTTP client factory.
// Loaded when dart:html is available (Flutter web builds).
// Uses BrowserClient so the browser attaches session cookies automatically.
import 'package:http/browser_client.dart';
import 'package:http/http.dart' as http;

http.Client createPlatformHttpClient() {
  final client = BrowserClient();
  client.withCredentials = true;
  return client;
}
