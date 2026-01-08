import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class AvoidAtomOutsideLogic extends DartLintRule {
  const AvoidAtomOutsideLogic() : super(code: _code);

  static const _code = LintCode(
    name: 'avoid_atom_outside_logic',
    problemMessage:
        'Atoms should strictly be defined inside a NanoLogic or Service class.',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addInstanceCreationExpression((node) {
      final type = node.constructorName.type;
      final typeName = type.name.lexeme;

      if (['Atom', 'ComputedAtom', 'AsyncAtom'].contains(typeName)) {
        // Traverse up to find the enclosing class
        final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();

        if (classDeclaration == null) {
          reporter.atNode(node, _code);
          return;
        }

        final extendsClause = classDeclaration.extendsClause;
        if (extendsClause == null) {
          reporter.atNode(node, _code);
          return;
        }

        // Check if the enclosing class extends NanoLogic or Service
        // Again, using simple name check for simplicity/speed in this context
        final superclassName = extendsClause.superclass.name.lexeme;
        if (!['NanoLogic', 'Service'].contains(superclassName)) {
          reporter.atNode(node, _code);
        }
      }
    });
  }
}
