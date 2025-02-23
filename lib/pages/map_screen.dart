import 'package:flutter/material.dart';
import 'package:food_delivery_app/components/theme_provider.dart';
import 'package:food_delivery_app/pages/distance_data.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';

class MapScreen extends StatefulWidget {
  final double shelterLat, shelterLng, userLat, userLng, distance;
  final String distanceText,durationText,encodedPolyline,shelterId;

  const MapScreen({
    super.key,
    required this.shelterLat,
    required this.shelterLng,
    required this.userLat,
    required this.userLng,
    required this.distance,
    required this.distanceText,
    required this.durationText,
    required this.encodedPolyline,
    required this.shelterId,
  });

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};

   @override
  void initState() {
    super.initState();
    _setupMap();
     DistanceData().setDistance(widget.shelterId, widget.distance);
  }

  void _setupMap() {
    // Add markers for user and shelter
    
    _markers.add(
      Marker(
        markerId: MarkerId('shelter'),
        position: LatLng(widget.shelterLat, widget.shelterLng),
        infoWindow: InfoWindow(title: 'Shelter Location'),
      ),
    );

    _markers.add(
      Marker(
        markerId: MarkerId('user'),
        position: LatLng(widget.userLat, widget.userLng),
        infoWindow: InfoWindow(title: 'Your Location'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
      ),
    );

    // Decode and add the route polyline
    List<LatLng> polylinePoints = _decodePolyline(widget.encodedPolyline);
    _polylines.add(
      Polyline(
        polylineId: PolylineId('route'),
        points: polylinePoints,
        color: Colors.blue,
        width: 5,
      ),
    );
  }

  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }




  @override
  Widget build(BuildContext context) {
      final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar: AppBar(title: const Text("Shelter Location")),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(
          target: LatLng(
                  (widget.userLat + widget.shelterLat) / 2,
                  (widget.userLng + widget.shelterLng) / 2,
                ),
          zoom: 10,
        ),
        markers: _markers,
        polylines: _polylines,
        onMapCreated: (controller) => mapController = controller,
      ),
      bottomNavigationBar: Container(
        height: 75,
        padding: const EdgeInsets.all(10),
        color:themeProvider.isDarkMode?Colors.grey.shade800: Colors.white,
        child: Center(
          child: Text(
            "Distance: ${widget.distance.toStringAsFixed(2)} km",
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        
      ),
    );
  }
  
}

