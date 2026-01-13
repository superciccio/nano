import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../lint_utils.dart';

class LogicNamingConvention extends DartLintRule {
  const LogicNamingConvention() : super(code: _code);

  static const _code = LintCode(
    name: 'logic_naming_convention',
    problemMessage: 'Classes extending NanoLogic should end with "Logic".',
  );

  @override
  void run(
    CustomLintResolver resolver,
    dynamic reporter,
    CustomLintContext context,
  ) {
    context.registry.addClassDeclaration((node) {
      final element = node.declaredFragment?.element;
      if (element == null) return;

      if (TypeCheckers.nanoLogic.isSuperOf(element)) {
        final className = node.name.lexeme;
        if (!className.endsWith('Logic') && className != 'NanoLogic') {
          reporter.atToken(node.name, _code);
        }
      }
    });
  }
}
