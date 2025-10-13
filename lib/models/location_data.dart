class LocationData {
  final double latitude;
  final double longitude;
  final String? placeName;
  final String? address;
  final String? placeType;

  LocationData({
    required this.latitude,
    required this.longitude,
    this.placeName,
    this.address,
    this.placeType,
  });
}
