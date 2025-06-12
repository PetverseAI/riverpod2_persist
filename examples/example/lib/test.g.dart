// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'test.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Auth _$AuthFromJson(Map<String, dynamic> json) => Auth(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
    );

Map<String, dynamic> _$AuthToJson(Auth instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
    };

// **************************************************************************
// PersistGenerator
// **************************************************************************

mixin _$AuthControllerPersistMixin on _$AuthController {
  bool _isFirstBuild = true;

  final providerStorageKey = 'AuthControllerStorage';

  FutureOr<void> persist({
    String Function(List<Auth> state)? encode,
    List<Auth> Function(String encoded)? decode,
  }) {
    return _persist(
      encode: encode ??
          (_) => $riverpod2PersistJsonCodex.encode(state.requireValue),
      decode: decode ??
          (encoded) {
            final e = $riverpod2PersistJsonCodex.decode(encoded);
            return (e as List)
                .map((e) => Auth.fromJson(e as Map<String, Object?>))
                .toList();
          },
    );
  }

  FutureOr<void> _persist({
    required String Function(List<Auth> state) encode,
    required List<Auth> Function(String encoded) decode,
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
        switch (state) {
          case AsyncLoading():
            return null;
          case AsyncError():
            return null;
          case AsyncData(:final value):
            return storage.write(encode(value));
        }
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
        state = AsyncData(decoded);
      } catch (err, _) {
        // Don't block the provider if decoding failed
      } finally {
        _isFirstBuild = false;
      }
    }
  }
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$authControllerHash() => r'40f857a0d673e88cd72d74ad667c9e4819c71cdd';

/// See also [AuthController].
@ProviderFor(AuthController)
final authControllerProvider =
    AutoDisposeAsyncNotifierProvider<AuthController, List<Auth>>.internal(
  AuthController.new,
  name: r'authControllerProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authControllerHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthController = AutoDisposeAsyncNotifier<List<Auth>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
