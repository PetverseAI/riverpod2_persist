import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:riverpod2_persist_generator/src/models/string.dart';

import '../provider_declaration.dart';
import 'template.dart';

class PersistMixinTemplate extends Template {
  final ClassBasedProviderDeclaration provider;

  PersistMixinTemplate({required this.provider});

  @override
  void run(StringBuffer buffer) {
    if (provider.node.typeParameters?.typeParameters.isNotEmpty ?? false) {
      throw UnsupportedError(
        'Encoding generic notifiers is currently not supported',
      );
    }

    final baseClass = provider.name.lexeme.public;
    final notifierClass = '_\$${provider.name.lexeme.public}';
    final mixinClass = '_\$${provider.name.lexeme.public}PersistMixin';
    final providerStorageKey = '${baseClass}Storage';
    final valueTypeDisplayString = provider.valueTypeDisplayString;

    final valueString = switch (provider.createdType) {
      SupportedCreatedType.future ||
      SupportedCreatedType.stream =>
        'state.requireValue',
      SupportedCreatedType.value => 'state',
    };

    final toStateString = switch (provider.createdType) {
      SupportedCreatedType.future ||
      SupportedCreatedType.stream =>
        'AsyncData(decoded)',
      SupportedCreatedType.value => 'decoded',
    };

    final fromStateString = switch (provider.createdType) {
      SupportedCreatedType.future || SupportedCreatedType.stream => '''
        switch (state) {
          case AsyncLoading():
            return null;
          case AsyncError():
            return null;
          case AsyncData(:final value):
            return storage.write(encode(value));
        }
        ''',
      SupportedCreatedType.value => 'storage.write(encode(state))',
    };

    String decode(DartType type, String name) {
      var result = type.switchPrimitiveType(
        boolean: () => '$name as bool',
        integer: () => '$name as int',
        double: () => '$name as double',
        number: () => '$name as num',
        string: () => '$name as String',
        array: (item) {
          return '($name as List).map((e) => ${decode(item, 'e')}).toList()';
        },
        set: (item) {
          return '($name as List).map((e) => ${decode(item, 'e')}).toSet()';
        },
        map: (key, value) {
          return '($name as Map).map((k, v) => MapEntry(${decode(key, 'k')}, ${decode(value, 'v')}))';
        },
        object: () {
          return '${type.getDisplayString()}.fromJson($name as Map<String, Object?>)';
        },
      );

      if (type.nullabilitySuffix == NullabilitySuffix.question) {
        result = '$name == null ? null : $result';
      }

      return result;
    }

    final decoded = decode(provider.valueTypeNode!.type!, 'e');

    buffer.writeln('''
mixin $mixinClass on $notifierClass {
  bool _isFirstBuild = true;

  final providerStorageKey = '$providerStorageKey';

  FutureOr<void> persist({
    String Function(${provider.valueTypeDisplayString} state)? encode,
    ${provider.valueTypeDisplayString} Function(String encoded)? decode,
  }) {
    return _persist(
      encode: encode ?? (_) => \$riverpod2PersistJsonCodex.encode($valueString),
      decode: decode ?? (encoded) {
        final e = \$riverpod2PersistJsonCodex.decode(encoded);
        return $decoded;
      },
    );
  }

  FutureOr<void> _persist({
    required String Function($valueTypeDisplayString state) encode,
    required $valueTypeDisplayString Function(String encoded) decode,
  }) async {
    ref.onDispose(() {
      _isFirstBuild = true;
    });

    final storage = await Riverpod2PersistStorage.init(providerStorageKey);

    var didChange = false;
    listenSelf((_, __) async {
      didChange = true;

      try {
        // Frequent here, maybe we can use `compute` or `Cancelable Isolate Queue` to encode after data size > 100KB
        $fromStateString
      } catch (e) {
      } finally {
        didChange = false;
      }
    });

    if (_isFirstBuild) {
      try {
        // Let's read the Database
        final value = storage.read();
        // The state was initialized during the decoding, abort
        if (didChange) return null;
        // Nothing to decode
        if (value.isEmpty) return null;

        final decoded = decode(value);
        state = $toStateString;
      } catch (err, _) {
        // Don't block the provider if decoding failed
      } finally {
        _isFirstBuild = false;
      }
    }
  }
}
''');
  }
}

extension on DartType {
  R switchPrimitiveType<R>({
    required R Function() boolean,
    required R Function() integer,
    required R Function() double,
    required R Function() number,
    required R Function() string,
    required R Function(DartType item) array,
    required R Function(DartType item) set,
    required R Function(DartType key, DartType value) map,
    required R Function() object,
  }) {
    if (isDartCoreBool) {
      return boolean();
    } else if (isDartCoreInt) {
      return integer();
    } else if (isDartCoreDouble) {
      return double();
    } else if (isDartCoreNum) {
      return number();
    } else if (isDartCoreString) {
      return string();
    } else if (isDartCoreSet) {
      return set(typeArguments!.single);
    } else if (isDartCoreList) {
      return array(typeArguments!.single);
    } else if (isDartCoreMap) {
      final typeArgs = typeArguments!;
      return map(typeArgs[0], typeArgs[1]);
    } else {
      return object();
    }
  }

  List<DartType>? get typeArguments {
    final that = this;
    if (that is InterfaceType) {
      return that.typeArguments;
    }
    return null;
  }
}
