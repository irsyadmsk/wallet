import 'dart:js_interop';

@JS('window.addEventListener')
external void _add(JSString type, JSFunction listener);
@JS('window.removeEventListener')
external void _remove(JSString type, JSFunction listener);
extension type _BeforeUnload(JSObject _) implements JSObject {
  external void preventDefault();
  external set returnValue(JSString value);
}
void Function() warnBeforeClosing() {
  final listener = ((JSObject event) {
    final unload = _BeforeUnload(event);
    unload.preventDefault();
    unload.returnValue = ''.toJS;
  }).toJS;
  _add('beforeunload'.toJS, listener);
  return () => _remove('beforeunload'.toJS, listener);
}
