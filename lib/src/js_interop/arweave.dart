@JS('Arweave')
library arweave.web;
import 'package:js/js.dart';
import 'dart:async';

import 'json.dart';


@JS()
class init {
  external init();
  //external jwkToAddress(Map options);
  external init get wallets;
  external Promise jwkToAddress(dynamic a);
  
  external Promise arql(dynamic t);

  external init get transactions;
  external Promise sign(dynamic t, dynamic jwk);
  external Promise post(dynamic t);
  external Promise<Transaction> createTransaction(Data d, dynamic jwk);
  external Promise<Transaction> get(String s);
}

@JS()
class Transaction{
  external factory Transaction(Data data);
  external addTag(String k, String v);
  external dynamic get(String k, TxOpts opts);

}


@JS()
@anonymous
class TxOpts {
  external bool get decode;
  external bool get string;

  external factory TxOpts({bool decode, bool string});
}
@JS()
@anonymous
class Data {
  external String get data;

  external factory Data({String data});
}