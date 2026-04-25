import 'package:flutter/material.dart';

import 'ui/feed_screen.dart';

class App extends StatelessWidget {
const App({super.key});

@override
Widget build(BuildContext context) {
  return MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'Social Feed',
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      useMaterial3: true,
    ),
    home: const FeedScreen(),
  );
}
}