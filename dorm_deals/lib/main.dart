import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:dorm_deals/firebase_options.dart';
import 'package:dorm_deals/state/listing_state.dart';
import 'package:dorm_deals/widgets/auth_widget.dart';
import 'package:firebase_core/firebase_core.dart';

var myLightColorScheme = ColorScheme.fromSeed(
  seedColor: const Color.fromARGB(255, 29, 112, 83),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (context) => ListingState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData().copyWith(
          colorScheme: myLightColorScheme,
          appBarTheme: AppBarTheme().copyWith(
            backgroundColor: myLightColorScheme.onPrimaryContainer,
            foregroundColor: myLightColorScheme.primaryContainer,
          ),
          cardTheme: CardThemeData().copyWith(
            color: myLightColorScheme.secondaryContainer,
          ),
        ),
        home: const AuthWidget(),
      ),
    ),
  );
}
