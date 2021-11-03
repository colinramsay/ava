import 'package:ffi/ffi.dart';
import './bindings.dart';
import 'dart:ffi';

NativeLibrary libNotMuch() {
  final dl = DynamicLibrary.open(
      "/home/colinramsay/projects/flutter-test/ava/notmuch/usr/local/lib/libnotmuch.so");

  return NativeLibrary(dl);
}

final LibNotmuch = libNotMuch();

final NotmuchDatabase = NmDb();

class NmDb {
  var openCount = 0;
  Pointer<notmuch_database_t> get db => _database;

  late Pointer<notmuch_database_t> _database;
  bool _open = false;
  final NativeLibrary _nativeNotmuch = libNotMuch();

  NmDb() {
    print("ctor");

    ensureOpen();
  }

  void ensureOpen({msg = ""}) {
    print("open $_open $msg");

    if (_open) {
      print("already open!");
      return;
    }
    openCount = openCount + 1;
    print("opening...");

    final dbPath = '/mnt/data/mail/.notmuch'.toNativeUtf8();
    final configPath =
        '/home/colinramsay/.config/notmuch/default/config'.toNativeUtf8();
    final profile = 'default'.toNativeUtf8();
    Pointer<Pointer<notmuch_database_t>> dbOut = calloc();
    Pointer<Pointer<Int8>> error = calloc();

    final res = _nativeNotmuch.notmuch_database_open_with_config(
        dbPath.cast<Int8>(),
        notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE,
        configPath.cast(),
        profile.cast(),
        dbOut,
        error);

    print("open result: $res $error ${error.cast<Utf8>().toDartString()}");

    _open = true;
    _database = dbOut.value;
    print("opened...");
  }

  void flushChanges() {
    print("flushing");
    close();
    ensureOpen(msg: "flushChanges");
  }

  void close({msg = ""}) {
    print("closing $msg");
    openCount = openCount - 1;

    try {
      _nativeNotmuch.notmuch_database_close(db);
    } finally {
      _open = false;
    }
  }

  void reopen() {
    print("reopen");

    _nativeNotmuch.notmuch_database_reopen(
        db, notmuch_database_mode_t.NOTMUCH_DATABASE_MODE_READ_WRITE);
    _open = true;
  }

  void destroy() {
    print("destroy");

    _nativeNotmuch.notmuch_database_destroy(db);
    _open = false;
  }
}
