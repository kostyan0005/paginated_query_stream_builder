import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'repository.dart';

class Controller<T> extends ChangeNotifier {
  final ScrollController scrollController = ScrollController();
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _pageSubscriptions = [];
  final List<T> items = [];
  final List<String> _itemIds = [];

  final double minScrollExtentLeft;
  final int pageSize;
  final T Function(Map<String, dynamic>) itemFromJson;
  final Repository _repo;

  Controller({
    required this.minScrollExtentLeft,
    required Query<Map<String, dynamic>> initialQuery,
    required String orderBy,
    required bool descending,
    required this.pageSize,
    required this.itemFromJson,
  }) : _repo = Repository(initialQuery, orderBy, descending, pageSize);

  dynamic _startAt;
  bool _isLoading = true;
  bool _isEmpty = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _newItemSubscription;

  double getCacheExtent(BoxConstraints constraints, Axis scrollDirection) {
    final viewportSize = scrollDirection == Axis.vertical
        ? constraints.maxHeight
        : constraints.maxWidth;
    return viewportSize + minScrollExtentLeft * 2;
  }

  void setInitialSubscriptions() async {
    _startAt = await _repo.getInitialOrderByValue();

    if (_startAt == null) {
      _isEmpty = true;
      _isLoading = false;
      notifyListeners();
    } else {
      // todo: subscribe to first old item page
    }

    // todo: subscribe to new items
  }

  void addNextSubscription() {
    // todo: define
  }

  // After the initial portion, check for document changes. If a document gets
  // deleted, remove it from the list, if it gets added, ignore it, as it's
  // already present in some other list anyway (exception: first list with new
  // documents). If it gets updated, update the corresponding list item (if it
  // is present in the corresponding list, otherwise ignore the update).

  // Maintain a separate list with document ids, corresponding to item positions.
  // This is needed so that when you want to search for the particular element
  // after it's updated, you can find its position in the ids list, and then
  // update the item at the corresponding position of the items list.

  // Mark somehow while loading is happening (the period until the initial
  // stream snapshot is received).

  @override
  void dispose() {
    _newItemSubscription?.cancel();
    for (final subscription in _pageSubscriptions) {
      subscription.cancel();
    }
    _pageSubscriptions.clear();
    items.clear();
    _itemIds.clear();
    super.dispose();
  }
}
