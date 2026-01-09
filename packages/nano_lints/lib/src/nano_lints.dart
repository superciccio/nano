import 'package:custom_lint_builder/custom_lint_builder.dart';
import 'lints/avoid_atom_outside_logic.dart';
import 'lints/logic_naming_convention.dart';
import 'lints/refactor_to_nano.dart';
import 'lints/migrate_from_provider.dart';
import 'lints/migrate_from_signals.dart';

class NanoLints extends PluginBase {
  @override
  List<LintRule> getLintRules(CustomLintConfigs configs) => [
        AvoidAtomOutsideLogic(),
        LogicNamingConvention(),
        RefactorToNano(),
        MigrateFromProvider(),
        MigrateFromSignals(),
      ];
}
