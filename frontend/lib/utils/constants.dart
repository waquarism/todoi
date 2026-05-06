import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

String _resolveBaseUrl() {
  if (kIsWeb) return 'http://localhost:3000';
  if (Platform.isAndroid) return 'http://10.0.2.2:3000';
  return 'http://localhost:3000';
}

final String baseUrl = _resolveBaseUrl();

enum Priority { low, medium, high }

const Map<Priority, Color> priorityColors = {
  Priority.low: Colors.grey,
  Priority.medium: Colors.blue,
  Priority.high: Colors.red,
};
