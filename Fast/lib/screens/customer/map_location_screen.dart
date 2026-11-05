import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../utils/constants.dart'; // 👈 تصحيح مسار الاستيراد للصعود مستويين

class MapLocationScreen extends StatefulWidget {
  const MapLocationScreen({Key? key}) : super(key: key);

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  GoogleMapController? _controller;
  
  // إحداثيات تعز الافتراضية (منطقة ديلوكس / شارع جمال)
  static const LatLng _taizDefault = LatLng(13.5779, 44.0219);
  LatLng _selectedLatLng = _taizDefault;
  String _selectedAddressName = 'تعز - ديلوكس / بجوار الشارع العام';
  bool _isLoadingGps = false;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  // جلب الموقع الحالي عبر الـ GPS
  Future<void> _determinePosition() async {
    setState(() => _isLoadingGps = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoadingGps = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoadingGps = false);
          return;
        }
      }

      // 💡 تم تحديث الاستدعاء ليتوافق مع أحدث إصدارات مكتبة geolocator بدون أخطاء
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      LatLng currentLatLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLatLng = currentLatLng;
        _selectedAddressName = 'موقعي الحالي (تعز)';
        _isLoadingGps = false;
      });

      _controller?.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: currentLatLng, zoom: 16.5),
        ),
      );
    } catch (e) {
      setState(() => _isLoadingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF1E1E1E);
    const backgroundColor = Color(0xFF121212);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: cardColor,
          // 💡 إزالة const لتجنب خطأ Not a constant expression مع AppConstants.gold
          title: Text('حدد موقع منزلك على خريطة جوجل', style: TextStyle(color: AppConstants.gold, fontSize: 15, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: AppConstants.gold),
            onPressed: () => Navigator.pop(context, _selectedAddressName),
          ),
        ),
        body: Stack(
          children: [
            // خريطة جوجل الحقيقية
            GoogleMap(
              initialCameraPosition: const CameraPosition(
                target: _taizDefault,
                zoom: 15.0,
              ),
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (GoogleMapController controller) {
                _controller = controller;
              },
              onCameraMove: (CameraPosition position) {
                setState(() {
                  _selectedLatLng = position.target;
                  _selectedAddressName = 'تعز (خط عرض: ${_selectedLatLng.latitude.toStringAsFixed(4)}, خط طول: ${_selectedLatLng.longitude.toStringAsFixed(4)})';
                });
              },
            ),

            // دبوس التحديد الثابت في منتصف الخريطة (لتحديد المنزل)
            const Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 40),
                child: Icon(Icons.location_pin, size: 55, color: Colors.redAccent),
              ),
            ),

            // زر تحديد الموقع الحالي (GPS)
            Positioned(
              top: 20,
              left: 20,
              child: FloatingActionButton(
                backgroundColor: cardColor,
                child: _isLoadingGps 
                    ? CircularProgressIndicator(color: AppConstants.gold) 
                    : Icon(Icons.my_location, color: AppConstants.gold),
                onPressed: _determinePosition,
              ),
            ),

            // شريط العنوان السفلي مع زر التثبيت
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppConstants.gold.withOpacity(0.4)),
                  boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.home, color: AppConstants.gold),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _selectedAddressName,
                            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.gold,
                        minimumSize: const Size(double.infinity, 45),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () {
                        // إرجاع العنوان والموقع المختار عند النقر
                        Navigator.pop(context, _selectedAddressName);
                      },
                      child: const Text('تثبيت هذا الموقع وعودة', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
