import 'package:collection/collection.dart';

const _deepEquality = DeepCollectionEquality();

/// A single record stored and synced by Offline Relay.
///
/// Records are schemaless: their payload is a `Map<String, Object?>` so the
/// SDK can carry any kind of entity without generated or typed models. Each
/// record also carries the metadata an offline-first store needs to sync it.
///
/// Instances are immutable. [data] is deep-copied on construction, so later
/// changes to the map passed in don't leak into the record, and any attempt
/// to modify [data] (at any nesting level) throws an [UnsupportedError].
///
/// This class is `final`: it cannot be extended, implemented or mixed in
/// outside this library.
final class RelayRecords {
  /// Creates a record.
  ///
  /// Throws an [ArgumentError] if [id] or [collection] is empty, or if
  /// [version] is less than 1. [updatedAt] is stored in UTC.
  factory RelayRecords({
    required String id,
    required String collection,
    required Map<String, Object?> data,
    required DateTime updatedAt,
    int version = 1,
    bool isDeleted = false,
  }) {
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'must not be empty');
    }
    if (collection.isEmpty) {
      throw ArgumentError.value(collection, 'collection', 'must not be empty');
    }
    if (version < 1) {
      throw RangeError.value(version, 'version', 'must be at least 1');
    }

    return RelayRecords._(
      id: id,
      collection: collection,
      data: _freezeMap(data),
      updatedAt: updatedAt.toUtc(),
      version: version,
      isDeleted: isDeleted,
    );
  }

  const RelayRecords._({
    required this.id,
    required this.collection,
    required this.data,
    required this.updatedAt,
    required this.version,
    required this.isDeleted,
  });

  /// Identifier of the record, unique within its [collection].
  final String id;

  /// Name of the collection (table, type) this record belongs to, e.g. `todos`.
  final String collection;

  /// The record's payload, deeply unmodifiable. Null values are preserved.
  final Map<String, Object?> data;

  /// When this record was last changed, always in UTC.
  final DateTime updatedAt;

  /// Revision of this record, starting at 1.
  final int version;

  /// Whether this record is a tombstone, i.e. it has been deleted but is kept
  /// so the deletion can be synced.
  final bool isDeleted;

  /// Returns a copy of this record with the given fields replaced.
  ///
  /// The copy is validated and deep-copied the same way as the constructor.
  RelayRecords copyWith({
    String? id,
    String? collection,
    Map<String, Object?>? data,
    DateTime? updatedAt,
    int? version,
    bool? isDeleted,
  }) {
    return RelayRecords(
      id: id ?? this.id,
      collection: collection ?? this.collection,
      data: data ?? this.data,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayRecords &&
        other.id == id &&
        other.collection == collection &&
        other.updatedAt == updatedAt &&
        other.version == version &&
        other.isDeleted == isDeleted &&
        _deepEquality.equals(other.data, data);
  }

  @override
  int get hashCode => Object.hash(
    id,
    collection,
    updatedAt,
    version,
    isDeleted,
    _deepEquality.hash(data),
  );

  @override
  String toString() =>
      'RelayRecords(id: $id, collection: $collection, '
      'version: $version, isDeleted: $isDeleted, '
      'updatedAt: ${updatedAt.toIso8601String()}, data: $data)';
}

Map<String, Object?> _freezeMap(Map<String, Object?> source) =>
    Map<String, Object?>.unmodifiable(
      source.map((key, value) => MapEntry(key, _freeze(value))),
    );

/// Recursively copies [value], turning maps, lists and sets into
/// unmodifiable collections. Other values are returned as-is.
Object? _freeze(Object? value) {
  return switch (value) {
    Map<String, Object?>() => _freezeMap(value),
    Map() => Map<Object?, Object?>.unmodifiable(
      value.map((key, v) => MapEntry(key, _freeze(v))),
    ),
    List() => List<Object?>.unmodifiable(value.map(_freeze)),
    Set() => Set<Object?>.unmodifiable(value.map(_freeze)),
    _ => value,
  };
}
