import 'package:resolveit/core/adapters/http/cookie_reader_stub.dart'
    if (dart.library.js_interop) 'package:resolveit/core/adapters/http/cookie_reader_web.dart';

/// Where the XSRF token comes from (the `XSRF-TOKEN` cookie set by the backend).
abstract interface class CsrfTokenSource {
  String? read();
}

/// Reads the `XSRF-TOKEN` cookie from the browser. Returns null outside a browser.
final class BrowserCsrfTokenSource implements CsrfTokenSource {
  const BrowserCsrfTokenSource();

  static const cookieName = 'XSRF-TOKEN';

  @override
  String? read() => cookieValue(readDocumentCookies(), cookieName);
}

/// Returns the value of cookie [name] from a `document.cookie` string, or null if absent or empty.
String? cookieValue(String? cookieHeader, String name) {
  if (cookieHeader == null || cookieHeader.isEmpty) return null;
  for (final part in cookieHeader.split(';')) {
    final separator = part.indexOf('=');
    if (separator < 0) continue;
    if (part.substring(0, separator).trim() != name) continue;
    final value = Uri.decodeComponent(part.substring(separator + 1).trim());
    return value.isEmpty ? null : value;
  }
  return null;
}
