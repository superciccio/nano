import 'package:analyzer/dart/ast/ast.dart';
import 'package:custom_lint_builder/custom_lint_builder.dart';
import '../lint_utils.dart';

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
    dynamic reporter,
    CustomLintContext context,
  ) {
    final path = resolver.source.fullName;
    if (path.contains('/test/') ||
        path.contains('/example/') ||
        path.contains('/lint_examples/')) {
      return;
    }

    context.registry.addInstanceCreationExpression((node) {
      final element = node.constructorName.staticElement;
      if (element == null) return;

      final enclosing = element.enclosingElement;
      if (['Atom', 'ComputedAtom', 'AsyncAtom', 'StreamAtom', 'DebouncedAtom']
              .contains(enclosing.name) &&
          (enclosing.library.name == 'nano' ||
              enclosing.library.identifier.contains('package:nano/') == true)) {
        // Enforce that atoms are defined inside NanoLogic
        final classDeclaration = node.thisOrAncestorOfType<ClassDeclaration>();

        if (classDeclaration == null) {
          reporter.atNode(node, _code);
          return;
        }

        final classElement = classDeclaration.declaredElement;
        if (classElement == null) return;

        // Check if it extends NanoLogic or has a valid suffix
        final name = classElement.name;
        final isValidSuffix =  
            (name.endsWith('Service') ||
                name.endsWith('Logic') ||
                name.endsWith('Runner') ||
                name.endsWith('Manager') ||
                name.endsWith('Controller') ||
                name.endsWith('Repository'));

        if (!isValidSuffix && !TypeCheckers.nanoLogic.isSuperOf(classElement)) {
          reporter.atNode(node, _code);
        }
      }
    });

    // Also check for .toAtom() extension calls
    context.registry.addMethodInvocation((node) {
      if (node.methodName.name == 'toAtom') {
        final element = node.methodName.staticElement;
        if (element == null) return;

        // Verify it's the nano extension
        // Note: isEquivalentToDeclaration might be tricky for extensions,
        // but checking the library name is a good fallback if TypeChecker fails on extensions.
        if (element.library?.name == 'nano' ||
            element.library?.identifier.contains('package:nano/') == true) {
          final classDeclaration =
              node.thisOrAncestorOfType<ClassDeclaration>();
          if (classDeclaration == null) {
            reporter.atNode(node, _code);
            return;
          }

          final classElement = classDeclaration.declaredElement;
          if (classElement == null) return;

          final name = classElement.name;
          final isValidSuffix =  
              (name.endsWith('Service') ||
                  name.endsWith('Logic') ||
                  name.endsWith('Runner') ||
                  name.endsWith('Manager') ||
                  name.endsWith('Controller') ||
                  name.endsWith('Repository'));

          if (!isValidSuffix &&
              !TypeCheckers.nanoLogic.isSuperOf(classElement)) {
            reporter.atNode(node, _code);
          }
        }
      }
    });
  }
}
