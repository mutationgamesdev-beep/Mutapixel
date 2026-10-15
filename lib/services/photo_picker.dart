import 'dart:typed_data';

import 'photo_picker_stub.dart'
    if (dart.library.html) 'photo_picker_web.dart' as impl;

/// Picks one image file from the user's device.
/// Returns null when the user cancels.
Future<Uint8List?> pickPhoto() => impl.pickPhoto();
