class FileConfig {
  final String inputFile;
  final String outputFile;
  final String? className;

  FileConfig({required this.inputFile, required this.outputFile, this.className});

  factory FileConfig.fromJson(Map<String, dynamic> json) {
    return FileConfig(
      inputFile: json['input_file'] as String,
      outputFile: json['output_file'] as String,
      className: json.containsKey('class_name') ? json['class_name'] : null,
    );
  }
}