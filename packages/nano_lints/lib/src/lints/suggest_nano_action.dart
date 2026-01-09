import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class SuggestNanoAction extends DartLintRule {
  const SuggestNanoAction() : super(code: _code);

  static const _code = LintCode(
    name: 'suggest_nano_action',
    problemMessage: 'Complex logic detected in UI. Consider creating a NanoAction and dispatching it.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
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
    // We only want to count updates in the current function scope.
  }
  
  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    // Stop recursion.
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    super.visitMethodInvocation(node);
    
    final name = node.methodName.name;
    // Heuristic: Methods that look like state updates
    if (['set', 'update', 'increment', 'decrement', 'toggle', 'call'].contains(name)) {
       updateCount++;
    }
  }
  
  @override
  void visitAssignmentExpression(AssignmentExpression node) {
    super.visitAssignmentExpression(node);
    updateCount++;
  }
}
