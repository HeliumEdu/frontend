import 'dart:typed_data';

class AttachmentFile {
  final Uint8List bytes;
  final String title;

  AttachmentFile({required this.bytes, required this.title});
}
