import 'dart:io';

String snakeToPascalCase(String input) {
  return input
      .split('_') // Split the string by underscores
      .map((word) => word.isNotEmpty
          ? '${word[0].toUpperCase()}${word.substring(1)}'
          : '') // Capitalize the first letter of each word
      .join(); // Join all the words
}

String getFileNameWithoutExtension(String path) {
  // Get the file name from the path
  String fileName = File(path).uri.pathSegments.last;

  // Remove the extension
  return fileName.contains('.')
      ? fileName.substring(0, fileName.lastIndexOf('.'))
      : fileName;
}
