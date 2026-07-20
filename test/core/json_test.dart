import 'package:dart_resend/src/core/json.dart';
import 'package:test/test.dart';

void main() {
  group('immutableJsonMap', () {
    test('deeply copies and freezes every JSON value type', () {
      final List<Object?> sourceList = <Object?>[
        null,
        'value',
        true,
        1,
        1.5,
        <String, Object?>{'nested': 'value'},
      ];
      final JsonMap source = <String, Object?>{'items': sourceList};

      final JsonMap result = immutableJsonMap(source);
      sourceList.add('later');
      source['later'] = true;

      final List<Object?> items = result['items']! as List<Object?>;
      expect(items, hasLength(6));
      expect(result, isNot(contains('later')));
      expect(() => result['new'] = 'value', throwsUnsupportedError);
      expect(() => items.add('value'), throwsUnsupportedError);
      expect(
        () => (items.last! as JsonMap)['new'] = 'value',
        throwsUnsupportedError,
      );
    });

    test('rejects values that JSON cannot represent', () {
      expect(
        () => immutableJsonMap(<String, Object?>{'value': double.nan}),
        throwsArgumentError,
      );
      expect(
        () => immutableJsonMap(<String, Object?>{
          'value': <Object?, Object?>{1: 'invalid'},
        }),
        throwsArgumentError,
      );
      expect(
        () => immutableJsonMap(<String, Object?>{'value': DateTime(2026)}),
        throwsArgumentError,
      );
    });
  });

  group('JsonMapReader', () {
    final JsonMap values = <String, Object?>{
      'string': 'value',
      'int': 2,
      'num': 2.5,
      'bool': true,
      'map': <String, Object?>{
        'child': <Object?>['value'],
      },
      'list': <Object?>[
        'value',
        <String, Object?>{'child': true},
      ],
      'strings': <Object?>['one', 'two'],
      'date': '2026-07-20T12:30:00Z',
    };

    test('reads required scalar values', () {
      expect(values.requiredString('string'), 'value');
      expect(values.requiredInt('int'), 2);
      expect(values.requiredNum('num'), 2.5);
      expect(values.requiredBool('bool'), isTrue);
    });

    test('reads optional scalar values and nulls', () {
      expect(values.optionalString('string'), 'value');
      expect(values.optionalInt('int'), 2);
      expect(values.optionalNum('num'), 2.5);
      expect(values.optionalBool('bool'), isTrue);

      const JsonMap empty = <String, Object?>{};
      expect(empty.optionalString('value'), isNull);
      expect(empty.optionalInt('value'), isNull);
      expect(empty.optionalNum('value'), isNull);
      expect(empty.optionalBool('value'), isNull);
    });

    test('reports missing, null, and incorrectly typed scalars', () {
      expect(
        () => const <String, Object?>{}.requiredString('missing'),
        throwsFormatException,
      );
      expect(
        () => const <String, Object?>{'value': null}.requiredInt('value'),
        throwsFormatException,
      );
      expect(
        () => const <String, Object?>{'value': 1}.requiredString('value'),
        throwsFormatException,
      );
      expect(
        () => const <String, Object?>{'value': '1'}.optionalInt('value'),
        throwsFormatException,
      );
    });

    test('reads and freezes object values', () {
      final JsonMap required = values.requiredMap('map');
      final JsonMap? optional = values.optionalMap('map');

      expect(required['child'], <Object?>['value']);
      expect(optional, required);
      expect(() => required['new'] = true, throwsUnsupportedError);
      expect(
        () => (required['child']! as List<Object?>).add(true),
        throwsUnsupportedError,
      );
      expect(const <String, Object?>{}.optionalMap('map'), isNull);
      expect(
        () => const <String, Object?>{'map': true}.requiredMap('map'),
        throwsFormatException,
      );
      expect(
        () => const <String, Object?>{'map': true}.optionalMap('map'),
        throwsFormatException,
      );
      expect(
        () => <String, Object?>{
          'map': <Object?, Object?>{1: true},
        }.requiredMap('map'),
        throwsFormatException,
      );
    });

    test('reads and freezes array values', () {
      final List<Object?> required = values.requiredList('list');
      final List<Object?>? optional = values.optionalList('list');

      expect(optional, required);
      expect(() => required.add(true), throwsUnsupportedError);
      expect(
        () => (required.last! as JsonMap)['new'] = true,
        throwsUnsupportedError,
      );
      expect(const <String, Object?>{}.optionalList('list'), isNull);
      expect(
        () => const <String, Object?>{'list': true}.requiredList('list'),
        throwsFormatException,
      );
      expect(
        () => const <String, Object?>{'list': true}.optionalList('list'),
        throwsFormatException,
      );
    });

    test('reads arrays of strings', () {
      expect(values.requiredStringList('strings'), <String>['one', 'two']);
      expect(values.optionalStringList('strings'), <String>['one', 'two']);
      expect(const <String, Object?>{}.optionalStringList('strings'), isNull);
      expect(
        () => const <String, Object?>{
          'strings': <Object?>['one', null],
        }.requiredStringList('strings'),
        throwsFormatException,
      );
    });

    test('reads ISO-8601 timestamps', () {
      expect(
        values.requiredDateTime('date'),
        DateTime.utc(2026, 7, 20, 12, 30),
      );
      expect(
        values.optionalDateTime('date'),
        DateTime.utc(2026, 7, 20, 12, 30),
      );
      expect(const <String, Object?>{}.optionalDateTime('date'), isNull);
      expect(
        () => const <String, Object?>{'date': 'later'}.requiredDateTime('date'),
        throwsFormatException,
      );
    });
  });
}
