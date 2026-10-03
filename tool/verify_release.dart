import 'dart:io';

void main(List<String> args) {
  if (args.length != 1 || !RegExp(r'^v\d+\.\d+\.\d+$').hasMatch(args.single)) {
    stderr.writeln('Use a vMAJOR.MINOR.PATCH tag.');
    exitCode = 1;
    return;
  }
  final version = RegExp(
    r'^version: (\d+\.\d+\.\d+)\+\d+$',
    multiLine: true,
  ).firstMatch(File('pubspec.yaml').readAsStringSync())?.group(1);
  if (args.single != 'v$version' ||
      !File('CHANGELOG.md').readAsStringSync().contains('## $version')) {
    stderr.writeln('Tag, pubspec version and changelog must agree.');
    exitCode = 1;
  }
}
