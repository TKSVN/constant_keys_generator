import 'package:build/build.dart';
import 'dart:io';
import 'dart:convert';

class LocaleKeysGenerator implements Builder {
  @override
  Future<void> build(BuildStep buildStep) async {
    final directory = Directory('assets/translations');
    final files = directory.listSync().where((file) => file.path.endsWith('.json'));
    
    final Map<String, dynamic> allTranslations = {};
    
    for (var file in files) {
      final content = File(file.path).readAsStringSync();
      final json = jsonDecode(content) as Map<String, dynamic>;
      allTranslations.addAll(json);
    }
    
    final buffer = StringBuffer();
    final classes = <String, StringBuffer>{};
    
    _generateClasses(classes, allTranslations, [], '_LocaleKeys');
    
    // Write classes from leaves to root
    classes.forEach((className, classBuffer) {
      buffer.writeln(classBuffer.toString());
      buffer.writeln();
    });

      // Write the public LocaleKeys class
    buffer.writeln('final LocaleKeys = _LocaleKeys();');
    
    final output = AssetId(buildStep.inputId.package, 'lib/generated/locale_keys.dart');
    await buildStep.writeAsString(output, buffer.toString());
  }

  void _generateClasses(Map<String, StringBuffer> classes, Map<String, dynamic> json, List<String> path, String className) {
    final classBuffer = StringBuffer();
    classBuffer.writeln('class $className {');
    
    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final nestedClassName = '${className}_${_pascalCase(key)}';
        classBuffer.writeln('  final $nestedClassName $key = $nestedClassName();');
        _generateClasses(classes, value, [...path, key], nestedClassName);
      } else {
        classBuffer.writeln('  final String $key = \'${[...path, key].join(".")}\';');
      }
    });
    
    classBuffer.writeln('  $className();');
    classBuffer.writeln('}');
    
    classes[className] = classBuffer;
  }

  String _pascalCase(String input) {
    return input.split('_').map((word) => word[0].toUpperCase() + word.substring(1)).join('');
  }

  @override
  Map<String, List<String>> get buildExtensions => {
    r'$lib$': ['generated/locale_keys.dart']
  };
}

Builder localeKeysBuilder(BuilderOptions options) => LocaleKeysGenerator();