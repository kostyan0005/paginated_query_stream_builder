import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'controller.dart';
import 'default_indicators.dart';

///
abstract class QueryStreamView<T> extends StatelessWidget {
  ///
  final Query<Map<String, dynamic>> initialQuery;

  ///
  final String orderBy;

  ///
  final bool descending;

  ///
  final int pageSize;

  ///
  final bool includeMetadataChanges;

  ///
  final bool allowSnapshotsFromCache;

  ///
  final T Function(Map<String, dynamic>) itemFromJson;

  ///
  final Widget Function(BuildContext, T) itemBuilder;

  ///
  final WidgetBuilder? newPageProgressIndicatorBuilder;

  ///
  final WidgetBuilder? noItemsFoundIndicatorBuilder;

  ///
  final WidgetBuilder? errorIndicatorBuilder;

  ///
  final double minScrollExtentLeft;

  ///
  final bool showDebugLogs;

  final Controller<T> _controller;

  QueryStreamView({
    super.key,
    required this.initialQuery,
    required this.orderBy,
    this.descending = false,
    this.pageSize = 20,
    this.includeMetadataChanges = false,
    this.allowSnapshotsFromCache = true,
    required this.itemFromJson,
    required this.itemBuilder,
    this.newPageProgressIndicatorBuilder,
    this.noItemsFoundIndicatorBuilder,
    this.errorIndicatorBuilder,
    this.minScrollExtentLeft = 500,
    this.showDebugLogs = false,
  }) : _controller = Controller<T>(
          initialQuery: initialQuery,
          orderBy: orderBy,
          descending: descending,
          pageSize: pageSize,
          includeMetadataChanges: includeMetadataChanges,
          allowSnapshotsFromCache: allowSnapshotsFromCache,
          itemFromJson: itemFromJson,
          minScrollExtentLeft: minScrollExtentLeft,
          showDebugLogs: showDebugLogs,
        );

  ///
  Widget getViewBuilder(BoxConstraints constraints);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            if (_controller.isEmpty) {
              return noItemsFoundIndicatorBuilder?.call(context) ??
                  const DefaultNoItemsFoundIndicator();
            } else {
              return getViewBuilder(constraints);
            }
          },
        );
      },
    );
  }

  ///
  ScrollController get scrollController => _controller.scrollController;

  ///
  int get itemCount =>
      _controller.itemCount + (_controller.needsPlusOne ? 1 : 0);

  ///
  double getCacheExtent(BoxConstraints constraints, Axis scrollDirection) {
    final viewportSize = scrollDirection == Axis.vertical
        ? constraints.maxHeight
        : constraints.maxWidth;
    return viewportSize + minScrollExtentLeft * 2;
  }

  ///
  Widget buildItem(context, index) {
    if (index < _controller.itemCount) {
      return itemBuilder(context, _controller.items[index]);
    } else if (_controller.hasError) {
      return errorIndicatorBuilder?.call(context) ??
          const DefaultErrorIndicator();
    } else {
      return newPageProgressIndicatorBuilder?.call(context) ??
          const DefaultNewPageProgressIndicator();
    }
  }
}
