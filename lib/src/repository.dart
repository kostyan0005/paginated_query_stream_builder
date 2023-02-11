import 'package:cloud_firestore/cloud_firestore.dart';

/// The repository responsible for constructing queries.
class Repository<T> {
  final Query<Map<String, dynamic>> _baseQuery;
  final String _orderBy;
  final bool _descending;
  final int _pageSize;

  Repository(
    this._baseQuery,
    this._orderBy,
    this._descending,
    this._pageSize,
  );

  /// The query with which the items are extracted.
  Query<Map<String, dynamic>> get _query =>
      _baseQuery.orderBy(_orderBy, descending: _descending);

  /// Gets the starting value of the field by which the ordering happens.
  Future<dynamic> getStartingOrderByValue() async {
    final snap = await _query.limit(1).get();
    return snap.size == 1 ? snap.docs.first.data()[_orderBy] : null;
  }

  /// Constructs a query that starts after the [startAfter] value relative to
  /// the order of the query.
  Query<Map<String, dynamic>> constructQuery(
      dynamic startAfter, bool isInitial) {
    assert(startAfter != null);
    return isInitial
        ? _query.startAt([startAfter]).limit(_pageSize)
        : _query.startAfter([startAfter]).limit(_pageSize);
  }

  /// Constructs a new-item query that ends before the [endBefore] value
  /// relative to the order of the query.
  Query<Map<String, dynamic>> constructNewItemQuery(dynamic endBefore) {
    return endBefore != null ? _query.endBefore([endBefore]) : _query;
  }
}
