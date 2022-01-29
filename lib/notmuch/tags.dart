import 'dart:collection';
import 'dart:ffi';
import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/bindings.dart';
import 'package:ava/notmuch/nm.dart';
import 'package:ffi/ffi.dart';

class TagSet extends Base with SetMixin<String> {
  late Base _parent;

  // ignore: prefer_typing_uninitialized_variables
  var _parentPtrGetterFn;

  // ignore: prefer_typing_uninitialized_variables
  var _tagGetterFn;

  // parent: thread/message
  // parentPtrGetterFn: _thread_p
  // tagGetterFn: notmuch_thread_get_tags
  TagSet(Base parent, parentPtrGetterFn, tagGetterFn) {
    _parent = parent;
    _parentPtrGetterFn = parentPtrGetterFn;
    _tagGetterFn = tagGetterFn;
  }

  @override
  bool get alive => _parent.alive;

  @override
  void destroy() {
    // nothing
  }

  @override
  bool add(String value) {
    var tag = value.toNativeUtf8().cast<Int8>();

    var ret = LibNotmuch.notmuch_message_add_tag(_parentPtrGetterFn(), tag);
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }
    return true;
  }

  @override
  bool contains(Object? element) {
    TagsIterator iterator = this.iterator;

    while (iterator.moveNext()) {
      if (iterator.current == element) {
        return true;
      }
    }
    return false;
  }

  @override
  TagsIterator get iterator {
    var tagsP = _tagGetterFn(_parentPtrGetterFn());

    if (tagsP == nullptr) {
      throw NullPointerError();
    }
    var tags = TagsIterator(this, tagsP);
    return tags;
  }

  @override
  int get length => throw UnimplementedError();

  @override
  String lookup(Object? element) {
    throw UnimplementedError();
  }

  @override
  bool remove(Object? value) {
    var str = value.toString();
    var tag = str.toNativeUtf8().cast<Int8>();
    var ret = LibNotmuch.notmuch_message_remove_tag(_parentPtrGetterFn(), tag);
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      throw NotmuchError(ret);
    }
    return true;
  }

  @override
  Set<String> toSet() {
    throw UnimplementedError();
  }
}

class TagsIterator extends Base implements Iterator<String> {
  // ignore: prefer_typing_uninitialized_variables
  var _parent;

  late MemoryPointer<notmuch_tags_t> tagsPointer;

  late String _current;

  @override
  String get current => _current;

  TagsIterator(parent, tagsP) {
    _parent = parent;
    tagsPointer = MemoryPointer(tagsP);
  }

  @override
  bool get alive {
    if (_parent.alive) {
      return false;
    }
    try {
      tagsPointer.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive) {
      try {
        LibNotmuch.notmuch_tags_destroy(tagsPointer.ptr);
      } on ObjectDestroyedError {
        // nothing
      }
    }
    tagsPointer.ptr = null;
  }

  @override
  bool moveNext() {
    if (LibNotmuch.notmuch_tags_valid(tagsPointer.ptr) != TRUE) {
      destroy();
      return false;
    }
    var tagP = LibNotmuch.notmuch_tags_get(tagsPointer.ptr);
    _current = BinString.fromCffi(tagP);

    LibNotmuch.notmuch_tags_move_to_next(tagsPointer.ptr);

    return true;
  }
}
