import 'dart:js_interop';
import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';
import 'package:web/web.dart' as web;

/// Web implementation: browsers can't touch the file system or the
/// photo gallery, so "saving" downloads the PNG instead.
Future<void> saveToGallery(Uint8List bytes, String name) =>
    _download(bytes, name);

Future<void> saveToFiles(Uint8List bytes, String name) =>
    _download(bytes, name);

Future<XFile> makeShareFile(Uint8List bytes, String name) async {
  return XFile.fromData(bytes, name: name, mimeType: 'image/png');
}

Future<void> _download(Uint8List bytes, String name) async {
  final blob = web.Blob(
    [bytes.toJS].toJS,
    web.BlobPropertyBag(type: 'image/png'),
  );
  final url = web.URL.createObjectURL(blob);
  final anchor = web.document.createElement('a') as web.HTMLAnchorElement;
  anchor.href = url;
  anchor.download = name;
  web.document.body!.append(anchor);
  anchor.click();
  anchor.remove();
  web.URL.revokeObjectURL(url);
}
