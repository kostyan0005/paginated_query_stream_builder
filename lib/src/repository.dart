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
  Query<Map<String, dynamic>> constructQuery(dynamic startAt) {
    var query = _initialQuery
        .orderBy(_orderBy, descending: _descending)
        .limit(_pageSize);
    if (startAt != null) query = query.startAt([startAt]);
    return query;
  }

  ///
  Query<Map<String, dynamic>> constructNewItemQuery(dynamic startAt) {
    var query = _initialQuery.orderBy(_orderBy, descending: _descending);
    if (startAt != null) query = query.endBefore([startAt]);
    return query;
  }

  ///
  Future<dynamic> getInitialOrderByValue() async {
    final snap = await constructQuery(null).limit(1).get();
    return snap.size == 1 ? snap.docs.first.data()[_orderBy] : null;
  }
}
