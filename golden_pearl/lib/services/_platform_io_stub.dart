// Native (non-web) implementation of the platform IO facade.
// Loaded on iOS, Android, macOS, Windows, Linux.
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';

/// A file the user picked from disk.
class PickedMedia {
  final String name;
  final Uint8List bytes;
  const PickedMedia({required this.name, required this.bytes});
}

final ImagePicker _picker = ImagePicker();

/// Opens a native image/video picker and returns the chosen file.
///
/// We inspect [accept] to decide whether to launch the image picker, video
/// picker, or "media" picker (both). On iOS this opens the system photo
/// library sheet; on Android it opens the gallery picker.
Future<PickedMedia?> pickMediaFile({required String accept}) async {
  final wantsVideo = accept.contains('video');
  final wantsImage = accept.contains('image');

  XFile? file;
  try {
    if (wantsVideo && wantsImage) {
      file = await _picker.pickMedia();
    } else if (wantsVideo) {
      file = await _picker.pickVideo(source: ImageSource.gallery);
    } else {
      file = await _picker.pickImage(source: ImageSource.gallery);
    }
  } catch (e, st) {
    // Surface plugin failures (missing NSPhotoLibraryUsageDescription,
    // platform-channel errors, permission denials, etc.) so the admin
    // upload buttons can show a visible message instead of silently
    // doing nothing.
    debugPrint('[pickMediaFile] image_picker threw: $e\n$st');
    return null;
  }
  if (file == null) return null;
  try {
    final bytes = await file.readAsBytes();
    return PickedMedia(name: file.name, bytes: bytes);
  } catch (e, st) {
    debugPrint('[pickMediaFile] readAsBytes failed for ${file.name}: $e\n$st');
    return null;
  }
}

/// Opens [url] in the platform's default browser.
Future<bool> openExternalUrl(String url) async {
  final uri = Uri.tryParse(url);
  if (uri == null) return false;
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
