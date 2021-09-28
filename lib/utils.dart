import 'package:flutter/material.dart';

showSnackbar(String message, BuildContext context) async {
  final snackBar = SnackBar(
    content: Text(message),
  );
  ScaffoldMessenger.of(context).hideCurrentSnackBar();
  ScaffoldMessenger.of(context).showSnackBar(snackBar);
}
