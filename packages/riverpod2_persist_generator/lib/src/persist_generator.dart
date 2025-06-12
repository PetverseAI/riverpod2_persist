import 'package:analyzer/dart/ast/ast.dart';
import 'package:riverpod2_persist_annotation/riverpod2_persist_annotation.dart';

import 'parser_generator.dart';
import 'provider_declaration.dart';
import 'templates/persist_mixin.dart';

class PersistGenerator extends ParserGenerator<Riverpod2Persist> {
  @override
  FutureOr<String> generateForUnit(
      List<CompilationUnitMember> compilationUnits) {
    final buffer = StringBuffer();

    for (final unit in compilationUnits) {
      if (unit is! ClassDeclaration) {
        throw UnsupportedError(
          'Only classes annotated with @riverpod2Persist are supported.',
        );
      }

      final provider = unit.provider;

      if (provider is! ClassBasedProviderDeclaration) {
        // Noop, we only care about class persisted notifiers
        continue;
      }

      final hasAnnotation = provider.node.metadata.any(
        (e) => e.annotationOfType(typeChecker, exact: true) != null,
      );
      // Not annotated by @riverpod2Persist
      if (!hasAnnotation) continue;

      PersistMixinTemplate(provider: provider).run(buffer);
    }

    return buffer.toString();
  }
}
