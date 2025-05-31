import 'package:flutter/material.dart';
import 'package:indoor_navigation/pages/ble_trilateration.dart';
import 'package:indoor_navigation/pages/find_me_page.dart';
import 'package:indoor_navigation/pages/fingerprinting_page.dart';

class HomeScreen extends StatefulWidget {
  /// Default constructor for [FindMePage] widget.
  const HomeScreen({super.key});

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // List of screens
  static final List<Widget> _screens = <Widget>[
    FingerprintingPage(),
    FindMePage(),
    BleTrilaterationPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_selectedIndex], // show the selected screen
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi),
            label: 'RF Fingerprint',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.location_pin),
            label: 'Find me',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bluetooth_searching_sharp),
            label: 'BLE Trilateration',
          ),
        ],
      ),
    );
  }
}