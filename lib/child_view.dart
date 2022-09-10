import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:money_tracker/styles.dart';
import 'package:money_tracker/utils.dart';

import 'database.dart';

class ChildViewHolder extends StatefulWidget {
  static const String route = "/childview";
  final ChildViewHolderArguments args;

  const ChildViewHolder(this.args, {Key? key}) : super(key: key);

  @override
  State createState() => ChildView();
}

class ChildViewHolderArguments {
  Child child;
  Function reloadChildren;
  ChildViewHolderArguments(this.child, this.reloadChildren);
}

class ChildView extends State<ChildViewHolder> {
  late double owedNewAmount;
  bool owedEditable = false;
  late TextField owedTextField;
  owedOnChanged(String value) {
    widget.args.child.amountOwed = double.parse(value);
    updateChangesMade();
  }

  owedOnEditClicked() {
    setState(() {
      owedEditable = !owedEditable;
    });
  }

  late double allowanceNewAmount;
  bool allowanceEditable = false;
  late TextField allowanceTextField;
  allowanceOnChanged(String value) {
    widget.args.child.allowanceAmount = double.parse(value);
    updateChangesMade();
  }

  allowanceOnEditClicked() {
    setState(() {
      allowanceEditable = !allowanceEditable;
    });
  }

  double payAmount = 0.0;
  late TextField payTextField;
  payOnChanged(String value) {
    payAmount = double.parse(value);
    updateChangesMade();
  }

  double deductAmount = 0.0;
  late TextField deductTextField;
  deductOnChanged(String value) {
    deductAmount = double.parse(value);
    updateChangesMade();
  }

  bool changesMade = false;
  updateChangesMade() {
    if (payAmount > 0 ||
        deductAmount > 0 ||
        owedNewAmount != widget.args.child.amountOwed ||
        allowanceNewAmount != widget.args.child.allowanceAmount) {
      changesMade = true;
    } else {
      changesMade = false;
    }
  }

  TextEditingController changeNameController = TextEditingController();

  onSubmit() {
    widget.args.child.amountOwed =
        widget.args.child.amountOwed + payAmount - deductAmount;
    DBDao().updateChild(widget.args.child);

    setState(() {
      owedNewAmount = widget.args.child.amountOwed;
      allowanceNewAmount = widget.args.child.allowanceAmount;
      payAmount = 0.0;
      deductAmount = 0.0;
    });

    String msg = "No changes have been made";
    if (changesMade) {
      msg = "Changes Saved";
    }
    showSnackbar(msg, context);
    updateChangesMade();
  }

  onNameChanged() async {
    setState(() {
      widget.args.child.name = changeNameController.text;
    });
    await DBDao().updateChild(widget.args.child);
    showSnackbar("Updated ${widget.args.child.name}'s name", context);
  }

  onChildDeleted(int id) async {
    try {
      await DBDao().deleteChild(id);
      widget.args.reloadChildren();
      showSnackbar("Child deleted", context);
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e, st) {
      showSnackbar("Unable to delete child", context);
      log("An error occurred deleting a child: $e, $st");
    }
  }

  onOptionsSelected(context, item) async {
    final _picker = ImagePicker();
    final XFile? lost;
    if (Platform.isAndroid) {
      lost = (await _picker.retrieveLostData()).file;
    } else {
      lost = null;
    }

    if (item == 0 || item == 1) {
      String? path;
      if (lost != null) {
        path = lost.path;
      } else {
        XFile? photo;
        if (item == 0) {
          photo = await _picker.pickImage(source: ImageSource.gallery);
        } else {
          photo = await _picker.pickImage(source: ImageSource.camera);
        }
        if (photo != null) {
          path = photo.path;
        }
      }
      if (path != null) {
        widget.args.child.imagePath = path;
        await DBDao().updateChild(widget.args.child);
        updateChildImage(widget.args.child);
        showSnackbar("Updated ${widget.args.child.name}'s photo", context);
      }
    } else if (item == 2) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(
                  'Enter the new name',
                  style: smallTextStyle,
                ),
                content: TextField(
                  controller: changeNameController,
                ),
                actions: [
                  ElevatedButton(
                    style: enabledButtonStyle,
                    onPressed: () => onNameChanged(),
                    child: Text(
                      'Save',
                      style: smallTextStyle,
                    ),
                  ),
                ],
              ),
          barrierDismissible: true);
    } else if (item == 3) {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text(
                  'Are you sure you want to remove ${widget.args.child.name}?',
                  style: smallTextStyle,
                ),
                actions: [
                  ElevatedButton(
                    style: warningButtonStyle,
                    onPressed: () => onChildDeleted(widget.args.child.id!),
                    child: Text(
                      'Yes',
                      style: smallTextStyle,
                    ),
                  ),
                  ElevatedButton(
                    style: enabledButtonStyle,
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: smallTextStyle,
                    ),
                  )
                ],
              ),
          barrierDismissible: true);
    }
  }

  updateChildImage(Child child) {
    imageCache.clear();
    imageCache.clearLiveImages();
    setState(() {
      widget.args.child = child;
    });
    widget.args.reloadChildren();
  }

  @override
  Widget build(BuildContext context) {
    owedNewAmount = widget.args.child.amountOwed;
    allowanceNewAmount = widget.args.child.allowanceAmount;
    owedTextField = getTextField(true, owedNewAmount, "Amount", owedOnChanged);
    allowanceTextField =
        getTextField(true, allowanceNewAmount, "Amount", allowanceOnChanged);
    payTextField = getTextField(false, payAmount, "Amount", payOnChanged);
    deductTextField =
        getTextField(false, deductAmount, "Amount", deductOnChanged);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.args.child.name),
        actions: [
          PopupMenuButton<int>(
              onSelected: (item) => onOptionsSelected(context, item),
              itemBuilder: (context) => [
                    const PopupMenuItem<int>(
                        value: 0, child: Text('Choose new photo')),
                    const PopupMenuItem<int>(
                        value: 1, child: Text('Take new photo')),
                    const PopupMenuItem<int>(
                        value: 2, child: Text('Edit name')),
                    const PopupMenuItem<int>(
                        value: 3, child: Text('Remove child'))
                  ])
        ],
      ),
      body: ListView(children: [
        Container(
            padding: const EdgeInsets.only(top: 16),
            child: Align(
              child: Card(
                child: Image.file(File(widget.args.child.imagePath),
                    height: 200,
                    width: 200,
                    fit: BoxFit.contain,
                    key: UniqueKey()),
              ),
            )),
        getToggleableEditRow(
            showEditSymbol: true,
            editActivated: owedEditable,
            label: "Owed: \$",
            textField: owedTextField,
            onEditClicked: owedOnEditClicked),
        getToggleableEditRow(
            showEditSymbol: true,
            editActivated: allowanceEditable,
            label: "Allowance: \$",
            textField: allowanceTextField,
            onEditClicked: allowanceOnEditClicked),
        getToggleableEditRow(
          showEditSymbol: false,
          label: "Pay: \$",
          textField: payTextField,
          editActivated: true,
        ),
        getToggleableEditRow(
          showEditSymbol: false,
          label: "Deduct: \$",
          textField: deductTextField,
          editActivated: true,
        ),
        Container(
          padding: const EdgeInsets.only(top: 25),
          width: double.infinity,
          child:
              Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
            ElevatedButton(
              style: enabledButtonStyle,
              onPressed: () => onSubmit(),
              child: Text(
                'Save',
                style: medTextStyle,
              ),
            ),
          ]),
        )
      ]),
    );
  }

  Widget getImageRow(String url) {
    return Container(
        padding: const EdgeInsets.only(top: 16),
        child: Align(
          child: Card(
            child: Image.file(File(widget.args.child.imagePath),
                height: 200, width: 200, fit: BoxFit.contain, key: UniqueKey()),
          ),
        ));
  }

  TextField getTextField(bool autoFocus, double initialValue, String inputLabel,
      Function onChanged) {
    return TextField(
      autofocus: autoFocus,
      controller: TextEditingController()
        ..text = initialValue.toStringAsFixed(2),
      keyboardType:
          const TextInputType.numberWithOptions(signed: false, decimal: true),
      inputFormatters: [DollarsInputFormatter()],
      decoration: getInputDecoration(inputLabel),
      style: smallTextStyle,
      onChanged: (text) => onChanged(text),
    );
  }

  Widget getToggleableEditRow(
      {required String label,
      required TextField textField,
      required bool editActivated,
      required bool showEditSymbol,
      Function? onEditClicked}) {
    if (showEditSymbol && onEditClicked == null) {
      throw ArgumentError(
          "onEditClicked must be provided if showEditSymbol is true");
    }
    return Center(
        child: Container(
            padding: const EdgeInsets.only(top: 16),
            child: SizedBox(
                width: double.infinity,
                height: 50,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: medTextStyle,
                    ),
                    (() {
                      if (editActivated) {
                        return SizedBox(
                          width: 100,
                          child: textField,
                        );
                      } else {
                        return Text(
                          textField.controller?.text ?? "0.00",
                          style: medTextStyle,
                        );
                      }
                    }()),
                    (() {
                      if (showEditSymbol) {
                        return Container(
                            padding: const EdgeInsets.only(left: 10),
                            child: InkWell(
                                onTap: () => onEditClicked!(),
                                child: Icon(Icons.edit,
                                    color: (() {
                                      if (!editActivated) {
                                        return Colors.black;
                                      } else {
                                        return Colors.grey;
                                      }
                                    }()))));
                      }
                      return Container();
                    }())
                  ],
                ))));
  }
}
