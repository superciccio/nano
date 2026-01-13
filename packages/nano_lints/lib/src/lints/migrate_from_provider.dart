import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MigrateFromProvider extends DartLintRule {
  const MigrateFromProvider() : super(code: _code);

  static const _code = LintCode(
    name: 'migrate_from_provider',
    problemMessage: 'This Provider-based pattern can be migrated to Nano.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    dynamic reporter,
    CustomLintContext context,
  ) {
    // Detect ChangeNotifierProvider or Consumer
    context.registry.addInstanceCreationExpression((node) {
      if (!_isProviderImported(node)) return;

      final typeName = node.constructorName.type.name.lexeme;
      if (['ChangeNotifierProvider', 'Consumer', 'MultiProvider']
          .contains(typeName)) {
        reporter.atNode(node, _code);
      }
    });

    // Detect Provider.of<T>(context)
    context.registry.addMethodInvocation((node) {
      if (!_isProviderImported(node)) return;

      final target = node.target;
      if (node.methodName.name == 'of' &&
          target is Identifier &&
          target.name == 'Provider') {
        reporter.atNode(node, _code);
      }
    });

    // Detect context.watch<T>() or context.read<T>()
    context.registry.addMethodInvocation((node) {
      if (!_isProviderImported(node)) return;

      final methodName = node.methodName.name;
      if (['watch', 'read', 'select'].contains(methodName)) {
        final target = node.target;
        if (target is Identifier && target.name == 'context') {
          // Check if it looks like a Provider extension call
          if (node.typeArguments != null) {
            reporter.atNode(node, _code);
          }
        }
      }
    });
  }

  bool _isProviderImported(AstNode node) {
    final root = node.root as CompilationUnit;
    return root.directives.whereType<ImportDirective>().any((d) =>
        d.uri.stringValue?.contains('package:provider/') == true ||
        d.uri.stringValue?.contains('package:flutter_bloc/') == true ||
        d.uri.stringValue?.contains('package:riverpod/') == true);
  }

  @override
  List<Fix> getFixes() => [];
}
