import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../lint_utils.dart';

class SuggestNanoAction extends DartLintRule {
  const SuggestNanoAction() : super(code: _code);

  static const _code = LintCode(
    name: 'suggest_nano_action',
    problemMessage:
        'Complex logic detected in UI. Consider creating a NanoAction and dispatching it.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    dynamic reporter,
    CustomLintContext context,
  ) {
    context.registry.addFunctionExpression((node) {
      // We only care about functions defined in the UI layer (Widgets)
      // Checking if we are inside a Class extending Widget/State is good,
      // but structural checks for update counts are usually enough.

      final visitor = _AtomUpdateVisitor();
      node.body.visitChildren(visitor);

      if (visitor.updateCount > 2) {
        reporter.atNode(node, _code);
      }
    });
  }
}

class _AtomUpdateVisitor extends RecursiveAstVisitor<void> {
  int updateCount = 0;

  @override
  void visitFunctionExpression(FunctionExpression node) {
    // Stop recursion for nested functions.
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Stop recursion.
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);

    final element = node.methodName.staticElement;
    if (element == null) return;

    // Check if the target is an Atom
    final targetType = node.realTarget?.staticType;
    if (targetType != null && TypeCheckers.anyAtom.isExactlyType(targetType)) {
      final name = node.methodName.name;
      if (['set', 'update', 'increment', 'decrement', 'toggle', 'call']
          .contains(name)) {
        updateCount++;
      }
    }
  }

  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    super.visitAssignmentExpression(node);

    // Check if we are assigning to an Atom's .value
    final left = node.leftHandSide;
    if (left is PropertyAccess && left.propertyName.name == 'value') {
      final targetType = left.realTarget.staticType;
      if (targetType != null &&
          TypeCheckers.anyAtom.isExactlyType(targetType)) {
        updateCount++;
      }
    } else if (left is PrefixedIdentifier && left.identifier.name == 'value') {
      final targetType = left.prefix.staticType;
      if (targetType != null &&
          TypeCheckers.anyAtom.isExactlyType(targetType)) {
        updateCount++;
      }
    }
  }
}
