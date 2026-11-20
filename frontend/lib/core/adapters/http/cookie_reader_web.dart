import 'package:web/web.dart' as web;

/// The browser's cookie string for this page (only cookies that are not HttpOnly).
String? readDocumentCookies() => web.document.cookie;
