part of '../riverpod_ast.dart';

abstract class RefInvocation extends RiverpodAst
    implements ProviderListenableExpressionParent {
  RefInvocation._({
    required this.node,
    required this.function,
  });

  @internal
  static RefInvocation? parse(
    MethodInvocation node, {
    required void Function() superCall,
  }) {
    final targetType = node.target?.staticType;
    if (targetType == null) return null;

    // Since Ref is sealed, checking that the function is from the package:riverpod
    // before checking its type skips iterating over the superclasses of an element
    // if it's not from Riverpod.
    if (!isFromRiverpod.isExactlyType(targetType) |
        !refType.isAssignableFromType(targetType)) {
      return null;
    }
    final function = node.function;
    if (function is! SimpleIdentifier) return null;
    final functionOwner = function.staticElement
        .cast<MethodElement>()
        ?.declaration
        .enclosingElement;

    if (functionOwner == null ||
        // Since Ref is sealed, checking that the function is from the package:riverpod
        // before checking its type skips iterating over the superclasses of an element
        // if it's not from Riverpod.
        !isFromRiverpod.isExactly(functionOwner) ||
        !refType.isAssignableFrom(functionOwner)) {
      return null;
    }

    switch (function.name) {
      case 'watch':
        return RefWatchInvocation._parse(
          node,
          function,
          superCall: superCall,
        );
      case 'read':
        return RefReadInvocation._parse(
          node,
          function,
          superCall: superCall,
        );
      case 'listen':
        return RefListenInvocation._parse(
          node,
          function,
          superCall: superCall,
        );
      default:
        return null;
    }
  }

  final MethodInvocation node;
  final SimpleIdentifier function;
}

class RefWatchInvocation extends RefInvocation {
  RefWatchInvocation._({
    required super.node,
    required super.function,
    required this.provider,
  }) : super._();

  static RefWatchInvocation? _parse(
    MethodInvocation node,
    SimpleIdentifier function, {
    required void Function() superCall,
  }) {
    assert(
      function.name == 'watch',
      'Argument error, function is not a ref.watch function',
    );

    final providerListenableExpression = ProviderListenableExpression.parse(
      node.argumentList.positionalArguments().singleOrNull,
    );
    if (providerListenableExpression == null) return null;

    final refInvocation = RefWatchInvocation._(
      node: node,
      function: function,
      provider: providerListenableExpression,
    );
    refInvocation.addChild(providerListenableExpression);

    return refInvocation;
  }

  final ProviderListenableExpression provider;

  @override
  void accept(RiverpodAstVisitor visitor) {
    visitor.visitRefWatchInvocation(this);
  }
}

class RefReadInvocation extends RefInvocation {
  RefReadInvocation._({
    required super.node,
    required super.function,
    required this.provider,
  }) : super._();

  static RefReadInvocation? _parse(
    MethodInvocation node,
    SimpleIdentifier function, {
    required void Function() superCall,
  }) {
    assert(
      function.name == 'read',
      'Argument error, function is not a ref.read function',
    );

    final providerListenableExpression = ProviderListenableExpression.parse(
      node.argumentList.positionalArguments().singleOrNull,
    );
    if (providerListenableExpression == null) return null;

    final refInvocation = RefReadInvocation._(
      node: node,
      function: function,
      provider: providerListenableExpression,
    );
    refInvocation.addChild(providerListenableExpression);

    return refInvocation;
  }

  final ProviderListenableExpression provider;

  @override
  void accept(RiverpodAstVisitor visitor) {
    visitor.visitRefReadInvocation(this);
  }
}

class RefListenInvocation extends RefInvocation {
  RefListenInvocation._({
    required super.node,
    required super.function,
    required this.listener,
    required this.provider,
  }) : super._();

  static RefListenInvocation? _parse(
    MethodInvocation node,
    SimpleIdentifier function, {
    required void Function() superCall,
  }) {
    assert(
      function.name == 'listen',
      'Argument error, function is not a ref.listen function',
    );

    final positionalArgs = node.argumentList.positionalArguments().toList();

    final listener = positionalArgs.elementAtOrNull(1);
    if (listener == null) return null;

    final providerListenableExpression = ProviderListenableExpression.parse(
      node.argumentList.positionalArguments().singleOrNull,
    );
    if (providerListenableExpression == null) return null;

    final refInvocation = RefListenInvocation._(
      node: node,
      function: function,
      listener: listener,
      provider: providerListenableExpression,
    );
    refInvocation.addChild(providerListenableExpression);

    return refInvocation;
  }

  final ProviderListenableExpression provider;
  final Expression listener;

  @override
  void accept(RiverpodAstVisitor visitor) {
    visitor.visitRefListenInvocation(this);
  }
}