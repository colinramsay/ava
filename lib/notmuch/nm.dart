import './bindings.dart';
import 'dart:ffi';

NativeLibrary libNotMuch() {
  final dl = DynamicLibrary.open(
      "/home/colinramsay/projects/ava/notmuch/usr/local/lib/libnotmuch.so");

  return NativeLibrary(dl);
}

// ignore: non_constant_identifier_names
final LibNotmuch = libNotMuch();
