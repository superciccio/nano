import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/diagnostic/diagnostic.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
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
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // Detect ChangeNotifierProvider or Consumer
    context.registry.addInstanceCreationExpression((node) {
      final typeName = node.constructorName.type.name.lexeme;
      if (['ChangeNotifierProvider', 'Consumer', 'MultiProvider'].contains(typeName)) {
        reporter.atNode(node, _code);
      }
    });

    // Detect Provider.of<T>(context)
    context.registry.addMethodInvocation((node) {
      final target = node.target;
      if (node.methodName.name == 'of' && 
          target is Identifier && 
          target.name == 'Provider') {
        reporter.atNode(node, _code);
      }
    });

    // Detect context.watch<T>() or context.read<T>()
    context.registry.addMethodInvocation((node) {
      final methodName = node.methodName.name;
      if (['watch', 'read', 'select'].contains(methodName)) {
        final target = node.target;
        if (target is Identifier && target.name == 'context') {
          // Check if it looks like a Provider extension call
          // Simplistic check: if it has type arguments it's likely a provider/bloc call
          if (node.typeArguments != null) {
             reporter.atNode(node, _code);
          }
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_MigrateFromProviderFix()];
}

class _MigrateFromProviderFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    analyzer.Diagnostic diagnostic,
    List<analyzer.Diagnostic> others,
  ) {
    // Fix implementation will be complex, starting with simple replacements
    context.registry.addMethodInvocation((node) {
      if (!diagnostic.sourceRange.intersects(node.sourceRange)) return;

      final methodName = node.methodName.name;
      final changeBuilder = reporter.createChangeBuilder(
        message: 'Migrate $methodName to Nano registry',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        if (methodName == 'read') {
           builder.addSimpleReplacement(node.sourceRange, 'context.read<${node.typeArguments?.arguments.first.toSource()}>()'); 
           // Wait, nano uses context.read<T>() too if we add the extension!
           // Actually, let's suggest the direct registry access or the same name if supported.
        }
        
        if (methodName == 'of' && (node.target as Identifier?)?.name == 'Provider') {
           final type = node.typeArguments?.arguments.first.toSource() ?? 'dynamic';
           builder.addSimpleReplacement(node.sourceRange, 'context.read<$type>()');
        }
      });
    });
  }
}
