

import 'dart:collection';

import 'package:flutter/foundation.dart';

class ListNotifier<T> extends ValueListenable<List<T>> with ChangeNotifier, ListMixin<T> {
  final List<T> _list = <T>[];

  @override
  set length(int newLength) {
    _list.length = newLength;
    notifyListeners();
  }

  @override
  int get length => _list.length;

  @override
  T operator [](int index) => _list[index];

  @override
  void operator []=(int index, T value) {
    _list[index] = value;
    notifyListeners();
  }

  @override
  void add(T element) {
    _list.add(element);
    notifyListeners();
  }

  @override
  void clear() {
    _list.clear();
    notifyListeners();
  }

  void pushChanges(Function(List<T>) modify) {
    modify.call(_list);
    notifyListeners();
  }

  @override
  List<T> get value => _list;

  set value(List<T> newValue) {
    _list
      ..clear()
      ..addAll(newValue);
    notifyListeners();
  }
}
