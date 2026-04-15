// Default (non-web) HTTP client factory.
// Loaded on iOS, Android, macOS, Windows, Linux.
import 'package:http/http.dart' as http;

http.Client createPlatformHttpClient() => http.Client();
