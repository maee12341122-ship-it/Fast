import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../utils/constants.dart';

class MapLocationScreen extends StatefulWidget {
  const MapLocationScreen({Key? key}) : super(key: key);

  @override
  State<MapLocationScreen> createState() => _MapLocationScreenState();
}

class _MapLocationScreenState extends State<MapLocationScreen> {
  final TextEditingController _customAddressController = TextEditingController(text: 'تعز - ديلوكس / بجوار الشارع العام');

  // دالة لفتح متصفح الخرائط لمساعدة المستخدم في جلب إحداثياته أو مكانه
  Future<void> _openGoogleMapsSearch() async {
    final Uri url = Uri.parse('https://www.google.com/maps/@13.5779,44.0219,15z');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح متصفح الخرائط')),
        );
      }
    }
  }

  @override
  void dispose() {
    _customAddressController.dispose();
    super.dispose();
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
          title: Text('تحديد موقع التوصيل في تعز 📍', style: TextStyle(color: AppConstants.gold, fontSize: 15, fontWeight: FontWeight.bold)),
          leading: IconButton(
            icon: Icon(Icons.arrow_forward, color: AppConstants.gold),
            onPressed: () => Navigator.pop(context, _customAddressController.text.trim()),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppConstants.gold.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'أكتب عنوانك التفصيلي بدقة:',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _customAddressController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'مثال: تعز - ححي الروضة، قرب الشارع العام',
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: backgroundColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: Icon(Icons.location_on, color: AppConstants.gold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              
              // زر لفتح خرائط جوجل الخارجية للاستعانة بها
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppConstants.gold),
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: Icon(Icons.map, color: AppConstants.gold),
                label: Text('فتح خرائط جوجل للاستدلال 🗺️', style: TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold)),
                onPressed: _openGoogleMapsSearch,
              ),
              
              const Spacer(),

              // زر الحفظ النهائي والعودة
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.gold,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  Navigator.pop(context, _customAddressController.text.trim());
                },
                child: const Text('تثبيت العنوان والعودة ✅', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
