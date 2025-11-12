@JS()
library mono;

import 'package:js/js_util.dart' as js;

import 'package:js/js.dart';

// invokes Mono.setup(data)`.
@JS('MonoConnect.setup')
external void setup(Object obj);

@JS('MonoConnect.open')
external void open();

@JS('setupMonoConnect')
external void setupMonoConnect(String key, String? reference, String? data,
    String? authCode, String? scope);

dynamic _nested(dynamic val) {
  if (val.runtimeType.toString() == 'LegacyJavaScriptObject') {
    return jsToMap(val);
  }
  return val;
}

/// A workaround to converting an object from JS to a Dart Map.
Map jsToMap(jsObject) {
  return Map.fromIterable(_getKeysOfObject(jsObject), value: (key) {
    return _nested(js.getProperty(jsObject, key));
  });
}

// Both of these interfaces exist to call `Object.keys` from Dart.
//
// But you don't use them directly. Just see `jsToMap`.
@JS('Object.keys')
external List<String> _getKeysOfObject(jsObject);
