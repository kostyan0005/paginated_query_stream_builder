# paginated_query_stream_builder

The purpose of this package is to create a dynamically loading (paginated) list/grid view, the elements of which would be received from a Firestore query and updated automatically when the query results are updated.

(!) The implementation is efficient in a way that each document would be read from Firestore only once (unless it is further updated or deleted).

## Usage

Example `QueryStreamListView` usage:

```dart
QueryStreamListView(
  baseQuery: FirebaseFirestore.instance.collection('items'),
  orderBy: 'date',
  descending: true,
  itemFromJson: (json) => Item(
    text: json['text'] as String,
    date: (json['date'] as Timestamp).toDate(),
  ),
  itemBuilder: (_, Item item) => ListTile(
    title: Text(item.text),
    subtitle: Text(item.date.toString()),
  ),
  showDebugLogs: true,
);
```

`QueryStreamGridView` widget can be used in a similar way.

## Restrictions

- Due to the specifics of package implementation, the field by which the query is ordered should not be modified, otherwise some query items may be lost from the result set.
- Apart from this, updating any other fields of an item and removing items is allowed.
- As for new item additions, they are allowed as long as the item would appear at the beginning of the query. For example, if we order by the `date` field in the descending order, then the new item's `date` should be the **current date**. Setting a date that does not position the item at the beginning of the query may result in loosing some items from the result set.

If the case that is not supported takes place while listening to your query, the appropriate log message will be printed.

If this package helps you in any way, please give it a 👍. This would help bring it to more people.
