import 'package:offline_relay_core/offline_relay_core.dart';
import 'package:test/test.dart';

void main() {
  final updatedAt = DateTime.utc(2026, 11, 14, 10, 30);

  RelayRecords buildRecord({
    String id = 'todo-1',
    String collection = 'todos',
    Map<String, Object?>? data,
    DateTime? at,
    int version = 1,
    bool isDeleted = false,
  }) {
    return RelayRecords(
      id: id,
      collection: collection,
      data:
          data ??
          {
            'title': 'Buy milk',
            'done': false,
            'tags': ['shopping', 'home'],
            'meta': {'priority': 2},
          },
      updatedAt: at ?? updatedAt,
      version: version,
      isDeleted: isDeleted,
    );
  }

  group('construction', () {
    test('sets all fields', () {
      final record = RelayRecords(
        id: 'todo-1',
        collection: 'todos',
        data: {'title': 'Buy milk'},
        updatedAt: updatedAt,
        version: 3,
        isDeleted: true,
      );

      expect(record.id, 'todo-1');
      expect(record.collection, 'todos');
      expect(record.data, {'title': 'Buy milk'});
      expect(record.updatedAt, updatedAt);
      expect(record.version, 3);
      expect(record.isDeleted, isTrue);
    });

    test('defaults version to 1 and isDeleted to false', () {
      final record = RelayRecords(
        id: 'todo-1',
        collection: 'todos',
        data: const {},
        updatedAt: updatedAt,
      );

      expect(record.version, 1);
      expect(record.isDeleted, isFalse);
    });

    test('accepts an empty data map', () {
      final record = buildRecord(data: {});
      expect(record.data, isEmpty);
    });
  });

  group('validation', () {
    test('throws on empty id', () {
      expect(() => buildRecord(id: ''), throwsArgumentError);
    });

    test('throws on empty collection', () {
      expect(() => buildRecord(collection: ''), throwsArgumentError);
    });

    test('throws on version 0', () {
      expect(() => buildRecord(version: 0), throwsArgumentError);
    });

    test('throws on negative version', () {
      expect(() => buildRecord(version: -1), throwsArgumentError);
    });
  });

  group('immutability', () {
    test('is unaffected by later changes to the source map', () {
      final tags = <Object?>['a'];
      final meta = <String, Object?>{'priority': 1};
      final source = <String, Object?>{
        'title': 'original',
        'tags': tags,
        'meta': meta,
      };

      final record = buildRecord(data: source);

      source['title'] = 'changed';
      source['extra'] = true;
      tags.add('b');
      meta['priority'] = 99;

      expect(record.data, {
        'title': 'original',
        'tags': ['a'],
        'meta': {'priority': 1},
      });
    });

    test('rejects top-level writes', () {
      final record = buildRecord();
      expect(() => record.data['title'] = 'x', throwsUnsupportedError);
      expect(() => record.data.remove('title'), throwsUnsupportedError);
      expect(() => record.data.clear(), throwsUnsupportedError);
    });

    test('rejects writes to nested maps', () {
      final record = buildRecord();
      final meta = record.data['meta'] as Map<String, Object?>;
      expect(() => meta['priority'] = 5, throwsUnsupportedError);
    });

    test('rejects writes to nested lists', () {
      final record = buildRecord();
      final tags = record.data['tags'] as List<Object?>;
      expect(() => tags.add('x'), throwsUnsupportedError);
      expect(() => tags[0] = 'x', throwsUnsupportedError);
    });

    test('rejects writes to maps nested inside lists', () {
      final record = buildRecord(
        data: {
          'items': [
            {'qty': 1},
          ],
        },
      );
      final items = record.data['items'] as List<Object?>;
      final first = items.first as Map<String, Object?>;
      expect(() => first['qty'] = 2, throwsUnsupportedError);
    });
  });

  group('null values', () {
    test('are preserved', () {
      final record = buildRecord(data: {'note': null, 'title': 'x'});

      expect(record.data.containsKey('note'), isTrue);
      expect(record.data['note'], isNull);
    });

    test('are preserved inside nested collections', () {
      final record = buildRecord(
        data: {
          'list': [null, 1],
          'map': {'inner': null},
        },
      );

      expect(record.data['list'], [null, 1]);
      expect(record.data['map'], {'inner': null});
    });
  });

  group('updatedAt', () {
    test('is normalized to UTC', () {
      final local = DateTime(2026, 11, 14, 12);
      final record = buildRecord(at: local);

      expect(record.updatedAt.isUtc, isTrue);
      expect(record.updatedAt, local.toUtc());
    });

    test('local and UTC values for the same instant give equal records', () {
      final local = DateTime(2026, 11, 14, 12);

      expect(buildRecord(at: local), buildRecord(at: local.toUtc()));
    });
  });

  group('equality', () {
    test('records with identical fields are equal', () {
      expect(buildRecord(), buildRecord());
    });

    test('equal records have equal hashCodes', () {
      expect(buildRecord().hashCode, buildRecord().hashCode);
    });

    test('compares nested data deeply', () {
      final a = buildRecord(
        data: {
          'meta': {
            'tags': ['x', 'y'],
            'deep': {'n': 1},
          },
        },
      );
      final b = buildRecord(
        data: {
          'meta': {
            'tags': ['x', 'y'],
            'deep': {'n': 1},
          },
        },
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('map key order does not affect equality', () {
      final a = buildRecord(data: {'a': 1, 'b': 2});
      final b = buildRecord(data: {'b': 2, 'a': 1});

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('a missing key is not equal to a null value', () {
      expect(buildRecord(data: {'note': null}), isNot(buildRecord(data: {})));
    });

    test('differs when id differs', () {
      expect(buildRecord(id: 'a'), isNot(buildRecord(id: 'b')));
    });

    test('differs when collection differs', () {
      expect(buildRecord(collection: 'a'), isNot(buildRecord(collection: 'b')));
    });

    test('differs when data differs', () {
      expect(buildRecord(data: {'n': 1}), isNot(buildRecord(data: {'n': 2})));
    });

    test('differs when nested data differs', () {
      expect(
        buildRecord(
          data: {
            'tags': ['a'],
          },
        ),
        isNot(
          buildRecord(
            data: {
              'tags': ['b'],
            },
          ),
        ),
      );
    });

    test('differs when updatedAt differs', () {
      expect(
        buildRecord(at: updatedAt),
        isNot(buildRecord(at: updatedAt.add(const Duration(seconds: 1)))),
      );
    });

    test('differs when version differs', () {
      expect(buildRecord(version: 1), isNot(buildRecord(version: 2)));
    });

    test('differs when isDeleted differs', () {
      expect(
        buildRecord(isDeleted: false),
        isNot(buildRecord(isDeleted: true)),
      );
    });

    test('is not equal to other types', () {
      expect(buildRecord(), isNot('todo-1'));
    });
  });

  group('copyWith', () {
    test('with no arguments returns an equal record', () {
      final record = buildRecord();
      expect(record.copyWith(), record);
    });

    test('changes only the given fields', () {
      final record = buildRecord();
      final later = updatedAt.add(const Duration(minutes: 5));

      final copy = record.copyWith(
        data: {'title': 'Buy oat milk'},
        updatedAt: later,
        version: 2,
        isDeleted: true,
      );

      expect(copy.id, record.id);
      expect(copy.collection, record.collection);
      expect(copy.data, {'title': 'Buy oat milk'});
      expect(copy.updatedAt, later);
      expect(copy.version, 2);
      expect(copy.isDeleted, isTrue);
    });

    test('can change id and collection', () {
      final copy = buildRecord().copyWith(id: 'todo-2', collection: 'notes');

      expect(copy.id, 'todo-2');
      expect(copy.collection, 'notes');
    });

    test('leaves the original untouched', () {
      final record = buildRecord();
      record.copyWith(version: 5, data: {'other': 1});

      expect(record, buildRecord());
    });

    test('re-validates', () {
      final record = buildRecord();

      expect(() => record.copyWith(version: 0), throwsArgumentError);
      expect(() => record.copyWith(id: ''), throwsArgumentError);
      expect(() => record.copyWith(collection: ''), throwsArgumentError);
    });

    test('copies new data defensively', () {
      final source = <String, Object?>{'n': 1};
      final copy = buildRecord().copyWith(data: source);

      source['n'] = 2;

      expect(copy.data, {'n': 1});
      expect(() => copy.data['n'] = 3, throwsUnsupportedError);
    });

    test('normalizes a new updatedAt to UTC', () {
      final copy = buildRecord().copyWith(updatedAt: DateTime(2026, 1, 1));
      expect(copy.updatedAt.isUtc, isTrue);
    });
  });

  test('toString includes id and collection', () {
    final text = buildRecord().toString();

    expect(text, contains('todo-1'));
    expect(text, contains('todos'));
  });
}
