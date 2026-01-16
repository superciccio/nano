import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
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
    final actualPublicName =
        className.startsWith('_') ? className.substring(1) : className;

    final fields = element.fields.where(_isNanoField);

    final buffer = StringBuffer();
    buffer.writeln('mixin _\$${actualPublicName} on $className {');

    for (final field in fields) {
      _validateField(field);

      final fieldName = field.name;
      final type = field.type.getDisplayString(withNullability: true);
      final atomName = '_\$${fieldName}Atom';

      if (_hasAnnotation(field, 'async')) {
        _generateAsyncAtom(buffer, field, type, atomName, actualPublicName);
      } else if (_hasAnnotation(field, 'stream')) {
        _generateStreamAtom(buffer, field, type, atomName, actualPublicName);
      } else {
        _generateValueAtom(buffer, field, type, atomName, actualPublicName);
      }
    }

    buffer.writeln('}');
    return buffer.toString();
  }

  bool _isNanoField(FieldElement field) {
    return _hasAnnotation(field, 'state') ||
        _hasAnnotation(field, 'async') ||
        _hasAnnotation(field, 'stream');
  }

  bool _hasAnnotation(FieldElement field, String name) {
    return field.metadata.any((m) => m.element?.displayName == name);
  }

  void _validateField(FieldElement field) {
    if (field.isPrivate) {
      throw InvalidGenerationSourceError(
        'Nano state fields cannot be private.',
        element: field,
      );
    }
    if (field.isStatic) {
      throw InvalidGenerationSourceError(
        'Nano state fields cannot be static.',
        element: field,
      );
    }
  }

  void _generateValueAtom(StringBuffer buffer, FieldElement field, String type,
      String atomName, String publicName) {
    buffer.writeln(
        "  late final $atomName = Atom<$type>(super.${field.name}, label: '$publicName.${field.name}');");
    _generateAccessors(buffer, field, type, atomName, 'Atom', type);
  }

  void _generateAsyncAtom(StringBuffer buffer, FieldElement field, String type,
      String atomName, String publicName) {
    final innerType = _getGenericType(field.type, 'AsyncState');
    buffer.writeln(
        "  late final $atomName = AsyncAtom<$innerType>(initial: super.${field.name}, label: '$publicName.${field.name}');");
    _generateAccessors(buffer, field, type, atomName, 'AsyncAtom', innerType);

    // Add track[Name] helper (experimental)
    final capitalized = field.name[0].toUpperCase() + field.name.substring(1);
    buffer.writeln(
        '  Future<void> track$capitalized(Future<$innerType> future) => $atomName.track(future);');
  }

  void _generateStreamAtom(StringBuffer buffer, FieldElement field, String type,
      String atomName, String publicName) {
    throw InvalidGenerationSourceError(
      '@stream is not yet fully supported via field generation.',
      element: field,
    );
  }

  void _generateAccessors(
      StringBuffer buffer,
      FieldElement field,
      String fieldType,
      String atomName,
      String atomClass,
      String atomGenericType) {
    final fieldName = field.name;
    buffer.writeln('  @override');
    buffer.writeln('  $fieldType get $fieldName => $atomName.value;');
    buffer.writeln('  @override');
    buffer.writeln('  set $fieldName($fieldType value) {');
    buffer.writeln('    super.$fieldName = value;');
    buffer.writeln('    $atomName.value = value;');
    buffer.writeln('  }');

    // Check if the base class defines the $ getter already (common pattern for Logic access)
    final enclosingClass = field.enclosingElement3;
    final hasBaseGetter = enclosingClass is ClassElement &&
        enclosingClass.getGetter('${fieldName}\$') != null;

    if (hasBaseGetter) {
      buffer.writeln('  @override');
    }
    buffer.writeln(
        '  $atomClass<$atomGenericType> get ${fieldName}\$ => $atomName;');
  }

  String _getGenericType(DartType type, String expectedWrapper) {
    final typeName = type.getDisplayString(withNullability: false);
    if (type is ParameterizedType && typeName.startsWith(expectedWrapper)) {
      return type.typeArguments.first.getDisplayString(withNullability: true);
    }
    throw InvalidGenerationSourceError(
      'Field must be of type $expectedWrapper<T> when using annotation. Found: $typeName',
    );
  }
}
