# Riverpod2_persist
Simple tool make your riverpod(v2) provider state auto persist


## Install it
```
flutter pub add riverpod2_persist json_annotation dev:riverpod2_persist_generator dev:json_serializable
```


## Use it
```
import 'package:json_annotation/json_annotation.dart';
import 'package:riverpod2_persist/riverpod2_persist.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'test.g.dart';

@JsonSerializable()
class Auth {
  final int id;
  final String name;

  Auth({required this.id, required this.name});

  factory Auth.fromJson(Map<String, dynamic> json) => _$AuthFromJson(json);

  Map<String, dynamic> toJson() => _$AuthToJson(this);
}

@riverpod
@riverpod2Persist
class AuthController extends _$AuthController
    with _$AuthControllerPersistMixin {
  @override
  FutureOr<List<Auth>> build() async {

    await persist();
    return state.value ?? [];
  }
}

```
1. Just use `@riverpod2Persist` with your `@riverpod` class.
2. Use `await persist()` in your `build` method to enable persist.
3. Your `build` method shoud return `state` or `state.value`(for AsyncValue) (Depends on your type of `state`).
4. Your model (type of `state`) should use `@JsonSerializable` to generate `toJson` an `fromJson`.
