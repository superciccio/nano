import 'package:custom_lint_builder/custom_lint_builder.dart';

class TypeCheckers {
  static const atom = TypeChecker.fromName('Atom', packageName: 'nano');
  static const asyncAtom =
      TypeChecker.fromName('AsyncAtom', packageName: 'nano');
  static const computedAtom =
      TypeChecker.fromName('ComputedAtom', packageName: 'nano');
  static const streamAtom =
      TypeChecker.fromName('StreamAtom', packageName: 'nano');
  static const debouncedAtom =
      TypeChecker.fromName('DebouncedAtom', packageName: 'nano');

  static const anyAtom = TypeChecker.any([
    atom,
    asyncAtom,
    computedAtom,
    streamAtom,
    debouncedAtom,
  ]);

  static const nanoLogic =
      TypeChecker.fromName('NanoLogic', packageName: 'nano');
  static const service = TypeChecker.fromName('Service', packageName: 'nano');

  static const widget = TypeChecker.fromName('Widget', packageName: 'flutter');
  static const state = TypeChecker.fromName('State', packageName: 'flutter');
  static const buildContext =
      TypeChecker.fromName('BuildContext', packageName: 'flutter');

  static const watch = TypeChecker.fromName('Watch', packageName: 'nano');
  static const watchMany =
      TypeChecker.fromName('WatchMany', packageName: 'nano');
}
