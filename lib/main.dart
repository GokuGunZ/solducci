import 'package:flutter/material.dart';
import 'package:solducci/views/homescreen/main.dart';
import 'package:solducci/utils/api/sheet_api.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SheetApi.init();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    ));
}
