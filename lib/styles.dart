import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

TextStyle medTextStyle = const TextStyle(fontSize: 30.0);

TextStyle smallTextStyle = const TextStyle(fontSize: 20.0);

ButtonStyle enabledButtonStyle = ElevatedButton.styleFrom(
  textStyle: const TextStyle(fontSize: 20),
  // minHeight: 100 // TODO How do I get the button to be bigger? More space above and below text
);
ButtonStyle smallEnabledButtonStyle = ElevatedButton.styleFrom(
  textStyle: const TextStyle(fontSize: 10),
  // minHeight: 100 // TODO How do I get the button to be bigger? More space above and below text
);
ButtonStyle disabledButtonStyle = ElevatedButton.styleFrom(
  textStyle: const TextStyle(fontSize: 20),
  primary: Colors.grey,
  // minHeight: 100 // TODO How do I get the button to be bigger? More space above and below text
);
ButtonStyle warningButtonStyle = ElevatedButton.styleFrom(
  textStyle: const TextStyle(fontSize: 20),
  primary: Colors.red,
  // minHeight: 100 // TODO How do I get the button to be bigger? More space above and below text
);

InputDecoration getInputDecoration(String label) => InputDecoration(
      border: const OutlineInputBorder(),
      labelText: label,
    );

class DollarsInputFormatter implements TextInputFormatter {
  final RegExp _regExp = RegExp(r"\d{0,10}\.\d{0,2}");
  bool _isValid(String value) {
    try {
      final matches = _regExp.allMatches(value);
      for (Match match in matches) {
        if (match.start == 0 && match.end == value.length) {
          return true;
        }
      }
      return false;
    } catch (e) {
      assert(false, e.toString()); // Invalid regex
      return true;
    }
  }

  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    final oldValueValid = _isValid(oldValue.text);
    final newValueValid = _isValid(newValue.text);
    if (oldValueValid && !newValueValid) {
      return oldValue;
    }
    return newValue;
  }
}
