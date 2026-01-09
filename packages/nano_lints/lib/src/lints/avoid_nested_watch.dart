import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidNestedWatch extends DartLintRule {
  const AvoidNestedWatch() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_nested_watch',
    problemMessage: 'Avoid nesting Watch widgets. Use tuple syntax (a, b).watch(...) instead.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // Check for explicit Watch/WatchMany
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (typeName == 'Watch' || typeName == 'WatchMany') {
        if (_isNestedInWatch(node)) {
          reporter.atNode(node, _code);
        }
      }
    });

    // Check for .watch() extension
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'watch') {
         if (_isNestedInWatch(node)) {
           reporter.atNode(node, _code);
         }
      }
    });
  }

  bool _isNestedInWatch(AstNode node) {
    // Walk up the tree
    for (var parent = node.parent; parent != null; parent = parent.parent) {
      // Logic for Nested in explicit Watch(builder: ...)
      if (parent is NamedExpression && parent.name.label.name == 'builder') {
         // Check if this builder belongs to a Watch widget
         final grandParent = parent.parent?.parent; // ArgumentList -> InstanceCreation
         if (grandParent is InstanceCreationExpression) {
            final typeName = grandParent.constructorName.type.name.lexeme;
            if (typeName == 'Watch' || typeName == 'WatchMany') {
              return true;
            }
         }
      }
      
      // Logic for Nested in .watch((context, val) => ...)
      if (parent is MethodInvocation && parent.methodName.name == 'watch') {
          // We are inside a method call to .watch().
          // Using structural assumption that .watch() takes a builder as argument.
          // Note: 'node' (the child Watch) must be inside the argument list of this parent.
          // But we are walking up, so we are definitely inside 'parent'.
          return true;
      }
      
      // Stop if we hit a class or function boundary to avoid expensive walks or false positives?
      // Actually, we want to find if we are lexically inside.
      if (parent is ClassDeclaration || parent is FunctionDeclaration) {
        break; 
      }
    }
    return false;
  }
}
