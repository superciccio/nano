import 'package:analyzer/error/listener.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';

class LogicNamingConvention extends DartLintRule {
  const LogicNamingConvention() : super(code: _code);

  static const _code = LintCode(
    name: 'logic_naming_convention',
    problemMessage: 'Classes extending NanoLogic should end with "Logic".',
  );

  @override
  void run(
    CustomLintResolver resolver,
    DiagnosticReporter reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final extendsClause = node.extendsClause;
      if (extendsClause == null) return;

      // Simple check for now: if it extends something named NanoLogic
      // A more robust check would involve checking the element type.
      final superclass = extendsClause.superclass;
      if (superclass.name.lexeme == 'NanoLogic') {
        final className = node.name.lexeme;
        if (!className.endsWith('Logic')) {
          reporter.atToken(node.name, _code);
        }
      }
    });
  }
}
