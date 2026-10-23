import 'dart:io';

import 'package:dotenv/dotenv.dart';

Map<String, String> loadEnvironment({
  required Iterable<String> variableNames,
  String envFile = '.env',
}) {
  final dotenv = DotEnv(quiet: true)..load([envFile]);
  final environment = <String, String>{};

  for (final name in variableNames) {
    final value = dotenv[name];
    if (value != null) {
      environment[name] = value;
    }
  }

  // Values exported by the process override local .env values.
  environment.addAll(Platform.environment);
  return environment;
}
