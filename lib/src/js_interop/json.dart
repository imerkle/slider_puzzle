@JS()
library js.js;
import 'package:js/js.dart';

// Calls invoke JavaScript `JSON.stringify(obj)`.
@JS("JSON.parse")
external parse(String obj);

@JS()
class Promise<T> {
  external Promise(void executor(void resolve(T result), Function reject));
  external Promise then(void onFulfilled(T result), [Function onRejected]);
}