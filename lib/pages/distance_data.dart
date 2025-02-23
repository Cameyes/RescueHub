class DistanceData {
  static final DistanceData _instance = DistanceData._internal();
  factory DistanceData() => _instance;
  DistanceData._internal();
  
  // Using a Map to store distances for each shelter ID
  final Map<String, double> _distances = {};

  // Method to set distance for a specific shelter
  void setDistance(String shelterId, double distance) {
    _distances[shelterId] = distance;
  }

  // Method to get distance for a specific shelter
  double getDistance(String shelterId) {
    return _distances[shelterId] ?? 0.0; // Return 0.0 if no distance is stored
  }
}