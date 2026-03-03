import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class PickedFile {
  final List<int> bytes;
  final String name;
  PickedFile(this.bytes, this.name);
}

Future<PickedFile?> pickFileWeb(String accept) async {
  if (!kIsWeb) return null;

  try {
    final dynamic html = await _importHtml();
    if (html == null) return null;

    final completer = Completer<PickedFile?>();
    final input = html.document.createElement('input');
    input.setAttribute('type', 'file');
    input.setAttribute('accept', accept);

    input.addEventListener('change', (event) {
      try {
        final files = input.files;
        if (files == null || files.length == 0) {
          completer.complete(null);
          return;
        }
        final file = files[0];
        final reader = html.FileReader();
        reader.addEventListener('loadend', (e) {
          try {
            final result = reader.result;
            if (result != null) {
              completer.complete(PickedFile(
                List<int>.from(result as Uint8List),
                file.name.toString(),
              ));
            } else {
              completer.complete(null);
            }
          } catch (_) {
            completer.complete(null);
          }
        });
        reader.readAsArrayBuffer(file);
      } catch (_) {
        completer.complete(null);
      }
    });

    input.click();

    return completer.future.timeout(
      const Duration(minutes: 5),
      onTimeout: () => null,
    );
  } catch (_) {
    return null;
  }
}

Future<dynamic> _importHtml() async {
  return null;
}
