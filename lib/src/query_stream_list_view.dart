import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'controller.dart';
import 'default_indicators.dart';

// todo: define a parent class with shared params and functionality

/// todo
///
/// To better understand the purpose of any parameters that are not documented,
/// you can refer to the [ListView.builder] documentation.
class QueryStreamListView<T> extends StatelessWidget {
  final Controller<T> _controller;
  final Widget Function(BuildContext, T) itemBuilder;
  final WidgetBuilder? newPageProgressIndicatorBuilder;
  final WidgetBuilder? noItemsFoundIndicatorBuilder;
  final WidgetBuilder? errorIndicatorBuilder;
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final double? itemExtent;
  final Widget? prototypeItem;
  final int? Function(Key)? findChildIndexCallback;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  QueryStreamListView({
    super.key,

    /// todo
    double minScrollExtentLeft = 500,

    /// todo
    required Query<Map<String, dynamic>> initialQuery,

    /// todo
    required String orderBy,

    /// todo
    bool descending = false,

    /// todo
    int pageSize = 20,

    /// todo
    bool includeMetadataChanges = false,

    /// todo
    bool allowSnapshotsFromCache = true,

    /// todo
    required T Function(Map<String, dynamic>) itemFromJson,

    /// todo
    required this.itemBuilder,

    /// todo
    this.newPageProgressIndicatorBuilder,

    /// todo
    this.noItemsFoundIndicatorBuilder,

    /// todo
    this.errorIndicatorBuilder,

    // The rest of the fields are passed to
    // [ListView.builder] constructor directly.
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
    this.itemExtent,
    this.prototypeItem,
    this.findChildIndexCallback,
    this.addAutomaticKeepAlives = true,
    this.addRepaintBoundaries = true,
    this.addSemanticIndexes = true,
    this.semanticChildCount,
    this.dragStartBehavior = DragStartBehavior.start,
    this.keyboardDismissBehavior = ScrollViewKeyboardDismissBehavior.manual,
    this.restorationId,
    this.clipBehavior = Clip.hardEdge,
  }) : _controller = Controller<T>(
          minScrollExtentLeft: minScrollExtentLeft,
          initialQuery: initialQuery,
          orderBy: orderBy,
          descending: descending,
          pageSize: pageSize,
          includeMetadataChanges: includeMetadataChanges,
          allowSnapshotsFromCache: allowSnapshotsFromCache,
          itemFromJson: itemFromJson,
        );

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
            }

            return ListView.builder(
              controller: _controller.scrollController,
              itemBuilder: _buildItem,
              itemCount:
                  _controller.itemCount + (_controller.needsPlusOne ? 1 : 0),
              cacheExtent:
                  _controller.getCacheExtent(constraints, scrollDirection),
              scrollDirection: scrollDirection,
              reverse: reverse,
              primary: primary,
              physics: physics,
              shrinkWrap: shrinkWrap,
              padding: padding,
              itemExtent: itemExtent,
              prototypeItem: prototypeItem,
              findChildIndexCallback: findChildIndexCallback,
              addAutomaticKeepAlives: addAutomaticKeepAlives,
              addRepaintBoundaries: addRepaintBoundaries,
              addSemanticIndexes: addSemanticIndexes,
              semanticChildCount: semanticChildCount,
              dragStartBehavior: dragStartBehavior,
              keyboardDismissBehavior: keyboardDismissBehavior,
              restorationId: restorationId,
              clipBehavior: clipBehavior,
            );
          },
        );
      },
    );
  }

  /// todo
  Widget _buildItem(context, index) {
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
