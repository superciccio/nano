import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'lints/avoid_atom_outside_logic.dart';
import 'lints/logic_naming_convention.dart';

class NanoLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidAtomOutsideLogic(),
        LogicNamingConvention(),
      ];
}
