part of '../riverpod_ast.dart';

class LegacyProviderDependencies extends RiverpodAst {
  LegacyProviderDependencies._({
    required this.dependencies,
    required this.dependenciesNode,
  });

  static LegacyProviderDependencies? parse(NamedExpression? dependenciesNode) {
    if (dependenciesNode == null) return null;

    final value = dependenciesNode.expression;

    List<LegacyProviderDependency>? dependencies;
    if (value is ListLiteral) {
      dependencies =
          value.elements.map(LegacyProviderDependency.parse).toList();
    }

    return LegacyProviderDependencies._(
      dependenciesNode: dependenciesNode,
      dependencies: dependencies,
    );
  }

  final List<LegacyProviderDependency>? dependencies;
  final NamedExpression dependenciesNode;

  @override
  void accept(RiverpodAstVisitor visitor) {
    visitor.visitLegacyProviderDependencies(this);
  }

  @override
  void visitChildren(RiverpodAstVisitor visitor) {
    final dependencies = this.dependencies;
    if (dependencies != null) {
      for (final dependency in dependencies) {
        dependency.accept(visitor);
      }
    }
  }
}

class LegacyProviderDependency extends RiverpodAst
    implements ProviderListenableExpressionParent {
  LegacyProviderDependency._({
    required this.node,
    required this.provider,
  });

  @internal
  factory LegacyProviderDependency.parse(CollectionElement node) {
    final provider =
        node.cast<Expression>().let(ProviderListenableExpression.parse);

    return LegacyProviderDependency._(
      node: node,
      provider: provider,
    );
  }

  final CollectionElement node;
  final ProviderListenableExpression? provider;

  @override
  void accept(RiverpodAstVisitor visitor) {
    visitor.visitLegacyProviderDependency(this);
  }

  @override
  void visitChildren(RiverpodAstVisitor visitor) {
    provider?.accept(visitor);
  }
}

class LegacyProviderDeclaration extends RiverpodAst
    implements ProviderDeclaration {
  LegacyProviderDeclaration._({
    required this.name,
    required this.node,
    required this.build,
    required this.typeArguments,
    required this.providerElement,
    required this.argumentList,
    required this.provider,
    required this.autoDisposeModifier,
    required this.familyModifier,
    required this.dependencies,
  });

  @internal
  static LegacyProviderDeclaration? parse(
    VariableDeclaration node,
  ) {
    final element = node.declaredElement;
    if (element == null) return null;

    final providerElement = LegacyProviderDeclarationElement.parse(element);
    if (providerElement == null) return null;

    final initializer = node.initializer;
    ArgumentList? arguments;
    late Identifier provider;
    SimpleIdentifier? autoDisposeModifier;
    SimpleIdentifier? familyModifier;
    TypeArgumentList? typeArguments;
    if (initializer is InstanceCreationExpression) {
      // Provider((ref) => ...)

      arguments = initializer.argumentList;
      provider = initializer.constructorName.type.name;
      typeArguments = initializer.constructorName.type.typeArguments;
    } else if (initializer is FunctionExpressionInvocation) {
      // Provider.modifier()

      void decodeIdentifier(SimpleIdentifier identifier) {
        switch (identifier.name) {
          case 'autoDispose':
            autoDisposeModifier = identifier;
            break;
          case 'family':
            familyModifier = identifier;
            break;
          default:
            provider = identifier;
        }
      }

      void decodeTarget(Expression? expression) {
        if (expression is SimpleIdentifier) {
          decodeIdentifier(expression);
        } else if (expression is PrefixedIdentifier) {
          decodeIdentifier(expression.identifier);
          decodeIdentifier(expression.prefix);
        } else {
          throw UnsupportedError(
            'unknown expression "$expression" (${expression.runtimeType})',
          );
        }
      }

      final modifier = initializer.function as PropertyAccess;

      decodeIdentifier(modifier.propertyName);
      decodeTarget(modifier.target);
      arguments = initializer.argumentList;
      typeArguments = initializer.typeArguments;
    } else {
      throw UnsupportedError('Unknown type ${initializer.runtimeType}');
    }

    final build = arguments.positionalArguments().firstOrNull;
    if (build is! FunctionExpression) return null;

    final dependenciesElement = arguments
        .namedArguments()
        .firstWhereOrNull((e) => e.name.label.name == 'dependencies');
    final dependencies = LegacyProviderDependencies.parse(dependenciesElement);

    final legacyProviderDeclaration = LegacyProviderDeclaration._(
      name: node.name,
      node: node,
      build: build,
      providerElement: providerElement,
      argumentList: arguments,
      typeArguments: typeArguments,
      provider: provider,
      autoDisposeModifier: autoDisposeModifier,
      familyModifier: familyModifier,
      dependencies: dependencies,
    );

    build.accept(_LegacyRefInvocationVisitor(legacyProviderDeclaration));

    return legacyProviderDeclaration;
  }

  final LegacyProviderDependencies? dependencies;

  final FunctionExpression build;
  final ArgumentList argumentList;
  final Identifier provider;
  final SimpleIdentifier? autoDisposeModifier;
  final SimpleIdentifier? familyModifier;
  final TypeArgumentList? typeArguments;

  @override
  final LegacyProviderDeclarationElement providerElement;

  final List<RefInvocation> refInvocations = [];

  @override
  final Token name;

  @override
  final VariableDeclaration node;

  @override
  void accept(RiverpodAstVisitor visitor) {
    visitor.visitLegacyProviderDeclaration(this);
  }

  @override
  void visitChildren(RiverpodAstVisitor visitor) {
    dependencies?.accept(visitor);
    for (final refInvocation in refInvocations) {
      refInvocation.accept(visitor);
    }
  }
}

class _LegacyRefInvocationVisitor extends RecursiveAstVisitor<void>
    with _ParseRefInvocationMixin {
  _LegacyRefInvocationVisitor(this.declaration);

  final LegacyProviderDeclaration declaration;

  @override
  void visitRefInvocation(RefInvocation invocation) {
    declaration.refInvocations.add(invocation);
  }

  @override
  void visitWidgetRefInvocation(WidgetRefInvocation invocation) {
    // TODO report to parent
    // The provider has no widgetef
  }
}
