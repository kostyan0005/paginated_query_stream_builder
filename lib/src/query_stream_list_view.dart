import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'query_stream_view.dart';

///
///
/// To better understand the purpose of any parameters that are not documented,
/// you can refer to the [ListView.builder] documentation.
class QueryStreamListView<T> extends QueryStreamView<T> {
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
    required super.initialQuery,
    required super.orderBy,
    super.descending,
    super.pageSize,
    super.includeMetadataChanges,
    super.allowSnapshotsFromCache,
    required super.itemFromJson,
    required super.itemBuilder,
    super.newPageProgressIndicatorBuilder,
    super.noItemsFoundIndicatorBuilder,
    super.errorIndicatorBuilder,
    super.minScrollExtentLeft,
    super.showDebugLogs,
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
  });

  @override
  Widget getViewBuilder(BoxConstraints constraints) {
    return ListView.builder(
      controller: scrollController,
      itemBuilder: buildItem,
      itemCount: itemCount,
      cacheExtent: getCacheExtent(constraints, scrollDirection),
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
  }
}
