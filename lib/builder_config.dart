import 'package:constant_keys_generator/file_config.dart';

class BuilderConfig {
  final String outputDir;
  final List<FileConfig> fileConfigs;

  BuilderConfig({this.outputDir = 'generated/constant_keys', required this.fileConfigs});
}