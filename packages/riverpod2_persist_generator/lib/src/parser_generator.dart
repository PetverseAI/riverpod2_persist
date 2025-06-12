import 'dart:async';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:build/build.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as p;
import 'package:riverpod_analyzer_utils/riverpod_analyzer_utils.dart'
    hide ClassBasedProviderDeclaration, GeneratorProviderDeclaration;
import 'package:source_gen/source_gen.dart';
import 'provider_declaration.dart';

/// Forked from build_resolvers
String assetPath(AssetId assetId) {
  return p.posix.join('/${assetId.package}', assetId.path);
}

abstract class ParserGenerator<AnnotationT>
    extends GeneratorForAnnotation<AnnotationT> {
  @override
  Future<String> generate(
    LibraryReader library,
    BuildStep buildStep,
  ) async {
    final firstAnnotatedElementFromUniqueSource = <Uri, Element>{};

    for (final annotated in library.annotatedWithExact(
      typeChecker,
      throwOnUnresolved: false,
    )) {
      firstAnnotatedElementFromUniqueSource.putIfAbsent(
        annotated.element.source!.uri,
        () => annotated.element,
      );
    }

    final ast = await Future.wait(
      firstAnnotatedElementFromUniqueSource.values.map(
        (e) => buildStep.resolver
            .astNodeFor(e, resolve: true)
            .then((value) => value as CompilationUnitMember),
      ),
    );

    return generateForUnit(ast);
  }

  FutureOr<String> generateForUnit(
      List<CompilationUnitMember> compilationUnits);

  @override
  Stream<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async* {
    // noop
  }
}

extension GeneratorProviderDeclarationX on Declaration {
  GeneratorProviderDeclaration? get provider {
    final that = this;
    switch (that) {
      case ClassDeclaration():
        return ClassBasedProviderDeclarationX(that).provider;
      case FunctionDeclaration():
        return null;
      default:
        return null;
    }
  }
}

extension ClassBasedProviderDeclarationX on ClassDeclaration {
  static final _cache = Expando<Box<ClassBasedProviderDeclaration?>>();

  ClassBasedProviderDeclaration? get provider {
    return _cache.upsert(this, () {
      final element = declaredElement;
      if (element == null) return null;

      if (abstractKeyword != null) {
        throw UnsupportedError(
          'Classes annotated with @riverpod cannot be abstract.',
        );
      }
      final constructors = members.whereType<ConstructorDeclaration>().toList();
      final defaultConstructor = constructors
          .firstWhereOrNull((constructor) => constructor.name == null);
      if (defaultConstructor == null && constructors.isNotEmpty) {
        throw UnsupportedError(
          'Classes annotated with @riverpod must have a default constructor.',
        );
      }
      if (defaultConstructor != null &&
          defaultConstructor.parameters.parameters.any((e) => e.isRequired)) {
        throw UnsupportedError(
          'The default constructor of classes annotated with @riverpod cannot have required parameters.',
        );
      }

      final buildMethod = members
          .whereType<MethodDeclaration>()
          .firstWhereOrNull((method) => method.name.lexeme == 'build');
      if (buildMethod == null) {
        throw UnsupportedError(
          'No "build" method found. '
          'Classes annotated with @riverpod must define a method named "build".',
        );
      }

      // ignore: invalid_use_of_internal_member
      final providerElement = ClassBasedProviderDeclarationElement.parse(
        element,
        annotation: null,
      );
      if (providerElement == null) return null;

      final createdTypeNode = buildMethod.returnType;

      final exposedTypeNode = _computeExposedType(
        createdTypeNode,
        root.cast<CompilationUnit>()!,
      );
      if (exposedTypeNode == null) {
        // Error already reported
        return null;
      }

      final valueTypeNode = getValueType(createdTypeNode);

      return ClassBasedProviderDeclaration(
        name: name,
        node: this,
        buildMethod: buildMethod,
        providerElement: providerElement,
        createdTypeNode: createdTypeNode,
        exposedTypeNode: exposedTypeNode,
        valueTypeNode: valueTypeNode,
      );
    });
  }
}

class Box<T> {
  Box(this.value);
  final T value;
}

extension ExpandoUtils<R> on Expando<Box<R>> {
  R upsert(
    AstNode key,
    R Function() create,
  ) {
    // Using a record to differentiate "null value" from "no value".
    final existing = this[key];
    if (existing != null) return existing.value;

    final created = create();
    this[key] = Box(created);
    return created;
  }
}

SourcedType? _computeExposedType(
  TypeAnnotation? createdType,
  CompilationUnit unit,
) {
  final library = unit.declaredElement!.library;

  if (createdType == null) {
    return (
      source: null,
      dartType: library.typeProvider.dynamicType,
    );
  }

  final createdDartType = createdType.type!;
  if (createdDartType.isRaw) {
    return (
      source: createdType.toSource(),
      dartType: createdType.type!,
    );
  }

  if (createdDartType.isDartAsyncFuture ||
      createdDartType.isDartAsyncFutureOr ||
      createdDartType.isDartAsyncStream) {
    createdType as NamedType;
    createdDartType as InterfaceType;

    final typeSource = createdType.toSource();
    if (typeSource != 'Future' &&
        typeSource != 'FutureOr' &&
        typeSource != 'Stream' &&
        !typeSource.startsWith('Future<') &&
        !typeSource.startsWith('FutureOr<') &&
        !typeSource.startsWith('Stream<')) {
      throw UnsupportedError(
        'Returning a typedef of type Future/FutureOr/Stream is not supported\n'
        'The code that triggered this error is: $typeSource',
      );
    }

    final valueTypeArg = createdType.typeArguments?.arguments.firstOrNull;

    final exposedDartType = unit.createdTypeToValueType(
      createdDartType.typeArguments.first,
    );
    if (exposedDartType == null) return null;

    return (
      source: valueTypeArg == null ? 'AsyncValue' : 'AsyncValue<$valueTypeArg>',
      dartType: exposedDartType,
    );
  }

  return (
    source: createdType.toSource(),
    dartType: createdType.type!,
  );
}

extension LibraryElementX on CompilationUnit {
  static final _asyncValueCache = Expando<ClassElement>();

  LibraryElement? get _library => declaredElement?.library;

  Element? findElementWithNameFromRiverpod(String name) {
    return _library!.importedLibraries
        .map((e) => e.exportNamespace.get(name))
        .firstWhereOrNull(
          (element) => element != null && isFromRiverpod.isExactly(element),
        );
  }

  ClassElement? findAsyncValue() {
    final cache = _asyncValueCache[this];
    if (cache != null) return cache;

    final result = findElementWithNameFromRiverpod('AsyncValue');
    if (result == null) {
      throw UnsupportedError(
        'No AsyncValue accessible in the library. '
        'Did you forget to import Riverpod?',
      );
    }

    return _asyncValueCache[this] = result as ClassElement?;
  }

  DartType? createdTypeToValueType(DartType? typeArg) {
    final asyncValue = findAsyncValue();

    return asyncValue?.instantiate(
      typeArguments: [if (typeArg != null) typeArg],
      nullabilitySuffix: NullabilitySuffix.none,
    );
  }
}

extension ObjectX<T> on T? {
  R? cast<R>() {
    final that = this;
    if (that is R) return that;
    return null;
  }
}

extension AnnotationOf on Annotation {
  ElementAnnotation? annotationOfType(TypeChecker type, {required bool exact}) {
    final elementAnnotation = this.elementAnnotation;
    final element = this.element;
    if (element == null || elementAnnotation == null) return null;
    if (element is! ExecutableElement) return null;

    if ((exact && !type.isExactlyType(element.returnType)) ||
        (!exact && !type.isAssignableFromType(element.returnType))) {
      return null;
    }

    return elementAnnotation;
  }
}
