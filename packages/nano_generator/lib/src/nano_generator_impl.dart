import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:nano_annotations/nano_annotations.dart';

class NanoGenerator extends GeneratorForAnnotation<Nano> {
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@nano can only be applied to classes.',
        element: element,
      );
    }

    // Input: _PocCounterLogic
    // Output Mixin: _$PocCounterLogic

    final className = element.name;
    // Remove leading underscore for the public name part if present
    final publicName = className.startsWith('_') ? className.substring(1) : className;

    final fields = element.fields.where(
      (f) => _hasStateAnnotation(f),
    );

    final buffer = StringBuffer();

    buffer.writeln('mixin _\$${publicName} on $className {');

    for (final field in fields) {
      final fieldName = field.name;
      final type = field.type.getDisplayString(withNullability: true);
      final atomName = '_$fieldName\$Atom';

      // Initialize Atom using super.fieldName (reads the initial value from the base class)
      buffer.writeln('  late final $atomName = Atom<$type>(super.$fieldName, label: \'$publicName.$fieldName\');');

      // Override Getter
      buffer.writeln('  @override');
      buffer.writeln('  $type get $fieldName {');
      buffer.writeln('    return $atomName.value;');
      buffer.writeln('  }');

      // Override Setter
      buffer.writeln('  @override');
      buffer.writeln('  set $fieldName($type value) {');
      buffer.writeln('    super.$fieldName = value;'); // Keep base field in sync
      buffer.writeln('    $atomName.value = value;');
      buffer.writeln('  }');
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  bool _hasStateAnnotation(FieldElement field) {
    return field.metadata.any((m) =>
        m.element?.displayName == 'state' ||
        m.element?.enclosingElement?.displayName == 'State');
  }
}
