import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MigrateFromSignals extends DartLintRule {
  const MigrateFromSignals() : super(code: _code);

  static const _code = LintCode(
    name: 'migrate_from_signals',
    problemMessage:
        'This Signal/Computed-based pattern can be migrated to Nano Atoms.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    dynamic reporter,
    CustomLintContext context,
  ) {
    // Detect signal<T>(...) creation
    context.registry.addMethodInvocation((node) {
      if (!_isSignalsImported(node)) return;
      if (node.methodName.name == 'signal' && node.target == null) {
        reporter.atNode(node, _code);
      }
    });

    // Detect computed(() => ...) creation
    context.registry.addMethodInvocation((node) {
      if (!_isSignalsImported(node)) return;
      if (node.methodName.name == 'computed' && node.target == null) {
        reporter.atNode(node, _code);
      }
    });
  }

  bool _isSignalsImported(AstNode node) {
    final root = node.root as CompilationUnit;
    return root.directives.whereType<ImportDirective>().any((d) =>
        d.uri.stringValue?.contains('package:signals/') == true ||
        d.uri.stringValue?.contains('package:signals_flutter/') == true);
  }

  @override
  List<Fix> getFixes() => [];
}
