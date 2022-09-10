import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:money_tracker/child_view.dart';
import 'package:money_tracker/database.dart';
import 'package:money_tracker/styles.dart';
import 'package:money_tracker/utils.dart';

import 'database.dart';

class HomePageHolder extends StatefulWidget {
  static const String route = "/";

  const HomePageHolder({Key? key}) : super(key: key);
  @override
  State createState() => HomePage();
}

class HomePage extends State<HomePageHolder> {
  var children = DBDao().getChildren();

  TextEditingController addChildText = TextEditingController();
  String? addChildImagePath;

  onChildTap(BuildContext context, Child child) {
    final args = ChildViewHolderArguments(child, reloadChildren);
    Navigator.of(context).pushNamed(ChildViewHolder.route, arguments: args);
  }

  reloadChildren() {
    imageCache.clear();
    imageCache.clearLiveImages();
    setState(() {
      children = DBDao().getChildren();
    });
  }

  onAddChildPressed() async {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                'Enter the new child\'s name',
                style: smallTextStyle,
              ),
              content: TextField(
                controller: addChildText,
              ),
              actionsAlignment: MainAxisAlignment.center,
              actions: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      style: smallEnabledButtonStyle,
                      onPressed: () => onTakePhotoPressed(),
                      child: Text(
                        'Take Photo',
                        style: smallTextStyle,
                      ),
                    ),
                    ElevatedButton(
                      style: smallEnabledButtonStyle,
                      onPressed: () => onChoosePhotoPressed(),
                      child: Text(
                        'Choose Photo',
                        style: smallTextStyle,
                      ),
                    ),
                    ElevatedButton(
                      style: enabledButtonStyle,
                      onPressed: () => onAddChildConfirmed(
                          addChildText.text, addChildImagePath),
                      child: Text(
                        'Add Child',
                        style: smallTextStyle,
                      ),
                    )
                  ],
                ),
              ],
            ),
        barrierDismissible: true);
  }

  onAddChildConfirmed(String name, String? imagePath) async {
    if (name.isEmpty || addChildImagePath == null) {
      showSnackbar("Please add a name and a photo", context);
      return;
    }

    addChildImagePath = null;
    addChildText.text = "";
    await DBDao().insertChild(Child(
        name: name, amountOwed: 0, allowanceAmount: 0, imagePath: imagePath!));
    setState(() {
      children = DBDao().getChildren();
    });
    reloadChildren();
    Navigator.of(context).pop();
    showSnackbar("$name has been added", context);
  }

  onTakePhotoPressed() async {
    try {
      final _picker = ImagePicker();
      final XFile? lost;
      if (Platform.isAndroid) {
        lost = (await _picker.retrieveLostData()).file;
      } else {
        lost = null;
      }

      String? currPath;
      if (lost != null) {
        currPath = lost.path;
      } else {
        XFile? photo;
        photo = await _picker.pickImage(source: ImageSource.camera);
        if (photo != null) {
          currPath = photo.path;
        }
      }
      if (currPath != null) {
        addChildImagePath = currPath;
        showSnackbar("Photo added", context);
      }
    } catch (e, st) {
      showSnackbar(
          "Unable to take photo. You may need to enable camera permission in system settings",
          context);
      log("Unable to get picture: $e, $st");
    }
  }

  onChoosePhotoPressed() async {
    try {
      final _picker = ImagePicker();
      final XFile? lost;
      if (Platform.isAndroid) {
        lost = (await _picker.retrieveLostData()).file;
      } else {
        lost = null;
      }

      String? currPath;
      if (lost != null) {
        currPath = lost.path;
      } else {
        XFile? photo;
        photo = await _picker.pickImage(source: ImageSource.gallery);
        if (photo != null) {
          currPath = photo.path;
        }
      }
      if (currPath != null) {
        addChildImagePath = currPath;
        showSnackbar("Photo added", context);
      }
    } catch (e, st) {
      showSnackbar(
          "Unable to choose photo. You may need to enable camera permission in system settings",
          context);
      log("Unable to get picture: $e, $st");
    }
  }

  onChangeThemePressed() async {
    // TODO Implement
    showSnackbar(
        "This feature hasn't been implemented yet. Coming soon!", context);
  }

  onOptionsSelected(context, item) async {
    switch (item) {
      case 0:
        onAddChildPressed();
        break;
      case 1:
        onChangeThemePressed();
        break;
    }
  }

  onPayAllowancePressed() {
    showDialog(
        context: context,
        builder: (context) => AlertDialog(
              title: Text(
                'Are you sure you want to pay allowance?',
                style: smallTextStyle,
              ),
              actions: [
                ElevatedButton(
                  style: warningButtonStyle,
                  onPressed: () {
                    onPayAllowanceConfirmed();
                    Navigator.of(context).pop();
                  },
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

  onPayAllowanceConfirmed() async {
    final children = await DBDao().getChildren();
    try {
      for (var child in children) {
        child.amountOwed += child.allowanceAmount;
        await DBDao().updateChild(child);
      }
      reloadChildren();
      showSnackbar("Paid allowance to ${children.length} children", context);
    } catch (e, st) {
      showSnackbar(
          "An error has occurred. Please report this to the developer.",
          context);
      log("Error: $e\n$st");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Money Tracker"),
        actions: [
          PopupMenuButton<int>(
              onSelected: (item) => onOptionsSelected(context, item),
              itemBuilder: (context) => [
                    const PopupMenuItem<int>(
                        value: 0, child: Text('Add a child')),
                    const PopupMenuItem<int>(
                        value: 1, child: Text('Change theme')),
                  ])
        ],
      ),
      body: FutureBuilder<List<Child>>(
          future: children,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              List<Child> children = snapshot.data!;
              return GridView.builder(
                itemCount: children.length,
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    childAspectRatio: 1,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10),
                itemBuilder: (BuildContext context, index) {
                  return InkWell(
                      onTap: () => onChildTap(context, children[index]),
                      child: Card(
                        child: Image.file(File(children[index].imagePath),
                            height: 100, width: 100),
                      ));
                },
              );
            } else if (snapshot.hasError) {
              log(snapshot.error.toString());
              return const Text(
                  "An error has occurred. Please report this to the developer.");
            }
            return Container();
          }),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.attach_money),
        onPressed: () => onPayAllowancePressed(),
      ),
    );
  }
}
