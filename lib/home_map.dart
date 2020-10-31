import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_webservice/places.dart';
import 'package:flutter_google_places/flutter_google_places.dart';
import 'package:share/share.dart';

class HomeMap extends StatefulWidget {
  const HomeMap({Key key}) : super(key: key);

  @override
  _HomeMapState createState() => _HomeMapState();
}

class _HomeMapState extends State<HomeMap> {
  Set<Marker> _mapMarkers = Set();
  Set<Polyline> _polyline = Set();
  GoogleMapController _mapController;
  Position _currentPosition;
  Position _defaultPosition = Position(
    longitude: 20.608148,
    latitude: -103.417576,
  );
  TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _getCurrentPosition(),
      builder: (context, result) {
        if (result.error == null) {
          if (_currentPosition == null) _currentPosition = _defaultPosition;
          return Scaffold(
            body: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentPosition.latitude,
                      _currentPosition.longitude,
                    ),
                  ),
                  polylines: _polyline,
                  onMapCreated: _onMapCreated,
                  markers: _mapMarkers,
                  onLongPress: _setMarker,
                ),
                Positioned(
                  top: 32,
                  right: 16,
                  left: 16,
                  child: Container(
                    color: Colors.white,
                    child: Row(
                      children: <Widget>[
                        IconButton(
                          splashColor: Colors.grey,
                          icon: Icon(Icons.menu),
                          onPressed: () {},
                        ),
                        Expanded(
                          child: TextField(
                            onTap: _searchAddress,
                            cursorColor: Colors.black,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(
                                border: InputBorder.none,
                                contentPadding:
                                    EdgeInsets.symmetric(horizontal: 15),
                                hintText: "Buscar..."),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: SingleChildScrollView(
              child: Column(
                children: [
                  FloatingActionButton(
                    onPressed: () {
                      _drawPolygon();
                    },
                    child: Icon(Icons.format_shapes),
                  ),
                  FloatingActionButton(
                    onPressed: () async {
                      await _getCurrentPosition();
                      _mapController.animateCamera(
                        CameraUpdate.newCameraPosition(
                          CameraPosition(
                            target: LatLng(
                              _currentPosition.latitude,
                              _currentPosition.longitude,
                            ),
                            zoom: 15.0,
                          ),
                        ),
                      );
                    },
                    child: Icon(Icons.my_location),
                  ),
                ],
              ),
            ),
          );
        } else {
          Scaffold(
            body: Center(
              child: Text("Se ha producido un error"),
            ),
          );
        }
        return Scaffold(
          body: Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );
  }

  void _searchAddress() async {
    Prediction prediction = await PlacesAutocomplete.show(
      context: context,
      apiKey: "AIzaSyAEHDanWw3QT_ZJZrYAOiIefDja6ucoVcY",
      mode: Mode.overlay,
    );
    if (prediction == null) {
      return;
    }

    GoogleMapsPlaces _places =
        new GoogleMapsPlaces(apiKey: "AIzaSyAEHDanWw3QT_ZJZrYAOiIefDja6ucoVcY");
    PlacesDetailsResponse detail =
        await _places.getDetailsByPlaceId(prediction.placeId);
    double latitude = detail.result.geometry.location.lat;
    double longitude = detail.result.geometry.location.lng;
    _currentPosition = Position(latitude: latitude, longitude: longitude);
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            latitude,
            longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  void _onMapCreated(GoogleMapController controller) {
    setState(() {
      _mapController = controller;
    });
  }

  void _displayBottomSheet(MarkerId markerId) async {
    Marker marker =
        _mapMarkers.firstWhere((element) => element.markerId == markerId);
    List<Placemark> placeMark = await placemarkFromCoordinates(
        marker.position.latitude, marker.position.longitude);
    showModalBottomSheet(
        context: context,
        builder: (BuildContext bc) {
          return Container(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].name}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].street}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].subLocality}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].locality}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].subAdministrativeArea}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].administrativeArea}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].postalCode}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].country}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].isoCountryCode}"),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("${placeMark[0].hashCode}"),
                  ),
                ],
              ),
            ),
          );
        });
  }

  void _drawPolygon() {
    setState(() {
      _polyline.clear();
      List<LatLng> points = _mapMarkers.map((e) => e.position).toList();
      _polyline.add(
        Polyline(
          color: Colors.red,
          polylineId: PolylineId("0"),
          points: points,
        ),
      );
    });
  }

  void _setMarker(LatLng coord) async {
    // get address
    String _markerAddress = await _getGeocodingAddress(
      Position(
        latitude: coord.latitude,
        longitude: coord.longitude,
      ),
    );

    // add marker
    setState(() {
      _mapMarkers.add(
        Marker(
          markerId: MarkerId(coord.toString()),
          position: coord,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
          onTap: () {
            _displayBottomSheet(
              MarkerId(
                coord.toString(),
              ),
            );
          },
        ),
      );
    });
  }

  Future<void> _getCurrentPosition() async {
    // verify permissions
    LocationPermission permission = await checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      permission = await requestPermission();
    }

    // get current position
    _currentPosition =
        await getCurrentPosition(desiredAccuracy: LocationAccuracy.high);

    // get address
    String _currentAddress = await _getGeocodingAddress(_currentPosition);

    // add marker
    _mapMarkers.add(
      Marker(
        markerId: MarkerId(_currentPosition.toString()),
        position: LatLng(_currentPosition.latitude, _currentPosition.longitude),
      ),
    );

    // move camera
    _mapController.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(
            _currentPosition.latitude,
            _currentPosition.longitude,
          ),
          zoom: 15.0,
        ),
      ),
    );
  }

  Future<String> _getGeocodingAddress(Position position) async {
    // geocoding
    var places = await placemarkFromCoordinates(
      position.latitude,
      position.longitude,
    );
    if (places != null && places.isNotEmpty) {
      final Placemark place = places.first;
      return "${place.thoroughfare}, ${place.locality}";
    }
    return "No address available";
  }
}
