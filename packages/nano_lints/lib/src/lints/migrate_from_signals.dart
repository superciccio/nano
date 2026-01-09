import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/error.dart' as analyzer;
import 'package:analyzer/diagnostic/diagnostic.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class MigrateFromSignals extends DartLintRule {
  const MigrateFromSignals() : super(code: _code);

  static const _code = LintCode(
    name: 'migrate_from_signals',
    problemMessage: 'This Signal/Computed-based pattern can be migrated to Nano Atoms.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    // Detect signal<T>(...) creation
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'signal' && node.target == null) {
        reporter.atNode(node, _code);
      }
    });

    // Detect computed(() => ...) creation
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'computed' && node.target == null) {
        reporter.atNode(node, _code);
      }
    });

    // Detect .value access on what might be a signal
    context.registry.addPropertyAccess((node) {
      if (node.propertyName.name == 'value') {
        // This is generic, but in a signals migration context it's frequent.
        // We could refine by checking the type if available, but for structural linting
        // we might just stick to obvious patterns or common names.
        // For now, let's keep it simple.
        // reporter.atNode(node, _code); 
      }
    });
    
    context.registry.addPrefixedIdentifier((node) {
      if (node.identifier.name == 'value') {
         // same as above
      }
    });
  }

  @override
  List<Fix> getFixes() => [_MigrateFromSignalsFix()];
}

class _MigrateFromSignalsFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    analyzer.Diagnostic diagnostic,
    List<analyzer.Diagnostic> others,
  ) {
    context.registry.addMethodInvocation((node) {
      if (!diagnostic.sourceRange.intersects(node.sourceRange)) return;

      if (node.methodName.name == 'signal') {
        final changeBuilder = reporter.createChangeBuilder(
          message: 'Migrate signal to Atom',
          priority: 1,
        );

        changeBuilder.addDartFileEdit((builder) {
          final arg = node.argumentList.arguments.first.toSource();
          builder.addSimpleReplacement(node.sourceRange, '$arg.toAtom()');
        });
      }

      if (node.methodName.name == 'computed') {
        final changeBuilder = reporter.createChangeBuilder(
          message: 'Migrate computed to ComputedAtom',
          priority: 1,
        );

        changeBuilder.addDartFileEdit((builder) {
          final arg = node.argumentList.arguments.first.toSource();
          builder.addSimpleReplacement(node.sourceRange, 'ComputedAtom([], $arg)');
        });
      }
    });
  }
}
