import 'package:ffi/ffi.dart';
import './bindings.dart';
import 'dart:ffi';

NativeLibrary libNotMuch() {
  final dl = DynamicLibrary.open(
      "/home/colinramsay/projects/ava/notmuch/usr/local/lib/libnotmuch.so");

  return NativeLibrary(dl);
}

final LibNotmuch = libNotMuch();
