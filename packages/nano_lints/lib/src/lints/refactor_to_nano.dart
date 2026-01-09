import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart' as analyzer;
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class RefactorToNano extends DartLintRule {
  const RefactorToNano() : super(code: _code);

  static const _code = LintCode(
    name: 'refactor_to_nano',
    problemMessage: 'This StatefulWidget can be refactored to a Nano-powered widget.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'setState') {
        final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();
        if (classDeclaration != null) {
          reporter.atNode(classDeclaration, _code);
        }
      }
    });
  }

  @override
  List<Fix> getFixes() => [_RefactorToNanoFix()];
}

class _RefactorToNanoFix extends DartFix {
  @override
  void run(
    CustomLintResolver resolver,
    ChangeReporter reporter,
    CustomLintContext context,
    analyzer.Diagnostic diagnostic,
    List<analyzer.Diagnostic> others,
  ) {
    context.registry.addClassDeclaration((node) {
      if (!diagnostic.sourceRange.intersects(node.sourceRange)) return;

      final className = node.name.lexeme;
      final logicClassName = '${className}Logic';

      final changeBuilder = reporter.createChangeBuilder(
        message: 'Refactor to Nano',
        priority: 1,
      );

      changeBuilder.addDartFileEdit((builder) {
        // 1. Add nano import if missing
        final root = node.root as CompilationUnit;
        final hasNanoImport = root.directives
            .whereType<ImportDirective>()
            .any((d) => d.uri.stringValue == 'package:nano/nano.dart');

        if (!hasNanoImport) {
          builder.addInsertion(0, (builder) {
            builder.writeln("import 'package:nano/nano.dart';");
          });
        }

        // 2. Extract state info (simplistic for this mini-project)
        // We look for the State class
        final stateClassName = '_${className}State';
        ClassDeclaration? stateClass;
        for (final declaration in root.declarations) {
          if (declaration is ClassDeclaration &&
              declaration.name.lexeme == stateClassName) {
            stateClass = declaration;
            break;
          }
        }

        if (stateClass == null) return;

        // Extract fields and increment method
        String fields = '';
        String methods = '';
        String? counterName;

        for (final member in stateClass.members) {
          if (member is FieldDeclaration) {
            fields += '  final ${member.fields.variables.first.name.lexeme.replaceAll('_', '')} = ${member.fields.variables.first.initializer?.toSource()}.toAtom();\n';
            counterName = member.fields.variables.first.name.lexeme.replaceAll('_', '');
          }
          if (member is MethodDeclaration && member.name.lexeme.contains('increment')) {
             methods += '  void increment() => $counterName.increment();\n';
          }
        }

        // 3. Create NanoLogic class
        final logicClass = '''
class $logicClassName extends NanoLogic<void> {
$fields$methods}

''';
        builder.addInsertion(node.offset, (builder) {
          builder.write(logicClass);
        });

        // 4. Replace StatefulWidget with NanoView
        final replacement = '''class $className extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return NanoView<$logicClassName, void>(
      create: (_) => $logicClassName(),
      builder: (context, logic) {
        return logic.${counterName ?? 'counter'}.watch((context, value) {
          return Text('\$value');
        });
      },
    );
  }
}
''';
        builder.addReplacement(node.sourceRange, (builder) {
          builder.write(replacement);
        });

        // 5. Remove State class
        builder.addDeletion(stateClass.sourceRange);
      });
    });
  }
}
