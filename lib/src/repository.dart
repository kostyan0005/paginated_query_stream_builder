import 'package:cloud_firestore/cloud_firestore.dart';

///
class Repository<T> {
  final Query<Map<String, dynamic>> _initialQuery;
  final String _orderBy;
  final bool _descending;
  final int _pageSize;

  Repository(
    this._initialQuery,
    this._orderBy,
    this._descending,
    this._pageSize,
  );

  ///
  Query<Map<String, dynamic>> get _query =>
      _initialQuery.orderBy(_orderBy, descending: _descending);

  ///
  Future<dynamic> getInitialOrderByValue() async {
    final snap = await _query.limit(1).get();
    return snap.size == 1 ? snap.docs.first.data()[_orderBy] : null;
  }

  ///
  Query<Map<String, dynamic>> constructQuery(
      dynamic startAfter, bool isInitial) {
    assert(startAfter != null);
    return isInitial
        ? _query.startAt([startAfter]).limit(_pageSize)
        : _query.startAfter([startAfter]).limit(_pageSize);
  }

  ///
  Query<Map<String, dynamic>> constructNewItemQuery(dynamic startAfter) {
    return startAfter != null ? _query.endBefore([startAfter]) : _query;
  }
}
