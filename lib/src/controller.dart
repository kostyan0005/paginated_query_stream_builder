import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'repository.dart';

class Controller<T> extends ChangeNotifier {
  final double minScrollExtentLeft;
  final String orderBy;
  final int pageSize;
  final T Function(Map<String, dynamic>) itemFromJson;
  final Repository _repo;

  Controller({
    required this.minScrollExtentLeft,
    required Query<Map<String, dynamic>> initialQuery,
    required this.orderBy,
    required bool descending,
    required this.pageSize,
    required this.itemFromJson,
  }) : _repo = Repository(initialQuery, orderBy, descending, pageSize) {
    _setInitialSubscriptions();
  }

  final ScrollController scrollController = ScrollController();
  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _pageSubscriptions = [];
  final List<T> _pageItems = [];
  final List<T> _newItems = [];
  final List<String> _pageItemIds = [];
  final List<String> _newItemIds = [];

  dynamic _startAt;
  bool _isLoading = true;
  bool _isEmpty = false;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _newItemSubscription;

  List<T> get items => [..._newItems, ..._pageItems];

  double getCacheExtent(BoxConstraints constraints, Axis scrollDirection) {
    final viewportSize = scrollDirection == Axis.vertical
        ? constraints.maxHeight
        : constraints.maxWidth;
    return viewportSize + minScrollExtentLeft * 2;
  }

  void _notifyEmpty() {
    _isEmpty = true;
    _isLoading = false;
    notifyListeners();
  }

  void _setInitialSubscriptions() async {
    _startAt = await _repo.getInitialOrderByValue();

    if (_startAt == null) {
      _notifyEmpty();
    } else {
      _addNextSubscription();
    }

    _newItemSubscription = _repo
        .constructNewItemQuery(_startAt)
        .snapshots()
        .listen(_listenToNewItemUpdates);
  }

  void _addNextSubscription() {
    _isLoading = true;
    bool isInitialSnap = true;

    final nextPageSubscription =
        _repo.constructQuery(_startAt).snapshots().listen((snap) {
      if (isInitialSnap) {
        final docs = snap.docs;
        final items = docs.map((doc) => itemFromJson(doc.data()));
        _pageItems.addAll(items);
        _pageItemIds.addAll(docs.map((doc) => doc.id));

        if (docs.length < pageSize) {
          _notifyEmpty();
        } else {
          _startAt = docs.last.data()[orderBy];
          _isLoading = false;
          notifyListeners();
        }

        isInitialSnap = false;
      } else {
        for (final change in snap.docChanges) {
          // Ignore this case, as it is not supported.
          if (change.type == DocumentChangeType.added) return;

          final itemIndex = _pageItemIds.indexOf(change.doc.id);
          // This should not happen if the package usage requirements are met.
          if (itemIndex == -1) return;

          if (change.type == DocumentChangeType.modified) {
            _pageItems[itemIndex] = itemFromJson(change.doc.data()!);
          } else {
            _pageItems.removeAt(itemIndex);
            _pageItemIds.removeAt(itemIndex);
          }
          notifyListeners();
        }
      }
    });

    _pageSubscriptions.add(nextPageSubscription);
  }

  void _listenToNewItemUpdates(QuerySnapshot<Map<String, dynamic>> snap) {
    // todo: define
  }

  // Note: the loading indicator will always be displayed (as the last element
  // of the list) until _isEmpty becomes true.

  @override
  void dispose() {
    _newItemSubscription?.cancel();
    for (final subscription in _pageSubscriptions) {
      subscription.cancel();
    }
    _pageSubscriptions.clear();
    _pageItems.clear();
    _newItems.clear();
    _pageItemIds.clear();
    _newItemIds.clear();
    super.dispose();
  }
}
