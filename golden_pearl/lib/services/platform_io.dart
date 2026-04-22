// Cross-platform facade for two web-only operations the admin UI needs:
//   * picking a file from disk and reading its bytes
//   * opening a URL externally (new tab on web, browser on native)
//
// On web, the implementation uses dart:html.
// On native (iOS, Android, desktop), file picking is not implemented — callers
// should gate the call with `kIsWeb` and show a message to use the web admin.
// External URL opening uses url_launcher on native, window.open on web.
//
// Using conditional exports keeps dart:html completely out of the iOS build.
export '_platform_io_stub.dart'
    if (dart.library.html) '_platform_io_web.dart';
