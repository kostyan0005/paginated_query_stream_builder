import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'repository.dart';

class Controller<T> extends ValueNotifier<List<T>> {
  late final Repository<T> _repo = Repository(this);
  final List<StreamSubscription<List<T>>> _pageSubscriptions = [];

  final ScrollController scrollController = ScrollController();
  final double minScrollExtentLeft;
  final Query<Map<String, dynamic>> initialQuery;
  final String orderBy;
  final int pageSize;
  final T Function(Map<String, dynamic>) itemFromJson;

  Controller({
    required this.minScrollExtentLeft,
    required this.initialQuery,
    required this.orderBy,
    required this.pageSize,
    required this.itemFromJson,
  }) : super([]);

  double getCacheExtent(BoxConstraints constraints, Axis scrollDirection) {
    final viewportSize = scrollDirection == Axis.vertical
        ? constraints.maxHeight
        : constraints.maxWidth;
    return viewportSize + minScrollExtentLeft * 2;
  }
}
