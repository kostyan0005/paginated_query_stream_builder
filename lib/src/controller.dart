import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class Controller<T> extends ValueNotifier<List<T>> {
  final ScrollController scrollController = ScrollController();
  final Query<T> initialQuery;
  final String orderBy;
  final int pageSize;
  final double minScrollExtentLeft;

  Controller({
    required this.initialQuery,
    required this.orderBy,
    required this.pageSize,
    required this.minScrollExtentLeft,
  }) : super([]);

  double getCacheExtent(BoxConstraints constraints, Axis scrollDirection) {
    final viewportSize = scrollDirection == Axis.vertical
        ? constraints.maxHeight
        : constraints.maxWidth;
    return viewportSize + minScrollExtentLeft * 2;
  }
}
