import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

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
  String _status = 'available';

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();
    final allOrders = appState.orders;

    final courierOrders = allOrders.where((order) {
      String assigned = order['assigned_courier']?.toString().trim() ?? '';
      return assigned == widget.courierName.trim() || assigned == widget.courierId;
    }).toList();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          title: Text(
            'لوحة المندوب: ${widget.courierName}',
            style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Card(
                color: const Color(0xFF1E1E1E),
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Text('تحديث حالتك الميدانية:', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        style: SegmentedButton.styleFrom(
                          backgroundColor: const Color(0xFF121212),
                          foregroundColor: Colors.white70,
                          selectedBackgroundColor: Colors.amber,
                          selectedForegroundColor: Colors.black,
                        ),
                        segments: const [
                          ButtonSegment(value: 'available', label: Text('متاح 🟢')),
                          ButtonSegment(value: 'busy', label: Text('مشغول 🟡')),
                          ButtonSegment(value: 'offline', label: Text('خارج الخدمة 🔴')),
                        ],
                        selected: {_status},
                        onSelectionChanged: (Set<String> newSelection) {
                          setState(() => _status = newSelection.first);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Align(
                alignment: Alignment.centerRight,
                child: Text('الطلبات المسندة إليك 📦', style: TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: courierOrders.isEmpty
                    ? const Center(child: Text('لا توجد طلبات مسندة لك حالياً', style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: courierOrders.length,
                        itemBuilder: (context, index) {
                          final order = courierOrders[index];
                          final orderId = order['id']?.toString() ?? '';
                          final customerName = order['customer_name']?.toString() ?? '';
                          final phone = order['phone']?.toString() ?? '';
                          final address = order['address']?.toString() ?? '';
                          final itemsDesc = order['items_description']?.toString() ?? '';
                          final totalPrice = order['total_price']?.toString() ?? '0';
                          final status = order['status']?.toString() ?? '';
                          
                          // معلومات الدفع للمندوب
                          final paymentMethod = order['payment_method'] ?? 'cash';
                          final paymentAccount = order['payment_account'] ?? '';
                          final paymentInfo = paymentMethod == 'cash' 
                              ? '💵 تحصيل نقدي من العميل عند الاستلام ($totalPrice ر.ي)' 
                              : '💳 مدفوع مسبقاً عبر ($paymentMethod) - حساب: $paymentAccount (لا تحصل نقداً)';

                          return Card(
                            color: const Color(0xFF1E1E1E),
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: Colors.amber.withOpacity(0.3)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('طلب #$orderId', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 15)),
                                      Text('إجمالي: $totalPrice ر.ي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                  const Divider(color: Colors.white12),
                                  Text('👤 العميل: $customerName ($phone)', style: const TextStyle(color: Colors.white70)),
                                  Text('📍 العنوان: $address', style: const TextStyle(color: Colors.white70)),
                                  const SizedBox(height: 6),
                                  Text('🛒 المنتجات: $itemsDesc', style: const TextStyle(color: Colors.white, fontSize: 13)),
                                  const SizedBox(height: 8),
                                  // 👈 تنبيه واضح للمندوب لطريقة الدفع
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: paymentMethod == 'cash' ? Colors.green.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: paymentMethod == 'cash' ? Colors.green : Colors.blueAccent),
                                    ),
                                    child: Text(paymentInfo, style: TextStyle(color: paymentMethod == 'cash' ? Colors.greenAccent : Colors.lightBlueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (status == 'waitingCourierApproval')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                          onPressed: () => appState.courierRespondToOrder(orderId, true),
                                          icon: const Icon(Icons.check, size: 16),
                                          label: const Text('قبول الطلب'),
                                        ),
                                      if (status == 'onTheWay')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, foregroundColor: Colors.black),
                                          onPressed: () => appState.courierUpdateArrival(orderId),
                                          icon: const Icon(Icons.location_pin, size: 16),
                                          label: const Text('وصلت لموقع العميل'),
                                        ),
                                      if (status == 'arrived')
                                        ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, foregroundColor: Colors.white),
                                          onPressed: () => appState.markOrderDelivered(orderId),
                                          icon: const Icon(Icons.done_all, size: 16),
                                          label: const Text('تم التسليم بنجاح ✅'),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
