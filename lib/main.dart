import 'package:flutter/material.dart';
import 'package:solducci/views/homescreen/main.dart';
import 'package:solducci/utils/api/sheet_api.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "dev/.env");

  await SheetApi.init();

  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    ));
}
