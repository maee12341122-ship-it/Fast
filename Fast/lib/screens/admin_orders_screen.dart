import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';

class AdminOrdersScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const AdminOrdersScreen({super.key, this.onOpenDrawer});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> with SingleTickerProviderStateMixin {
  // خريطة لتخزين حالة القفل لكل طلب على حدة (مفتاحها رقم الطلب)
  final Map<String, bool> _feeLockedState = {};

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().orders;
    final appState = context.read<AppState>();

    return Scaffold(
      appBar: AppBar(
        leading: widget.onOpenDrawer == null ? null : IconButton(icon: const Icon(Icons.menu), onPressed: widget.onOpenDrawer),
        title: const Text('لوحة تحكم المشرف - الطلبات'),
      ),
      body: orders.isEmpty
          ? const EmptyState(
              message: 'لا توجد طلبات جديدة واردة حتى الآن\nالطلبات ستظهر هنا فور إرسالها من العملاء 📦',
              icon: Icons.admin_panel_settings_outlined,
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              itemBuilder: (context, index) {
                final order = orders[index];
                
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

                // هل تم إرسال التسعيرة من قبل؟
                bool isLocked = _feeLockedState.putIfAbsent(
                  orderId, 
                  () => status != 'waitingForPricing'
                );

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  child: Card(
                    color: Theme.of(context).colorScheme.surface,
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: AppConstants.gold.withOpacity(0.2), width: 1),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // --- رأس الكارت (رقم الطلب والحالة بتصميم عصري) ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'طلب #$orderId',
                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold, fontSize: 16),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: AppConstants.gold.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: AppConstants.gold.withOpacity(0.4)),
                                ),
                                child: Text(
                                  _getStatusText(status),
                                  style: const TextStyle(fontSize: 11, color: AppConstants.gold, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 20, color: Colors.white12),

                          // --- بيانات العميل والطلب ---
                          Row(
                            children: [
                              const Icon(Icons.person, size: 16, color: AppConstants.gold),
                              const SizedBox(width: 6),
                              Text('العميل: $customerName', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone, size: 16, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text('الهاتف: $phone', style: const TextStyle(color: Colors.white70)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 6),
                              Expanded(child: Text('العنوان: $address', style: const TextStyle(color: Colors.white70))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.black26,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text('🛒 المنتجات: $itemsDesc', style: const TextStyle(color: Colors.white, fontSize: 13)),
                          ),
                          const Divider(height: 20, color: Colors.white12),

                          // --- الحسابات المالية مع خيار التعديل المقفل ---
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('سعر المنتجات: $productsTotal ر.ي', style: const TextStyle(color: Colors.white70)),
                              Text('رسوم التوصيل: $deliveryFee ر.ي', style: TextStyle(color: isLocked ? Colors.white70 : AppConstants.gold, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('الإجمالي الكلي: $totalPrice ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold, fontSize: 15)),
                              IconButton(
                                icon: Icon(
                                  isLocked ? Icons.edit : Icons.lock, 
                                  color: isLocked ? AppConstants.gold : Colors.greenAccent,
                                  size: 20,
                                ),
                                tooltip: isLocked ? 'تعديل رسوم التوصيل' : 'قفل الرسوم',
                                onPressed: () {
                                  setState(() {
                                    _feeLockedState[orderId] = !isLocked;
                                  });
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.delivery_dining, size: 16, color: Colors.amber),
                              const SizedBox(width: 6),
                              Text('المندوب: $assignedCourier', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          
                          if (adminMessage.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text('💬 حالة المشرف: $adminMessage', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          ],
                          
                          const SizedBox(height: 14),

                          // --- زر تحديد رسوم التوصيل وإسناد المندوب ---
                          if (status == 'waitingForPricing' || !isLocked)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppConstants.gold,
                                  foregroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () => _showPricingDialog(context, appState, orderId),
                                icon: const Icon(Icons.local_shipping),
                                label: Text(
                                  status == 'waitingForPricing' ? 'تحديد رسوم التوصيل وإسناد المندوب 🚀' : 'تحديث وإعادة إرسال التسعيرة 🔄', 
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  // --- نافذة إدخال رسوم التوصيل واختيار المندوب بتصميم متناسق ---
  void _showPricingDialog(BuildContext context, AppState appState, dynamic orderId) {
    final feeController = TextEditingController();
    String? selectedCourier;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('تحديد رسوم التوصيل للطلب #$orderId', style: const TextStyle(color: AppConstants.gold, fontSize: 16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: feeController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'رسوم التوصيل (ر.ي)',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF121212),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              value: selectedCourier,
              dropdownColor: const Color(0xFF1E1E1E),
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'اختر المندوب للتوصيل',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color(0xFF121212),
              ),
              items: appState.couriers.map<DropdownMenuItem<String>>((courier) {
                String courierName = courier['name']?.toString() ?? 'مندوب';
                return DropdownMenuItem<String>(
                  value: courierName,
                  child: Text(courierName, style: const TextStyle(color: Colors.white)),
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
            child: const Text('إغلاق', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.gold, 
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
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

              appState.setOrderDeliveryFee(orderId, fee, selectedCourier!);
              setState(() {
                _feeLockedState[orderId.toString()] = true;
              });
              
              Navigator.pop(context);

              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('تم إرسال رسوم التوصيل وإسناد المندوب للعميل بنجاح! 🚀')),
              );
            },
            child: const Text('إرسال للعميل', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

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
