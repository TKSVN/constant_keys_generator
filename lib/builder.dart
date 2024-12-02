import 'dart:async';
import 'dart:io';

// ignore: depend_on_referenced_packages
import 'package:build/build.dart';
import 'package:constant_keys_generator/builder_config.dart';
import 'package:constant_keys_generator/file_config.dart';
import 'package:constant_keys_generator/util.dart';
import 'dart:convert';

import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:yaml/yaml.dart';

class ConstantKeysGenerator implements Builder {
  final BuilderConfig? _builderConfig;

  ConstantKeysGenerator(this._builderConfig);

  @override
  Future<void> build(BuildStep buildStep) async {
    if (_builderConfig == null) {
      return;
    }

    for (var fileConfig in _builderConfig.fileConfigs) {
      await _generenateFile(buildStep, fileConfig);
    }
  }

  Future<void> _generenateFile(BuildStep buildStep, FileConfig config) async {
    // Use Glob to match all JSON files in the translations directory
    final inputFilesGlob = Glob(config.inputFile);

    if (inputFilesGlob.listSync().isEmpty) {
      log.warning('Unable to found input file path ${config.inputFile}');
      return;
    }

    final inputFiles = buildStep.findAssets(inputFilesGlob);

    final Map<String, dynamic> allTranslations = {};
    await for (final id in inputFiles) {
      final content = await buildStep.readAsString(id);
      final json = jsonDecode(content) as Map<String, dynamic>;
      allTranslations.addAll(json);
    }

    final buffer = StringBuffer();
    final classes = <String, StringBuffer>{};

    // Extract output file's name (without extenstion)
    final fileNameWithoutExt = getFileNameWithoutExtension(config.outputFile);
    final className = config.className ?? snakeToPascalCase(fileNameWithoutExt);

    // Ignore class name warning
    buffer.writeln('// ignore_for_file: camel_case_types');

    _generateClasses(classes, allTranslations, [], '_$className');

    // Write classes from leaves to root
    classes.forEach((className, classBuffer) {
      buffer.writeln(classBuffer.toString());
    });

    // Write the public LocaleKeys class
    buffer.writeln('// ignore: non_constant_identifier_names');
    buffer.writeln('final $className = _$className();');

    final outputFile = File(_createOutputFilePath(config.outputFile));
    if (await outputFile.exists()) {
      await outputFile.delete();
    }

    final output = AssetId(buildStep.inputId.package, outputFile.path);
    await buildStep.writeAsString(output, buffer.toString());

    log.info(
        'Constants class $className has been generated in path lib/${config.outputFile}');
  }

  void _generateClasses(Map<String, StringBuffer> classes,
      Map<String, dynamic> json, List<String> path, String className) {
    final classBuffer = StringBuffer();
    classBuffer.writeln('class $className {');

    json.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        final nestedClassName = '${className}_${snakeToPascalCase(key)}';
        classBuffer
            .writeln('  final $nestedClassName $key = $nestedClassName();');
        _generateClasses(classes, value, [...path, key], nestedClassName);
      } else {
        classBuffer
            .writeln('  final String $key = \'${[...path, key].join(".")}\';');
      }
    });

    classBuffer.writeln('  $className();');
    classBuffer.writeln('}');

    classes[className] = classBuffer;
  }

  @override
  Map<String, List<String>> get buildExtensions => {
        r'$lib$': (_builderConfig?.fileConfigs ?? [])
            .map((config) => _createOutputFilePath(config.outputFile, containsLib: false))
            .toList()
      };

  String _createOutputFilePath(String outputFileName, { bool containsLib = true}) {
    return '${containsLib ? 'lib/' : ''}${_builderConfig?.outputDir}/$outputFileName.dart';
  }

  factory ConstantKeysGenerator.fromConfig() {
    final builderConfig = _loadConfigs();

    return ConstantKeysGenerator(builderConfig);
  }

  static BuilderConfig? _loadConfigs() {
    return _loadConfigsFromFile() ?? _loadConfigsFromPubspec();
  }

  static BuilderConfig? _loadConfigsFromFile() {
    // Using 'constant_keys_generator.yaml' config file
    const customConfigFileName = 'constant_keys_generator.yaml';
    final customConfigFile = File(customConfigFileName);

    if (!customConfigFile.existsSync()) {
      log.warning(
          '$customConfigFileName not found. Using default configuration.');
      return null;
    }

    // Read and parse the custom config file
    final configContent = customConfigFile.readAsStringSync();
    final configYaml = loadYaml(configContent) as Map<String, dynamic>;

    // Parse file configurations
    return BuilderConfig(
      fileConfigs: (configYaml['file_configs'] as List?)
        ?.map(
            (config) => FileConfig.fromJson(Map<String, dynamic>.from(config)))
        .toList() ?? []);
  }

  static BuilderConfig? _loadConfigsFromPubspec() {
    // Read pubspec.yaml
    final pubspecFile = File('pubspec.yaml');
    if (!pubspecFile.existsSync()) {
      log.warning('pubspec.yaml not found.');
      return null;
    }

    final pubspecContent = pubspecFile.readAsStringSync();
    final pubspec = loadYaml(pubspecContent);

    // Parse the custom configuration
    final customConfig = pubspec['constant_keys_generator'] as Map?;
    if (customConfig == null) {
      log.warning(
          'No configuration found for "constant_keys_generator" in pubspec.yaml.');
      return null;
    }

    return BuilderConfig(
      fileConfigs:(customConfig['file_configs'] as List?)
        ?.map(
            (config) => FileConfig.fromJson(Map<String, dynamic>.from(config)))
        .toList() ?? []);
  }
}

Builder localeKeysGeneratorBuilder(BuilderOptions options) {
  return ConstantKeysGenerator.fromConfig();
}
