import 'package:flutter/material.dart';
import '../utils/constants.dart';

class DeliveryDashboard extends StatefulWidget {
  final String courierId;
  final String courierName;

  const DeliveryDashboard({
    Key? key,
    required this.courierId,
    required this.courierName,
  }) : super(key: key);

  @override
  State<DeliveryDashboard> createState() => _DeliveryDashboardState();
}

class _DeliveryDashboardState extends State<DeliveryDashboard> {
  String _status = 'available'; // available, busy, offline

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 2,
          title: Text(
            'لوحة المندوب: ${widget.courierName}',
            style: const TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: const Color(0xFF1E1E1E),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: AppConstants.gold.withOpacity(0.2)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.toggle_on, color: AppConstants.gold, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'تحديث حالة التوفر:',
                            style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          backgroundColor: const Color(0xFF121212),
                          foregroundColor: Colors.white70,
                          selectedBackgroundColor: AppConstants.gold,
                          selectedForegroundColor: Colors.black,
                        ),
                        segments: const [
                          ButtonSegment(
                            value: 'available', 
                            label: Text('متاح', style: TextStyle(fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.check_circle_outline, size: 16),
                          ),
                          ButtonSegment(
                            value: 'busy', 
                            label: Text('مشغول', style: TextStyle(fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.hourglass_empty, size: 16),
                          ),
                          ButtonSegment(
                            value: 'offline', 
                            label: Text('خارج الخدمة', style: TextStyle(fontWeight: FontWeight.bold)),
                            icon: Icon(Icons.offline_bolt_outlined, size: 16),
                          ),
                        ],
                        selected: {_status},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() {
                            _status = newSelection.first;
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('تم تحديث حالتك إلى: ${_status == 'available' ? 'متاح 🟢' : _status == 'busy' ? 'مشغول 🟡' : 'خارج الخدمة 🔴'}=')),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 25),
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppConstants.gold.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.local_shipping_outlined, size: 50, color: AppConstants.gold),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'الطلبات المسندة لك ستظهر هنا فور قبولها من المشرف 📦',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey, fontSize: 14, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
