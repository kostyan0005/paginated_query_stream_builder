# paginated_query_stream_builder

The purpose of this package is to create a dynamically loading (paginated) 
list/grid view, the elements of which would be received from a Firestore query
and updated automatically when the query results are updated. The implementation 
is efficient in a way that each element would be read from Firestore only once,
unless it is modified while listening to query updates.

The package is currently in development. Once it is ready and tested, 
it will be published to pub.dev.

## Features

TODO: List what your package can do. Maybe include images, gifs, or videos.

## Getting started

TODO: List prerequisites and provide or point to information on how to
start using the package.

## Usage

TODO: Include short and useful examples for package users. Add longer examples
to `/example` folder.

```dart
const like = 'sample';
```

## Additional information

TODO: Tell users more about the package: where to find more information, how to
contribute to the package, how to file issues, what response they can expect
from the package authors, and more.
