import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:riverpod_analyzer_utils/riverpod_analyzer_utils.dart';

enum SupportedCreatedType {
  future,
  stream,
  value;

  static SupportedCreatedType from(TypeAnnotation? type) {
    final dartType = type?.type;
    switch (dartType) {
      case != null
          when !dartType.isRaw &&
              (dartType.isDartAsyncFutureOr || dartType.isDartAsyncFuture):
        return SupportedCreatedType.future;
      case != null when !dartType.isRaw && dartType.isDartAsyncStream:
        return SupportedCreatedType.stream;
      case _:
        return SupportedCreatedType.value;
    }
  }
}

abstract class ProviderDeclaration {
  Token get name;
  AnnotatedNode get node;
  ProviderDeclarationElement get providerElement;
}

abstract class GeneratorProviderDeclaration extends ProviderDeclaration {
  @override
  GeneratorProviderDeclarationElement get providerElement;

  String get valueTypeDisplayString => valueTypeNode?.toSource() ?? 'Object?';
  String get exposedTypeDisplayString => exposedTypeNode?.source ?? 'Object?';
  String get createdTypeDisplayString {
    final type = createdTypeNode?.type;

    if (type != null &&
        !type.isRaw &&
        (type.isDartAsyncFuture || type.isDartAsyncFutureOr)) {
      return 'FutureOr<$valueTypeDisplayString>';
    }

    return createdTypeNode?.toSource() ?? 'Object?';
  }

  TypeAnnotation? get valueTypeNode;
  SourcedType? get exposedTypeNode;
  TypeAnnotation? get createdTypeNode;

  SupportedCreatedType get createdType =>
      SupportedCreatedType.from(createdTypeNode);

  final List<RefInvocation> refInvocations = [];
}

class ClassBasedProviderDeclaration extends GeneratorProviderDeclaration {
  ClassBasedProviderDeclaration({
    required this.name,
    required this.node,
    required this.buildMethod,
    required this.providerElement,
    required this.createdTypeNode,
    required this.exposedTypeNode,
    required this.valueTypeNode,
  });

  @override
  final Token name;
  @override
  final ClassDeclaration node;
  @override
  final ClassBasedProviderDeclarationElement providerElement;

  final MethodDeclaration buildMethod;
  @override
  final TypeAnnotation? createdTypeNode;
  @override
  final TypeAnnotation? valueTypeNode;
  @override
  final SourcedType exposedTypeNode;
}

TypeAnnotation? getValueType(TypeAnnotation? createdType) {
  switch (SupportedCreatedType.from(createdType)) {
    case SupportedCreatedType.future:
    case SupportedCreatedType.stream:
      return (createdType! as NamedType).typeArguments?.arguments.firstOrNull;
    case SupportedCreatedType.value:
      return createdType;
  }
}
