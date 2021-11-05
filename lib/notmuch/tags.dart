import 'dart:collection';
import 'dart:ffi';
import 'package:ava/notmuch/base.dart';
import 'package:ava/notmuch/bindings.dart';
import 'package:ava/notmuch/nm.dart';
import 'package:ffi/src/utf8.dart';

class TagSet extends Base with SetMixin<String> {
  var _parent;

  var _parentPtrGetterFn;

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
  bool contains(Object? tag) {
    TagsIterator iterator = this.iterator;

    while (iterator.moveNext()) {
      if (iterator.current == tag) {
        return true;
      }
    }
    return false;
  }

  @override
  TagsIterator get iterator {
    var tags_p = _tagGetterFn(_parentPtrGetterFn());

    if (tags_p == nullptr) {
      throw NullPointerError();
    }
    var tags = TagsIterator(this, tags_p);
    return tags;
  }

  @override
  // TODO: implement length
  int get length => throw UnimplementedError();

  @override
  String lookup(Object? element) {
    // TODO: implement lookup
    throw UnimplementedError();
  }

  @override
  bool remove(Object? value) {
    var str = value.toString();
    var tag = str.toNativeUtf8().cast<Int8>();
    var ret = LibNotmuch.notmuch_message_remove_tag(_parentPtrGetterFn(), tag);
    if (ret != notmuch_status_t.NOTMUCH_STATUS_SUCCESS) {
      print("Return value when trying to remove tag: $ret");
      throw NotmuchError(ret);
    }
    return true;
  }

  @override
  Set<String> toSet() {
    // TODO: implement toSet
    throw UnimplementedError();
  }
}

class TagsIterator extends Base implements Iterator<String> {
  var _parent;

  late MemoryPointer<notmuch_tags_t> _tags_p;

  late String _current;

  String get current => _current;

  TagsIterator(parent, tags_p) {
    _parent = parent;
    _tags_p = MemoryPointer(tags_p);
  }

  @override
  bool get alive {
    if (_parent.alive) {
      return false;
    }
    try {
      _tags_p.ptr;
    } on ObjectDestroyedError {
      return false;
    }
    return true;
  }

  @override
  void destroy() {
    if (alive) {
      try {
        LibNotmuch.notmuch_tags_destroy(_tags_p.ptr);
      } on ObjectDestroyedError {
        // nothing
      }
    }
    _tags_p.ptr = null;
  }

  @override
  bool moveNext() {
    if (LibNotmuch.notmuch_tags_valid(_tags_p.ptr) != TRUE) {
      destroy();
      return false;
    }
    var tag_p = LibNotmuch.notmuch_tags_get(_tags_p.ptr);
    _current = BinString.fromCffi(tag_p);

    LibNotmuch.notmuch_tags_move_to_next(_tags_p.ptr);

    return true;
  }
}
