// Web implementation of the platform IO facade.
// Loaded only when dart:html is available (Flutter web builds).
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';

/// A file the user picked from disk.
class PickedMedia {
  final String name;
  final Uint8List bytes;
  const PickedMedia({required this.name, required this.bytes});
}

/// Opens a browser file picker and returns the chosen file's bytes.
///
/// [accept] uses the HTML `<input accept>` syntax, e.g. 'image/jpeg,image/png'.
/// Returns null if the user cancels (only supported by modern browsers via
/// the `cancel` event — on older browsers the future simply never completes,
/// which matches the prior behavior of this screen).
Future<PickedMedia?> pickMediaFile({required String accept}) {
  final completer = Completer<PickedMedia?>();
  final input = html.FileUploadInputElement()..accept = accept;

  input.onChange.listen((_) {
    final files = input.files;
    if (files == null || files.isEmpty) {
      if (!completer.isCompleted) completer.complete(null);
      return;
    }
    final file = files.first;
    final reader = html.FileReader();
    reader.readAsArrayBuffer(file);
    reader.onLoadEnd.listen((_) {
      if (completer.isCompleted) return;
      final raw = reader.result;
      Uint8List bytes;
      if (raw is Uint8List) {
        bytes = raw;
      } else if (raw is ByteBuffer) {
        bytes = raw.asUint8List();
      } else {
        completer.completeError(
          StateError('Unexpected file data type: ${raw.runtimeType}'),
        );
        return;
      }
      completer.complete(PickedMedia(name: file.name, bytes: bytes));
    });
    reader.onError.listen((_) {
      if (!completer.isCompleted) {
        completer.completeError(reader.error ?? StateError('FileReader error'));
      }
    });
  });

  // Modern browsers fire 'cancel' if the user dismisses the picker.
  input.addEventListener('cancel', (_) {
    if (!completer.isCompleted) completer.complete(null);
  });

  input.click();
  return completer.future;
}

/// Opens [url] in a new browser tab.
Future<bool> openExternalUrl(String url) async {
  html.window.open(url, '_blank');
  return true;
}
