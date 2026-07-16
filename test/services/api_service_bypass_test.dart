// Tests that ApiService (and similar service classes) are never constructed
// directly outside of service_locator.dart — prevents DI bypass regressions.
//
// This is a static analysis check: reads source files and asserts that no
// direct `ApiService()` constructor calls exist outside the service locator.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

/// Directories under lib/ to scan (relative to project root).
const _scanDirs = [
  'lib/features',
  'lib/services',
  'lib/widgets',
  'lib/models',
  'lib/state',
  'lib/utils',
  'lib/core',
];

/// Classes whose direct construction outside get_it is forbidden.
const _forbiddenConstructors = [
  'ApiService',
  // Add other service classes here as the codebase evolves
  // (e.g. 'OverpassApiService' if it becomes a singleton)
];

/// Files that are exempt from the check (they register services).
const _exemptFiles = [
  'service_locator.dart',
  'api_service.dart',
  'overpass_api_service.dart',
];

void main() {
  test('no direct ApiService() constructions outside service_locator', () {
    final projectRoot = _findProjectRoot();
    final violations = <String>[];

    for (final dir in _scanDirs) {
      final dirPath = '${projectRoot.path}/$dir';
      final dirEntity = Directory(dirPath);
      if (!dirEntity.existsSync()) continue;

      final files = dirEntity.listSync(recursive: true).whereType<File>();

      for (final file in files) {
        if (!file.path.endsWith('.dart')) continue;

        final fileName = file.path.split('/').last;
        if (_exemptFiles.contains(fileName)) continue;

        final content = file.readAsStringSync();
        final lines = content.split('\n');

        for (int i = 0; i < lines.length; i++) {
          final line = lines[i];
          final stripped = line.trim();

          // Skip comments
          if (stripped.startsWith('//') || stripped.startsWith('*')) continue;

          for (final className in _forbiddenConstructors) {
            // Match `ClassName()` but not `ClassName?` or `ClassName<T>`
            // Not `getIt<ClassName>()` or `ClassName.someStatic()`
            if (RegExp(r'\b' + className + r'\(\)').hasMatch(stripped) &&
                !stripped.contains('getIt<') &&
                !stripped.contains('register')) {
              violations.add(
                '${file.path}:${i + 1}:  $stripped',
              );
            }
          }
        }
      }
    }

    if (violations.isNotEmpty) {
      fail(
        'Found ${violations.length} direct service construction(s) outside '
        'service_locator.dart — use getIt<Service>() instead:\n'
        '${violations.join('\n')}',
      );
    }
  });
}

Directory _findProjectRoot() {
  // Start from the current directory and go up looking for pubspec.yaml
  var dir = Directory.current;
  while (true) {
    if (File('${dir.path}/pubspec.yaml').existsSync()) return dir;
    final parent = dir.parent;
    if (parent.path == dir.path) {
      throw StateError('Could not find project root (no pubspec.yaml found)');
    }
    dir = parent;
  }
}
