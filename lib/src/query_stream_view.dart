import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'controller.dart';
import 'default_indicators.dart';

/// An abstract view that is constructed based on query stream items.
abstract class QueryStreamView<T> extends StatelessWidget {
  /// The query with which the items are extracted.
  final Query<Map<String, dynamic>> baseQuery;

  /// The name of the field by which to order the [baseQuery].
  final String orderBy;

  /// Whether the sort order for the [orderBy] field is descending.
  final bool descending;

  /// The size of the item portion loaded initially and when more is needed.
  final int pageSize;

  /// Whether query metadata changes can produce an additional snapshot.
  final bool includeMetadataChanges;

  /// Whether to allow query snapshots that come from cache.
  final bool allowSnapshotsFromCache;

  /// The converter from a query document json to an item used in [itemBuilder].
  final T Function(Map<String, dynamic>) itemFromJson;

  /// The builder for the provided item.
  final Widget Function(BuildContext, T) itemBuilder;

  /// The builder for a new page's progress indicator.
  final WidgetBuilder? newPageProgressIndicatorBuilder;

  /// The builder for a no items found indicator.
  final WidgetBuilder? noItemsFoundIndicatorBuilder;

  /// The builder for a new page's error indicator.
  final WidgetBuilder? errorIndicatorBuilder;

  /// The minimum scroll extent that needs to be available below the current
  /// viewport in order to not trigger loading more items.
  final double minScrollExtentLeft;

  /// Whether to show debug logs.
  final bool showDebugLogs;

  final Controller<T> _controller;

  QueryStreamView({
    super.key,
    required this.baseQuery,
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
          baseQuery: baseQuery,
          orderBy: orderBy,
          descending: descending,
          pageSize: pageSize,
          includeMetadataChanges: includeMetadataChanges,
          allowSnapshotsFromCache: allowSnapshotsFromCache,
          itemFromJson: itemFromJson,
          minScrollExtentLeft: minScrollExtentLeft,
          showDebugLogs: showDebugLogs,
        );

  /// Builds the view based on certain [constraints].
  Widget buildView(BoxConstraints constraints);

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
              return buildView(constraints);
            }
          },
        );
      },
    );
  }

  ScrollController get scrollController => _controller.scrollController;

  /// The count of currently loaded items.
  ///
  /// It may incremented by one if some additional widget needs to be displayed
  /// at the bottom of this view.
  int get itemCount =>
      _controller.itemCount + (_controller.needsPlusOne ? 1 : 0);

  /// Get the full cache extent for this view.
  double getCacheExtent(BoxConstraints constraints, Axis scrollDirection) {
    final viewportSize = scrollDirection == Axis.vertical
        ? constraints.maxHeight
        : constraints.maxWidth;
    return viewportSize + minScrollExtentLeft * 2;
  }

  /// Builds an item based on its [index].
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
