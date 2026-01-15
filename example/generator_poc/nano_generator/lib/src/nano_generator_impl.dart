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

    final className = element.name;
    final fields = element.fields.where(
      (f) => _hasStateAnnotation(f),
    );

    final buffer = StringBuffer();

    // Mixin definition
    buffer.writeln('mixin _\$${className} on $className {');

    for (final field in fields) {
      final fieldName = field.name;
      final type = field.type.getDisplayString(withNullability: true);
      final atomName = '_$fieldName\$Atom';

      // Atom field - lazy initialized using super.field value
      buffer.writeln('  late final $atomName = Atom<$type>(super.$fieldName, label: \'$className.$fieldName\');');

      // Getter override
      buffer.writeln('  @override');
      buffer.writeln('  $type get $fieldName {');
      buffer.writeln('    return $atomName.value;');
      buffer.writeln('  }');

      // Setter override
      buffer.writeln('  @override');
      buffer.writeln('  set $fieldName($type value) {');
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
