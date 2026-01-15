import 'dart:io';

class AdHelper {
  static String get openAdUniteId {
    // Return test ad unit IDs during development
    // Use your real IDs ONLY for production builds
    if (Platform.isAndroid) {
      // Test Banner ID: ca-app-pub-3940256099942544/6300978111
      // return 'ca-app-pub-3879097594901223/2342300641';
      return 'ca-app-pub-3879097594901223/4334340485';
    } else {
      throw UnsupportedError('Unsupported platform');
    }
  }
}
