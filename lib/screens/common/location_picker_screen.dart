import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../core/constants/colors.dart';

class LocationPickerScreen extends StatefulWidget {
  final double? initialLat;
  final double? initialLng;

  const LocationPickerScreen({
    super.key,
    this.initialLat,
    this.initialLng,
  });

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  static const LatLng _defaultCenter = LatLng(20.5937, 78.9629);
  LatLng? _selectedLocation;

  LatLng get _initialCameraTarget {
    if (widget.initialLat != null && widget.initialLng != null) {
      return LatLng(widget.initialLat!, widget.initialLng!);
    }
    return _defaultCenter;
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialLat != null && widget.initialLng != null) {
      _selectedLocation = LatLng(widget.initialLat!, widget.initialLng!);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Select Artisan Location'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: _initialCameraTarget,
                  zoom: widget.initialLat != null ? 14 : 4.5,
                ),
                onTap: (latLng) {
                  setState(() {
                    _selectedLocation = latLng;
                  });
                },
                markers: _selectedLocation == null
                    ? const <Marker>{}
                    : {
                        Marker(
                          markerId: const MarkerId('artisan_location'),
                          position: _selectedLocation!,
                        ),
                      },
                myLocationButtonEnabled: false,
                mapToolbarEnabled: false,
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: AppColors.primarySurface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedLocation == null
                      ? 'Tap on the map to set your artisan location'
                      : 'Location selected on map',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _selectedLocation == null
                        ? null
                        : () {
                            Navigator.of(context).pop(_selectedLocation);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryAccent,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: AppColors.softAccent,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Save Location'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
