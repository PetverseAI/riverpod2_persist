import 'package:build/build.dart';
import 'package:riverpod2_persist_generator/src/persist_generator.dart';
import 'package:source_gen/source_gen.dart';

Builder riverpod2PersistBuilder(BuilderOptions options) {
  return SharedPartBuilder(
    [PersistGenerator()],
    'persist',
  );
}
