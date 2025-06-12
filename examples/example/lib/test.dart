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

    await persist(); // ✅ 调用生成的 persist 方法
    return state.value ?? [];
  }
}
