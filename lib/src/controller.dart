import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

import 'query_stream_view.dart';
import 'repository.dart';

/// The controller for the [QueryStreamView].
///
/// It is responsible for loading more items, updating/deleting the existing
/// items and maintaining the correct state of the [QueryStreamView].
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
    _addInitialSubscriptions();
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

  dynamic _startAfter;
  bool _isLoading = true;
  bool hasMore = true;
  bool hasError = false;

  int get itemCount => items.length;
  bool get isEmpty => items.isEmpty && !hasMore;
  bool get needsPlusOne => hasMore || hasError;
  bool get _canLoadMore => !_isLoading && hasMore && !hasError;

  /// Determines the initial controller state and adds the initial subscriptions
  /// and listeners.
  void _addInitialSubscriptions() async {
    _startAfter = await _repo.getStartingOrderByValue();

    if (_startAfter == null) {
      _notifyEmpty();
    } else {
      _addNextSubscription(isInitialQuery: true);
      scrollController.addListener(_onScrollPositionUpdate);
    }

    _addNewItemSubscription();
  }

  /// Adds the subscription for the next portion of items.
  void _addNextSubscription({bool isInitialQuery = false}) {
    _isLoading = true;
    bool isInitialSnap = true;

    if (showDebugLogs) {
      final firstOrNext = _pageSubscriptions.isEmpty ? 'first' : 'next';
      Logger().d('Loading the $firstOrNext $pageSize items...');
    }

    final nextPageStream = _repo
        .constructQuery(_startAfter, isInitialQuery)
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
          _startAfter = docs.last.data()[orderBy];
          _isLoading = false;
          _notify();
        }

        isInitialSnap = false;
      } else {
        for (final change in snap.docChanges) {
          final docId = change.doc.id;

          if (change.type == DocumentChangeType.added) {
            if (change.newIndex == pageSize - 1) {
              // Do not warn about this case, as when the item is removed from
              // the current query result set, the first item from the next
              // query matches the current query and gets added to its result
              // set as the last element.
            } else {
              // Warn about this case, as it is not supported.
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

  /// Adds the subscription for new items.
  void _addNewItemSubscription() {
    final newItemStream = _repo
        .constructNewItemQuery(_startAfter)
        .snapshots(includeMetadataChanges: includeMetadataChanges);

    _newItemSubscription = newItemStream.listen((snap) {
      if (!allowSnapshotsFromCache && snap.metadata.isFromCache) return;

      for (final change in snap.docChanges.reversed) {
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

  /// Determines on each scroll position update whether more items need to be loaded.
  void _onScrollPositionUpdate() {
    if (_canLoadMore &&
        scrollController.position.extentAfter < minScrollExtentLeft) {
      _addNextSubscription();
    }
  }

  /// Notify about the update to the item list.
  void _notify() {
    items = [..._newItems, ..._pageItems];
    notifyListeners();
  }

  /// Notify that either all query items have been loaded or none satisfy the query.
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

  /// Handles the error and notifies the view about it.
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

  /// Cancels all existing subscriptions.
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
