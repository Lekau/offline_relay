# offline_relay_core

Core primitives for the Offline Relay offline-first SDK.

## RelayRecords

A single schemaless record: its payload is a `Map<String, Object?>`, with
sync metadata alongside it.

```dart
final record = RelayRecords(
  id: 'todo-1',
  collection: 'todos',
  data: {'title': 'Buy milk', 'done': false},
  updatedAt: DateTime.now(),
);

final edited = record.copyWith(
  data: {...record.data, 'done': true},
  updatedAt: DateTime.now(),
  version: record.version + 1,
);
```

- `final class`: it cannot be extended or implemented outside the package.
- Deeply immutable: `data` is copied on construction, and nested maps, lists
  and sets are unmodifiable.
- `updatedAt` is stored in UTC.
- `isDeleted` marks a tombstone, so a deletion can still be synced.
- Equality compares `data` deeply.
