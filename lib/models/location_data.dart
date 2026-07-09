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

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'place_name': placeName,
      'address': address,
      'place_type': placeType,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory LocationData.fromJson(Map<String, dynamic> json) {
    return LocationData(
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      placeName: json['place_name']?.toString(),
      address: json['address']?.toString(),
      placeType: json['place_type']?.toString(),
    );
  }

  factory LocationData.fromMap(Map<String, dynamic> map) =>
      LocationData.fromJson(map);
}
