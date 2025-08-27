import 'package:flutter/material.dart';
import '../../main.dart';
import '../../app_config.dart';
import '../seepays/resource.dart';
import 'config.dart';
import 'color.dart';

void main() {
  print('SEEPAYS Token: $sigVendor');
  
  var configApp = AppConfig(
    appDisplayName: namaApp,
    appInternalId: sigVendor,
    theme: colors,
    resource: StringResource(),
    child: MyApp(),
  );

  runApp(configApp);
}
