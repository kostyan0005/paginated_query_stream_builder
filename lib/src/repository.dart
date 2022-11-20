import 'package:cloud_firestore/cloud_firestore.dart';

import 'controller.dart';

class Repository<T> {
  final Query<Map<String, dynamic>> _initialQuery;
  final String _orderBy;
  final int _pageSize;
  final T Function(Map<String, dynamic>) _itemFromJson;

  Repository(Controller<T> controller)
      : _initialQuery = controller.initialQuery,
        _orderBy = controller.orderBy,
        _pageSize = controller.pageSize,
        _itemFromJson = controller.itemFromJson;

  dynamic _startAfter;
  bool isEmpty = false;

  Query<Map<String, dynamic>> _constructQuery() {
    var query = _initialQuery.orderBy(_orderBy).limit(_pageSize);
    if (_startAfter != null) query = query.startAfter([_startAfter]);
    return query;
  }

  Future<void> _getQueryStartingPoint() async {
    final snap = await _constructQuery().limit(1).get();
    if (snap.size == 1) {
      _startAfter = snap.docs.first.data()[_orderBy];
    } else {
      isEmpty = true;
    }
  }

  // Think about how the updated combined list would be constructed when one
  // of the lists gets updated, taking into account that items must be unique.

  // Add a page subscription to the controller.
  // Mark somehow while loading is happening
  // (the period until the initial stream snapshot
  // is received).

  // When the new/updated item portion is received from the subscription,
  // make sure to not include the items that are already present in the list.

  // The objects of type T should be comparable with each other.
  // It should be mentioned in the documentation that the type T should correctly
  // override the equality operator and hashCode getter, or do a similar thing
  // (such as extending the Equitable class).
}
