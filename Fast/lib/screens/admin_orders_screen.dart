import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';

class AdminOrdersScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const AdminOrdersScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    // جلب الطلبات لحظياً من قاعدة البيانات عبر الـ AppState
    final orders = context.watch<AppState>().orders;
    final appState = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: onOpenDrawer == null ? null : IconButton(icon: const Icon(Icons.menu), onPressed: onOpenDrawer),
        title: const Text('لوحة تحكم المشرف - الطلبات'),
      ),
      body: orders.isEmpty
          ? const EmptyState(
              message: 'لا توجد طلبات جديدة واردة حتى الآن\nالطلبات ستظهر هنا فور إرسالها من العملاء 📦',
              icon: Icons.admin_panel_settings_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                
                // استخراج بيانات الطلب بدقة من قاعدة البيانات
                final orderId = order['id']?.toString() ?? '';
                final customerName = order['customer_name']?.toString() ?? 'عميل';
                final phone = order['phone']?.toString() ?? '';
                final address = order['address']?.toString() ?? '';
                final itemsDesc = order['items_description']?.toString() ?? 'لا توجد تفاصيل';
                final productsTotal = double.tryParse(order['products_total']?.toString() ?? '0') ?? 0.0;
                final deliveryFee = double.tryParse(order['delivery_fee']?.toString() ?? '0') ?? 0.0;
                final totalPrice = double.tryParse(order['total_price']?.toString() ?? '0') ?? 0.0;
                final status = order['status']?.toString() ?? 'waitingForPricing';
                final assignedCourier = order['assigned_courier']?.toString() ?? 'لم يتم التعيين';
                final adminMessage = order['admin_message']?.toString() ?? '';

                return Card(
                  color: Theme.of(context).colorScheme.surface,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // --- رأس الكارت (رقم الطلب والحالة) ---
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'طلب #$orderId',
                              style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold, fontSize: 16),
                            ),
                            Chip(
                              label: Text(
                                _getStatusText(status),
                                style: const TextStyle(fontSize: 11, color: Colors.black, fontWeight: FontWeight.bold),
                              ),
                              backgroundColor: AppConstants.gold,
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // --- بيانات العميل والطلب ---
                        Text('👤 العميل: $customerName', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('📞 الهاتف: $phone'),
                        Text('📍 العنوان: $address'),
                        const SizedBox(height: 6),
                        Text('🛒 تفاصيل المنتجات: $itemsDesc', style: const TextStyle(color: Colors.white70)),
                        const Divider(height: 20),

                        // --- الحسابات المالية ---
                        Text('سعر المنتجات: $productsTotal ر.ي'),
                        Text('رسوم التوصيل: $deliveryFee ر.ي'),
                        Text('الإجمالي الكلي: $totalPrice ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold)),
                        const SizedBox(height: 6),
                        Text('🛵 المندوب المعين: $assignedCourier', style: const TextStyle(color: Colors.amber)),
                        
                        if (adminMessage.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text('💬 حالة المشرف: $adminMessage', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                        
                        const SizedBox(height: 12),

                        // --- زر تحديد رسوم التوصيل وإسناد المندوب (يظهر إذا كان الطلب بانتظار التسعير) ---
                        if (status == 'waitingForPricing')
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppConstants.gold,
                                foregroundColor: Colors.black,
                              ),
                              onPressed: () => _showPricingDialog(context, appState, orderId),
                              icon: const Icon(Icons.local_shipping),
                              label: const Text('تحديد رسوم التوصيل وإسناد المندوب 🚀', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- نافذة إدخال رسوم التوصيل واختيار المندوب ---
  void _showPricingDialog(BuildContext context, AppState appState, dynamic orderId) {
    final feeController = TextEditingController();
    String? selectedCourier;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('تحديد رسوم التوصيل للطلب #$orderId'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'رسوم التوصيل (ر.ي)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedCourier,
              hint: const Text('اختر المندوب للتوصيل'),
              items: appState.couriers.map<DropdownMenuItem<String>>((courier) {
                String courierName = courier['name']?.toString() ?? 'مندوب';
                return DropdownMenuItem<String>(
                  value: courierName,
                  child: Text(courierName),
                );
              }).toList(),
              onChanged: (val) {
                selectedCourier = val;
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.gold, foregroundColor: Colors.black),
            onPressed: () {
              double fee = double.tryParse(feeController.text) ?? 0.0;
              if (fee <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء إدخال رسوم توصيل صحيحة!')),
                );
                return;
              }
              if (selectedCourier == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('الرجاء اختيار مندوب للطلب!')),
                );
                return;
              }

              // إرسال الرسوم واسم المندوب لقاعدة البيانات وتنبيه العميل
              appState.setOrderDeliveryFee(orderId, fee, selectedCourier!);
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال رسوم التوصيل وإسناد المندوب للعميل بنجاح! 🚀')),
              );
            },
            child: const Text('إرسال للعميل'),
          ),
        ],
      ),
    );
  }

  // ترجمة حالات الطلب لعرضها بوضوح للمشرف
  String _getStatusText(String status) {
    switch (status) {
      case 'waitingForPricing': return 'بانتظار التسعير';
      case 'pricingSentToCustomer': return 'تم إرسال السعر للعميل';
      case 'waitingCourierApproval': return 'بانتظار قبول المندوب';
      case 'onTheWay': return 'المندوب في الطريق';
      case 'arrived': return 'وصل المندوب';
      case 'delivered': return 'تم التسليم بنجاح';
      case 'cancelledByCustomer': return 'ملغي من العميل';
      default: return status;
    }
  }
}
