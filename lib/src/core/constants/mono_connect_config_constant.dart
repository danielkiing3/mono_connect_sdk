/// Configuration constants for Mono Connect
class MonoConnectConfigConstant {
  static const String urlScheme = 'https';
  static const String connectHost = 'connect.mono.co';
  static const String version = '2023-12-14';
  static const String jsChannelName = 'MonoClientInterface';

  /// JavaScript code to enable dark mode in WebView
  static const String darkModeScript = '''
    document.head.appendChild(document.createElement("style")).innerHTML=
    "html { filter: invert(.95) hue-rotate(180deg) }"
  ''';
}
