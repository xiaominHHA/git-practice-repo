import 'package:flutter_driver/driver_extension.dart';

import 'package:flutter_application/main.dart' as app;

void main() {
  // Enable Flutter Driver extension for automated UI interactions.
  enableFlutterDriverExtension();
  app.main();
}
