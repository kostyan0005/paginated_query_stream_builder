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
  final bool showDebugLogs;

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
    required this.showDebugLogs,
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

    if (showDebugLogs) {
      final firstOrNext = _pageSubscriptions.isEmpty ? 'first' : 'next';
      Logger().d('Loading the $firstOrNext $pageSize items...');
    }

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

        final nItems = docs.length;
        if (showDebugLogs) Logger().d('$nItems items have been loaded!');

        if (nItems < pageSize) {
          _notifyEmpty();
        } else {
          _startAt = docs.last.data()[orderBy];
          _isLoading = false;
          _notify();
        }

        isInitialSnap = false;
      } else {
        for (final change in snap.docChanges) {
          final docId = change.doc.id;

          // Ignore this case, as it is not supported.
          if (change.type == DocumentChangeType.added) {
            // In case it is a last element of the change list, do not warn
            // the user, as when the item is removed from the current list,
            // the first item from the next query matches the current query.
            if (change != snap.docChanges.last) {
              Logger().w('Unsupported case: item addition operations '
                  'can only happen in the new item query snapshots! '
                  'Item $docId has not been added to the list.');
            }
            continue;
          }

          final isUpdated = change.type == DocumentChangeType.modified;
          final itemIndex = _pageItemIds.indexOf(docId);

          // This should not happen if package usage requirements are met.
          if (itemIndex == -1) {
            Logger().w('Unsupported case: item $docId has not been '
                'found among existing items, so it cannot be '
                '${isUpdated ? 'updated' : 'removed'}!');
            continue;
          }

          if (isUpdated) {
            _pageItems[itemIndex] = itemFromJson(change.doc.data()!);

            if (showDebugLogs) Logger().d('Item $docId has been updated.');
          } else {
            _pageItems.removeAt(itemIndex);
            _pageItemIds.removeAt(itemIndex);

            if (showDebugLogs) Logger().d('Item $docId has been removed.');
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

          if (showDebugLogs) Logger().d('Item $docId has been added.');
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

          if (showDebugLogs) Logger().d('Item $docId has been updated.');
        } else {
          _newItems.removeAt(itemIndex);
          _newItemIds.removeAt(itemIndex);

          if (showDebugLogs) Logger().d('Item $docId has been removed.');
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

    if (showDebugLogs) {
      if (isEmpty) {
        Logger().i('There are no items that satisfy your query.');
      } else {
        Logger().i('All items have been loaded!');
      }
    }
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
        .e('An error was thrown by one of the streams!', e, StackTrace.current);
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
