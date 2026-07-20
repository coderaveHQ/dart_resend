import 'package:dart_resend/src/models/base.dart';
import 'package:dart_resend/src/models/request.dart';
import 'package:test/test.dart';

void main() {
  group('ResendModel', () {
    final _TestModel model = _TestModel(<String, Object?>{
      'string': 'value',
      'nullable': null,
      'object': <Object?, Object?>{'nested': true},
      'list': <Object?>['a', 'b'],
      'date': '2026-07-20T12:00:00Z',
    });

    test('reads typed, object, list, and timestamp fields', () {
      expect(model.field<String>('string'), 'value');
      expect(model.optionalField<String>('string'), 'value');
      expect(model.optionalField<String>('nullable'), isNull);
      expect(model.objectField('object'), <String, Object?>{'nested': true});
      expect(model.optionalObjectField('object'), isNotNull);
      expect(model.optionalObjectField('nullable'), isNull);
      expect(model.listField<String>('list'), <String>['a', 'b']);
      expect(model.optionalListField<String>('list'), <String>['a', 'b']);
      expect(model.optionalListField<String>('nullable'), isNull);
      expect(model.dateTimeField('date'), DateTime.utc(2026, 7, 20, 12));
      expect(
        model.optionalDateTimeField('date'),
        DateTime.utc(2026, 7, 20, 12),
      );
      expect(model.optionalDateTimeField('nullable'), isNull);
      expect(model.toString(), contains('_TestModel'));
      expect(() => model.json['new'] = true, throwsUnsupportedError);
    });

    test('reports malformed fields with context', () {
      expect(() => model.field<int>('string'), throwsFormatException);
      expect(() => model.optionalField<int>('string'), throwsFormatException);
      expect(
        () => _TestModel(<String, Object?>{'value': 1}).objectField('value'),
        throwsFormatException,
      );
      expect(
        () => _TestModel(<String, Object?>{
          'value': 1,
        }).optionalObjectField('value'),
        throwsFormatException,
      );
      expect(
        () => _TestModel(<String, Object?>{
          'value': 1,
        }).listField<Object?>('value'),
        throwsFormatException,
      );
      expect(
        () => _TestModel(<String, Object?>{
          'value': <Object?>[1],
        }).listField<String>('value'),
        throwsFormatException,
      );
      expect(
        () => _TestModel(<String, Object?>{
          'value': <Object?, Object?>{1: 'bad'},
        }).objectField('value'),
        throwsArgumentError,
      );
    });
  });

  test('standard ID and deletion responses expose optional metadata', () {
    final ResendId id = ResendId.fromJson(<String, Object?>{
      'id': 'id_1',
      'object': 'email',
    });
    expect(id.id, 'id_1');
    expect(id.object, 'email');
    expect(ResendId.fromJson(<String, Object?>{'id': 'id_2'}).object, isNull);

    final ResendDeletion deletion = ResendDeletion.fromJson(<String, Object?>{
      'id': 'id_1',
      'object': 'email',
      'deleted': true,
    });
    expect(deletion.id, 'id_1');
    expect(deletion.object, 'email');
    expect(deletion.deleted, isTrue);
    final ResendDeletion empty = ResendDeletion.fromJson(<String, Object?>{});
    expect(empty.id, isNull);
    expect(empty.object, isNull);
    expect(empty.deleted, isNull);
  });

  test('page and collection decode typed immutable data', () {
    final ResendPage<ResendId> page = ResendPage<ResendId>.fromJson(
      <String, Object?>{
        'object': 'list',
        'has_more': true,
        'data': <Object?>[
          <String, Object?>{'id': 'one'},
        ],
      },
      ResendId.fromJson,
    );
    expect(page.object, 'list');
    expect(page.hasMore, isTrue);
    expect(page.data.single.id, 'one');
    expect(
      () => page.data.add(ResendId.fromJson(<String, Object?>{'id': 'x'})),
      throwsUnsupportedError,
    );

    final ResendPage<ResendId> defaults = ResendPage<ResendId>.fromJson(
      <String, Object?>{'data': <Object?>[]},
      ResendId.fromJson,
    );
    expect(defaults.object, 'list');
    expect(defaults.hasMore, isFalse);

    final ResendCollection<ResendId> collection =
        ResendCollection<ResendId>.fromJson(<String, Object?>{
          'data': <Object?>[
            <String, Object?>{'id': 'two'},
          ],
        }, ResendId.fromJson);
    expect(collection.data.single.id, 'two');
    expect(
      () => ResendPage<ResendId>.fromJson(<String, Object?>{
        'data': <Object?>[1],
      }, ResendId.fromJson),
      throwsFormatException,
    );
  });

  group('request helpers', () {
    test('compactJson omits null and keeps false', () {
      expect(
        compactJson(<String, Object?>{'null': null, 'false': false}),
        <String, Object?>{'false': false},
      );
    });

    test('validates non-blank strings and non-empty immutable lists', () {
      expect(requireNonBlank(' value ', 'name'), ' value ');
      expect(() => requireNonBlank(' ', 'name'), throwsArgumentError);
      final List<int> values = requireNonEmpty<int>(<int>[1], 'values');
      expect(values, <int>[1]);
      expect(() => values.add(2), throwsUnsupportedError);
      expect(
        () => requireNonEmpty<int>(<int>[], 'values'),
        throwsArgumentError,
      );
      expect(const _WireValue().value, 'wire');
    });
  });
}

final class _TestModel extends ResendModel {
  _TestModel(super.json);
}

final class _WireValue implements ResendWireValue {
  const _WireValue();

  @override
  String get value => 'wire';
}
