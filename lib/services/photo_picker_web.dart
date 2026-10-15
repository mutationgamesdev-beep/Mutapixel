import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

/// Web implementation: opens the browser's file picker and reads the
/// chosen image as bytes.
Future<Uint8List?> pickPhoto() {
  final completer = Completer<Uint8List?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/*';

  void finish(Uint8List? bytes) {
    if (!completer.isCompleted) completer.complete(bytes);
  }

  input.addEventListener(
    'change',
    ((web.Event _) {
      final files = input.files;
      if (files == null || files.length == 0) {
        finish(null);
        return;
      }
      final file = files.item(0);
      if (file == null) {
        finish(null);
        return;
      }
      final reader = web.FileReader();
      reader.addEventListener(
        'load',
        ((web.Event _) {
          final result = reader.result;
          if (result == null) {
            finish(null);
            return;
          }
          final bytes =
              (result as JSArrayBuffer).toDart.asUint8List();
          finish(Uint8List.fromList(bytes));
        }).toJS,
      );
      reader.addEventListener(
          'error', ((web.Event _) => finish(null)).toJS);
      reader.readAsArrayBuffer(file);
    }).toJS,
  );

  // Dismissing the dialog fires no change event; the window regaining
  // focus means the user walked away.
  web.window
      .addEventListener('focus', ((web.Event _) => finish(null)).toJS);

  input.click();
  return completer.future;
}
