import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'query_stream_view.dart';

/// A grid view that is based on [QueryStreamView].
///
/// To better understand the purpose of any parameters that are not documented,
/// you can refer to the [GridView.builder] documentation.
class QueryStreamGridView<T> extends QueryStreamView<T> {
  final Axis scrollDirection;
  final bool reverse;
  final bool? primary;
  final ScrollPhysics? physics;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final SliverGridDelegate gridDelegate;
  final int? Function(Key)? findChildIndexCallback;
  final bool addAutomaticKeepAlives;
  final bool addRepaintBoundaries;
  final bool addSemanticIndexes;
  final int? semanticChildCount;
  final DragStartBehavior dragStartBehavior;
  final ScrollViewKeyboardDismissBehavior keyboardDismissBehavior;
  final String? restorationId;
  final Clip clipBehavior;

  QueryStreamGridView({
    super.key,
    required super.baseQuery,
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
    required this.gridDelegate,
    this.scrollDirection = Axis.vertical,
    this.reverse = false,
    this.primary,
    this.physics,
    this.shrinkWrap = false,
    this.padding,
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
  Widget buildView(BoxConstraints constraints) {
    return GridView.builder(
      controller: scrollController,
      itemBuilder: buildItem,
      itemCount: itemCount,
      cacheExtent: getCacheExtent(constraints, scrollDirection),
      gridDelegate: gridDelegate,
      scrollDirection: scrollDirection,
      reverse: reverse,
      primary: primary,
      physics: physics,
      shrinkWrap: shrinkWrap,
      padding: padding,
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
