// Native (non-web) implementation of the platform IO facade.
// Loaded on iOS, Android, macOS, Windows, Linux.
import 'dart:typed_data';
import 'package:url_launcher/url_launcher.dart';

/// A file the user picked from disk.
class PickedMedia {
  final String name;
  final Uint8List bytes;
  const PickedMedia({required this.name, required this.bytes});
}

/// Opens a file picker and returns the chosen file.
///
/// Native platforms do NOT implement this — returns null. Callers should
/// check `kIsWeb` before calling and show a user-facing message on native.
/// Adding native file-picking would require a plugin (e.g. file_picker); this
/// is intentionally out of scope to keep the iOS build surface minimal.
Future<PickedMedia?> pickMediaFile({required String accept}) async => null;

/// Opens [url] in the platform's default browser.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
