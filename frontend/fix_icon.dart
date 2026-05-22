import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/icon/ico_foreground.png');
  if (!file.existsSync()) {
    print('File not found!');
    return;
  }
  
  // Read and decode the image
  final image = img.decodePng(file.readAsBytesSync());
  if (image == null) {
    print('Failed to decode image');
    return;
  }
  
  // Set the 4 corners to 1% opacity white to prevent trimming
  // Note: image package uses different formats, we can use setPixelRgba
  // 1 opacity out of 255 is practically invisible but stops trimming
  image.setPixelRgba(0, 0, 255, 255, 255, 1);
  image.setPixelRgba(image.width - 1, 0, 255, 255, 255, 1);
  image.setPixelRgba(0, image.height - 1, 255, 255, 255, 1);
  image.setPixelRgba(image.width - 1, image.height - 1, 255, 255, 255, 1);

  // Re-encode and save
  file.writeAsBytesSync(img.encodePng(image));
  print('Injected anchor pixels successfully!');
}
