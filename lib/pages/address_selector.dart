import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_google_maps_webservices/places.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';


class AddressSelector extends StatefulWidget {
  const AddressSelector({super.key});

  @override
  _AddressSelectorState createState() => _AddressSelectorState();
}

class _AddressSelectorState extends State<AddressSelector> {
  LatLng? selectedLocation;
  final places = GoogleMapsPlaces(apiKey: 'AIzaSyCpDn4zTqIWLIsTvuoO_xioZTeOnI6mtqc');
  final searchController = TextEditingController();

  void searchPlaces(String query) async {
    if (query.isEmpty) return;

    final response = await places.searchByText(query);

    if (response.status == "OK" && response.results.isNotEmpty) {
      final place = response.results.first;
      final location = LatLng(
        place.geometry!.location.lat,
        place.geometry!.location.lng,
      );
      
      setState(() {
        selectedLocation = location;
      });

      final controller = await _controller.future;
      controller.animateCamera(
        CameraUpdate.newLatLngZoom(location, 15),
      );
    }
  }

  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select Location"),
        actions: [
          IconButton(
            icon: Icon(Icons.check),
            onPressed: () {
              if (selectedLocation != null) {
                Navigator.pop(context, selectedLocation);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Please select a location")),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: searchController,
              decoration: InputDecoration(
                hintText: 'Search location',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onSubmitted: searchPlaces,
            ),
          ),
          Expanded(
            child: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(10.1632, 76.6413),
                zoom: 12,
              ),
              onMapCreated: (GoogleMapController controller) {
                _controller.complete(controller);
              },
              onTap: (LatLng location) {
                setState(() {
                  selectedLocation = location;
                });
              },
              markers: selectedLocation != null
                  ? {
                      Marker(
                        markerId: MarkerId("selected-location"),
                        position: selectedLocation!,
                      ),
                    }
                  : {},
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    places.dispose();
    searchController.dispose();
    super.dispose();
  }
}