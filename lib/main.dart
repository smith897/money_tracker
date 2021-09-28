import 'package:flutter/material.dart';
import 'package:money_tracker/child_view.dart';

import 'home_page.dart';

void main() {
  runApp(MaterialApp(
      title: "Money Tracker",
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      initialRoute: HomePageHolder.route,
      routes: {
        HomePageHolder.route: (_) => const HomePageHolder(),
        ChildViewHolder.route: (context) => ChildViewHolder(
            ModalRoute.of(context)!.settings.arguments
                as ChildViewHolderArguments),
      }));
}
