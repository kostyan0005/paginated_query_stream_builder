import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'repository.dart';

///
class Controller<T> extends ChangeNotifier {
  final String orderBy;
  final int pageSize;
  final bool includeMetadataChanges;
  final bool allowSnapshotsFromCache;
  final T Function(Map<String, dynamic>) itemFromJson;
  final double minScrollExtentLeft;

  final Repository _repo;

  Controller({
    required Query<Map<String, dynamic>> initialQuery,
    required this.orderBy,
    required bool descending,
    required this.pageSize,
    required this.includeMetadataChanges,
    required this.allowSnapshotsFromCache,
    required this.itemFromJson,
    required this.minScrollExtentLeft,
  }) : _repo = Repository(initialQuery, orderBy, descending, pageSize) {
    _setInitialSubscriptions();
  }

  final ScrollController scrollController = ScrollController();

  final List<StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>
      _pageSubscriptions = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _newItemSubscription;

  List<T> items = [];
  final List<T> _pageItems = [];
  final List<T> _newItems = [];
  final List<String> _pageItemIds = [];
  final List<String> _newItemIds = [];

  dynamic _startAt;
  bool _isLoading = true;
  bool hasMore = true;
  bool hasError = false;

  int get itemCount => items.length;
  bool get isEmpty => items.isEmpty && !hasMore;
  bool get needsPlusOne => hasMore || hasError;
  bool get _canLoadMore => !_isLoading && hasMore && !hasError;

  ///
  void _setInitialSubscriptions() async {
    _startAt = await _repo.getInitialOrderByValue();

    if (_startAt == null) {
      _notifyEmpty();
    } else {
      _addNextSubscription();
    }

    _addNewItemSubscription();
    scrollController.addListener(_onScrollPositionUpdate);
  }

  ///
  void _addNextSubscription() {
    _isLoading = true;
    bool isInitialSnap = true;

    final nextPageStream = _repo
        .constructQuery(_startAt)
        .snapshots(includeMetadataChanges: includeMetadataChanges);

    final nextPageSubscription = nextPageStream.listen((snap) {
      if (!allowSnapshotsFromCache && snap.metadata.isFromCache) return;

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
          _notify();
        }

        isInitialSnap = false;
      } else {
        for (final change in snap.docChanges) {
          // Ignore this case, as it is not supported.
          if (change.type == DocumentChangeType.added) continue;

          final itemIndex = _pageItemIds.indexOf(change.doc.id);
          // This should not happen if package usage requirements are met.
          if (itemIndex == -1) continue;

          if (change.type == DocumentChangeType.modified) {
            _pageItems[itemIndex] = itemFromJson(change.doc.data()!);
          } else {
            _pageItems.removeAt(itemIndex);
            _pageItemIds.removeAt(itemIndex);
          }
        }
        _notify();
      }
    })
      ..onError(_handleError);

    _pageSubscriptions.add(nextPageSubscription);
  }

  ///
  void _addNewItemSubscription() {
    final newItemStream = _repo
        .constructNewItemQuery(_startAt)
        .snapshots(includeMetadataChanges: includeMetadataChanges);

    _newItemSubscription = newItemStream.listen((snap) {
      if (!allowSnapshotsFromCache && snap.metadata.isFromCache) return;

      for (final change in snap.docChanges) {
        final docId = change.doc.id;

        if (change.type == DocumentChangeType.added) {
          _newItems.insert(0, itemFromJson(change.doc.data()!));
          _newItemIds.insert(0, docId);
          continue;
        }

        final itemIndex = _newItemIds.indexOf(docId);
        // This should not happen if package usage requirements are met.
        if (itemIndex == -1) continue;

        if (change.type == DocumentChangeType.modified) {
          final updatedItem = itemFromJson(change.doc.data()!);
          // The only supported repositioning is to the beginning of the list.
          final shouldReposition = change.oldIndex != change.newIndex &&
              change.newIndex == 0 &&
              itemIndex != 0;

          if (shouldReposition) {
            // Remove the item from the old position and insert it at the
            // beginning of the list.
            _newItems.removeAt(itemIndex);
            _newItemIds.removeAt(itemIndex);
            _newItems.insert(0, updatedItem);
            _newItemIds.insert(0, docId);
          } else {
            _newItems[itemIndex] = updatedItem;
          }
        } else {
          _newItems.removeAt(itemIndex);
          _newItemIds.removeAt(itemIndex);
        }
      }
      _notify();
    })
      ..onError(_handleError);
  }

  ///
  void _onScrollPositionUpdate() {
    if (_canLoadMore &&
        scrollController.position.extentAfter < minScrollExtentLeft) {
      _addNextSubscription();
    }
  }

  ///
  void _notify() {
    items = [..._newItems, ..._pageItems];
    notifyListeners();
  }

  ///
  void _notifyEmpty() {
    hasMore = false;
    _isLoading = false;
    _notify();

    // Remove the listener, as it is not needed anymore.
    scrollController.removeListener(_onScrollPositionUpdate);
  }

  ///
  void _handleError(dynamic e) {
    // Notify that there is an error.
    hasError = true;
    _isLoading = false;
    _notify();

    // Remove the listener, as it is not needed anymore.
    scrollController.removeListener(_onScrollPositionUpdate);

    // Cancel all subscriptions.
    _cancelAllSubscriptions();

    // Log the error to make it visible to the developer.
    Logger()
        .e('An error was thrown by one of the streams', e, StackTrace.current);
  }

  ///
  void _cancelAllSubscriptions() {
    _newItemSubscription?.cancel();
    for (final subscription in _pageSubscriptions) {
      subscription.cancel();
    }
    _pageSubscriptions.clear();
  }

  @override
  void dispose() {
    _cancelAllSubscriptions();
    _pageItems.clear();
    _newItems.clear();
    _pageItemIds.clear();
    _newItemIds.clear();
    scrollController.dispose();
    super.dispose();
  }
}
