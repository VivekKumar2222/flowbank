import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:js_interop';
import 'dart:js_interop_unsafe';

@JS()
external JSObject get globalThis;

Future<void> openPlaidOnWeb({
  required String linkToken,
  required void Function(String publicToken) onSuccess,
  required void Function(String? errorCode, String? errorMessage) onExit,
}) async {
  if (!globalThis.has('Plaid')) {
    await _loadPlaidScript();
  }

  final config = JSObject();
  config['token'] = linkToken.toJS;
  config['onSuccess'] = ((JSAny? token, JSAny? metadata) {
    onSuccess(token?.dartify()?.toString() ?? '');
  }).toJS;
  config['onExit'] = ((JSAny? err, JSAny? metadata) {
    String? errorCode;
    String? errorMessage;
    if (err != null) {
      final errObj = err as JSObject;
      errorCode = errObj['error_code']?.dartify()?.toString();
      final msg = errObj['display_message'] ?? errObj['error_message'];
      errorMessage = msg?.dartify()?.toString();
    }
    onExit(errorCode, errorMessage);
  }).toJS;

  final plaid = globalThis['Plaid']! as JSObject;
  final handler = plaid.callMethod('create'.toJS, config) as JSObject;
  handler.callMethod('open'.toJS);
}

Future<void> _loadPlaidScript() {
  final completer = Completer<void>();
  final script = html.ScriptElement()
    ..src = 'https://cdn.plaid.com/link/v2/stable/link-initialize.js'
    ..onLoad.listen((_) => completer.complete())
    ..onError.listen((_) => completer.completeError(
          Exception('Failed to load Plaid SDK from CDN'),
        ));
  html.document.head!.append(script);
  return completer.future;
}
