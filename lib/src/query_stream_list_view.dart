import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'controller.dart';

/// todo
///
/// To better understand the purpose of any parameters that are not documented,
/// you can refer to the [ListView.builder] documentation.
class QueryStreamListView<T> extends StatelessWidget {
  final Controller<T> controller;
  final Widget Function(BuildContext, T) itemBuilder;

  // The rest of the fields are passed to
  // [ListView.builder] constructor directly.
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
    required T Function(Map<String, dynamic>) itemFromJson,

    /// todo
    required this.itemBuilder,
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
  }) : controller = Controller<T>(
          minScrollExtentLeft: minScrollExtentLeft,
          initialQuery: initialQuery,
          orderBy: orderBy,
          descending: descending,
          pageSize: pageSize,
          itemFromJson: itemFromJson,
        );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return AnimatedBuilder(
          animation: controller,
          builder: (context, child) {
            return ListView.builder(
              controller: controller.scrollController,
              itemBuilder: (context, index) =>
                  itemBuilder(context, controller.items[index]),
              itemCount: controller.items.length,
              cacheExtent:
                  controller.getCacheExtent(constraints, scrollDirection),
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
}
