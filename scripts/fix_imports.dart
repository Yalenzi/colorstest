import 'dart:io';

void main() async {
  final directory = Directory('lib');
  await processDirectory(directory);
  print('✅ All imports updated successfully!');
}

Future<void> processDirectory(Directory directory) async {
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && entity.path.endsWith('.dart')) {
      await updateImports(entity);
    }
  }
}

Future<void> updateImports(File file) async {
  final content = await file.readAsString();
  if (content.contains("package:reagentkit/")) {
    final updatedContent = content.replaceAll(
      "package:reagentkit/",
      "package:ctds/",
    );
    await file.writeAsString(updatedContent);
    print('Updated imports in: ${file.path}');
  }
}
