import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:food_delivery_app/service/language_provider.dart';

class NavBar extends StatelessWidget {
  final void Function(int)? onTabChange;

  const NavBar({super.key, required this.onTabChange});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        final translations = languageProvider.translations;

        return Container(
          padding: const EdgeInsets.all(8),
          child: GNav(
            color: Colors.blue,
            activeColor: Colors.white,
            tabBackgroundColor: const Color.fromARGB(255, 0, 98, 150),
            mainAxisAlignment: MainAxisAlignment.center,
            tabBorderRadius: 20,
            onTabChange: (value) => onTabChange!(value),
            tabs: [
              GButton(
                icon: Icons.home,
                text: translations['home'] ?? 'Home',
              ),
              GButton(
                icon: Icons.timer,
                text: translations['activity'] ?? 'Activity',
              ),
              GButton(
                icon: FontAwesomeIcons.bell,
                text: translations['notifications'] ?? 'Notifications',
              ),
              GButton(
                icon: Icons.settings,
                text: translations['settings'] ?? 'Settings',
              ),
            ],
          ),
        );
      },
    );
  }
}
