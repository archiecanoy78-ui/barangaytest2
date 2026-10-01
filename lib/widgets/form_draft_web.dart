import 'dart:js_interop';
import 'package:web/web.dart' as web;

web.EventListener? _listener;

void setupBeforeUnload(bool Function() hasUnsavedChanges) {
  _listener = ((web.Event event) {
    if (hasUnsavedChanges()) {
      event.preventDefault();
    }
  }).toJS as web.EventListener;
  web.window.addEventListener('beforeunload', _listener);
}

void removeBeforeUnload() {
  if (_listener != null) {
    web.window.removeEventListener('beforeunload', _listener);
  }
}
