import 'dart:io';
import 'dart:typed_data';

import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Phone implementation: real files, real gallery.
Future<void> saveToGallery(Uint8List bytes, String name) async {
  await Gal.putImageBytes(bytes, name: name);
}

Future<void> saveToFiles(Uint8List bytes, String name) async {
  final dir = await getApplicationDocumentsDirectory();
  await File('${dir.path}/$name').writeAsBytes(bytes);
}

Future<XFile> makeShareFile(Uint8List bytes, String name) async {
  final dir = await getTemporaryDirectory();
  final path = '${dir.path}/$name';
  await File(path).writeAsBytes(bytes);
  return XFile(path, name: name, mimeType: 'image/png');
}
