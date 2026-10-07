import 'dart:typed_data';

import 'package:share_plus/share_plus.dart';

import 'save_service_io.dart'
    if (dart.library.html) 'save_service_web.dart' as impl;

/// Saves / shares exported PNGs. The real work lives in the
/// platform files: [save_service_io.dart] for phones, [save_service_web.dart]
/// for browsers.
class SaveService {
  /// Saves to the photo gallery (phones) or downloads the file (web).
  static Future<void> saveToGallery(Uint8List bytes, String name) =>
      impl.saveToGallery(bytes, name);

  /// Saves to the app's files folder (phones) or downloads it (web).
  static Future<void> saveToFiles(Uint8List bytes, String name) =>
      impl.saveToFiles(bytes, name);

  /// Builds a shareable file for the platform share menu.
  static Future<XFile> makeShareFile(Uint8List bytes, String name) =>
      impl.makeShareFile(bytes, name);
}
