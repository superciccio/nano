import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';
import 'package:nano_generator/src/nano_generator_impl.dart';

Builder nanoBuilder(BuilderOptions options) =>
    SharedPartBuilder([NanoGenerator()], 'nano');
