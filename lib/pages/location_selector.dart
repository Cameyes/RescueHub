import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:provider/provider.dart';

class LocationSelector extends StatefulWidget {
  final String initialLocation;

  const LocationSelector({super.key, required this.initialLocation});

  @override
  _LocationSelectorState createState() => _LocationSelectorState();
}

class _LocationSelectorState extends State<LocationSelector> {
  String? selectedLoc;
  int currentIconIndex = 0;
  final int totalIcons = 7;

  // Data structure to store location information
  final List<LocationInfo> locationData = [
    LocationInfo(
      icon: Icons.home,
      title: 'Shelter',
      description: 'Find safe and comfortable temporary accommodations during emergencies. Our platform connects you with nearby hosts offering space for individuals or families, ensuring security and peace of mind.',
    ),
    LocationInfo(
      icon: FontAwesomeIcons.shirt,
      title: 'Cloth',
      description: 'Obtain essential clothing to meet your needs and stay comfortable in all conditions. Donors and volunteers ensure timely distribution, prioritizing dignity and well-being.',
    ),
    LocationInfo(
      icon: Icons.local_hospital,
      title: 'Medical Assistance',
      description: 'Receive critical healthcare support, from first aid to professional medical services. Our network of doctors, nurses, and paramedics ensures timely care when it matters most.',
    ),
    LocationInfo(
      icon: FontAwesomeIcons.droplet,
      title: 'Blood Donors',
      description: ' Quickly connect with verified blood donors in your vicinity for urgent requirements. The platform bridges the gap between donors and recipients, saving lives with every contribution.',
    ),
    LocationInfo(
      icon: FontAwesomeIcons.truckMedical,
      title: 'Ambulance Drivers',
      description: 'Locate reliable ambulance services to transport patients during emergencies. Experienced drivers ensure rapid and safe transit to medical facilities.',
    ),
    LocationInfo(
      icon: FontAwesomeIcons.fireExtinguisher,
      title: 'Fire and Safety',
      description: 'Access critical fire and safety resources to protect life and property during crises. Partnering with trained professionals, we provide swift action to mitigate risks and damages.',
    ),
    LocationInfo(
      icon: Icons.shield,
      title: 'Disaster Preparedness',
      description: ' Learn essential survival tips and strategies to stay prepared for any emergency. Equip yourself with knowledge and tools to safeguard yourself and your loved ones.',
    ),
    LocationInfo(
      icon: FontAwesomeIcons.language,
      title: 'Multilanguage Support',
      description: ' Navigate the platform in your preferred language for a seamless experience. Our multilingual interface ensures accessibility for diverse users worldwide.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedLoc = widget.initialLocation;
    startIconAnimation();
  }

  void startIconAnimation() {
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          currentIconIndex = (currentIconIndex + 1) % locationData.length;
        });
        startIconAnimation();
      }
    });
  }

  Widget buildIconWithDialog(int index) {
    Provider.of<ThemeProvider>(context);
    return Column(
      children: [
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12)
              ),
              child: Icon(locationData[index].icon, size: 40, color: Colors.black),
            ),
          ],
        ),
      ],
    );
  }

  Widget buildBottomDialog(int index) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: themeProvider.isDarkMode ? Colors.grey[800] : Colors.blue,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            locationData[index].title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            locationData[index].description,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: themeProvider.isDarkMode ? Colors.grey[300] : Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Center(
          child: Text(
            "Select Location",
            style: TextStyle(color: Colors.white),
          ),
        ),
        backgroundColor: themeProvider.isDarkMode ? Colors.grey[600] : Colors.blue,
      ),
      body: Column(
        children: [
          const SizedBox(height: 25),
          Container(
            height: 75,
            width: 75,
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20)
            ),
            child: const Center(
              child: Text(
                "Rescue\nHub",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Center(
            child: Text(
              "Please select your location",
              style: TextStyle(
                color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 25),
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.near_me_rounded,
                  color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900],
                  size: 20,
                ),
                const SizedBox(width: 10),
                DropdownButton<String>(
                  dropdownColor: themeProvider.isDarkMode ? Colors.grey[900] : Colors.white,
                  value: selectedLoc,
                  iconSize: 40,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedLoc = newValue!;
                    });
                  },
                  items: <String>['Thrissur', 'Palakkad', 'Eranakulam']
                      .map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(
                          color: themeProvider.isDarkMode ? Colors.white : Colors.grey[900]
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
          Center(child: Text("App Features",
          style: TextStyle(
            color: themeProvider.isDarkMode?Colors.grey[600]:Colors.blue,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          )),
          const SizedBox(height: 15,),
          SizedBox(
            width: double.infinity,
            height: 120,
            //color: themeProvider.isDarkMode ? Colors.grey[700] : const Color.fromARGB(255, 248, 204, 232),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 500),
                transitionBuilder: (Widget child, Animation<double> animation) {
                  return SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(1.0, 0.0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  );
                },
                child: Center(
                  key: ValueKey<int>(currentIconIndex),
                  child: buildIconWithDialog(currentIconIndex),
                ),
              ),
            ),
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              transitionBuilder: (Widget child, Animation<double> animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0.0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: buildBottomDialog(currentIconIndex),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context, selectedLoc);
        },
        child: const Icon(Icons.check),
      ),
    );
  }
}

class LocationInfo {
  final IconData icon;
  final String title;
  final String description;

  LocationInfo({
    required this.icon,
    required this.title,
    required this.description,
  });
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool isUpsideDown;

  TrianglePainter({
    required this.color,
    this.isUpsideDown = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    if (isUpsideDown) {
      path.moveTo(size.width / 2, size.height);
      path.lineTo(0, 0);
      path.lineTo(size.width, 0);
    } else {
      path.moveTo(0, 0);
      path.lineTo(size.width / 2, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}