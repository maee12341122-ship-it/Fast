import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';

class OrdersScreen extends StatefulWidget {
  final VoidCallback? onOpenDrawer;
  const OrdersScreen({super.key, this.onOpenDrawer});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  // جعلنا مجموعة التتبع داخل الـ State لكي تتحدث وتتفرغ بسلامة عند تغيير الحسابات
  final Set<String> _processedPricingOrders = {};

  @override
  Widget build(BuildContext context) {
    final orders = context.watch<AppState>().customerOrders;
    
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 2,
          leading: widget.onOpenDrawer == null ? null : IconButton(icon: const Icon(Icons.menu, color: AppConstants.gold), onPressed: widget.onOpenDrawer),
          title: const Text('طلباتي', style: TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: orders.isEmpty
            ? const EmptyState(
                message: 'لا توجد طلبات محفوظة خاصة بك حتى الآن 📦', 
                icon: Icons.receipt_long_outlined,
              )
            : ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: orders.length,
                itemBuilder: (context, index) => _orderCard(context, orders[index]),
              ),
      ),
    );
  }

  Widget _orderCard(BuildContext context, dynamic order) {
    final appState = context.read<AppState>();
    
    final orderId = order is Map ? (order['id']?.toString() ?? '') : order.id;
    final status = order is Map ? (order['status']?.toString() ?? 'waitingForPricing') : order.status;
    final totalPrice = order is Map ? (order['total_price']?.toString() ?? '0') : order.total.toString();
    final customerName = order is Map ? (order['customer_name']?.toString() ?? '') : order.customerName;
    final customerPhone = order is Map ? (order['phone']?.toString() ?? '') : order.customerPhone;
    final address = order is Map ? (order['address']?.toString() ?? '') : order.address;
    final itemsDesc = order is Map ? (order['items_description']?.toString() ?? 'لا توجد تفاصيل') : (order.itemsDescription ?? '');
    final productsTotal = order is Map ? (order['products_total']?.toString() ?? '0') : order.subtotal.toString();
    final deliveryFee = order is Map ? (order['delivery_fee']?.toString() ?? '0') : order.deliveryFee.toString();
    final assignedCourier = order is Map ? (order['assigned_courier']?.toString() ?? 'لم يتم التعيين') : order.assignedCourier;
    final adminMessage = order is Map ? (order['admin_message']?.toString() ?? '') : '';

    final paymentMethod = order is Map ? (order['payment_method']?.toString() ?? 'cash') : 'cash';
    final paymentAccount = order is Map ? (order['payment_account']?.toString() ?? '') : '';
    final paymentDisplay = paymentMethod == 'cash'
        ? '💵 نقداً عند الاستلام'
        : '💳 محفظة ($paymentMethod) - حساب: $paymentAccount';

    // فحص ذكي ومستقل لكل طلب ليظهر الشاشة المنبثقة بدقة متناهية
    if (status == 'pricingSentToCustomer' && !_processedPricingOrders.contains(orderId)) {
      _processedPricingOrders.add(orderId);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCustomerPricingDialog(context, appState, orderId, deliveryFee, totalPrice);
      });
    }

    return Card(
      color: const Color(0xFF1E1E1E),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppConstants.gold.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('طلب #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold, fontSize: 16)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_getStatusText(status), style: const TextStyle(color: AppConstants.gold, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(color: Colors.white12, height: 20),
            Text('💰 الإجمالي: $totalPrice ر.ي', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
            const SizedBox(height: 4),
            Text('🛵 المندوب: $assignedCourier', style: const TextStyle(color: Colors.white70, fontSize: 13)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppConstants.gold,
                  side: BorderSide(color: AppConstants.gold.withOpacity(0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => showDialog<void>(
                  context: context,
                  builder: (dialogContext) => Directionality(
                    textDirection: TextDirection.rtl,
                    child: AlertDialog(
                      backgroundColor: const Color(0xFF1E1E1E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      title: Text('تفاصيل الطلب #$orderId', style: const TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold, fontSize: 16)),
                      content: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('مراحل الطلب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppConstants.gold)),
                            const SizedBox(height: 10),
                            buildOrderStatusTimeline(status),
                            const Divider(color: Colors.white12, height: 24),

                            Text('الحالة الحالية: ${_getStatusText(status)}', style: const TextStyle(color: Colors.white, fontSize: 13)),
                            if (adminMessage.isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                child: Text('ملاحظة الإدارة: $adminMessage', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            ],
                            const Divider(color: Colors.white12),
                            Text('👤 العميل: $customerName', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('📞 الهاتف: $customerPhone', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('📍 العنوان: $address', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            const Divider(color: Colors.white12),
                            
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: paymentMethod == 'cash' ? Colors.green.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: paymentMethod == 'cash' ? Colors.green : Colors.blueAccent),
                              ),
                              child: Text(
                                'طريقة الدفع: $paymentDisplay',
                                style: TextStyle(
                                  color: paymentMethod == 'cash' ? Colors.greenAccent : Colors.lightBlueAccent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const Divider(color: Colors.white12),

                            Text('🛒 تفاصيل المنتجات:\n$itemsDesc', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                            const Divider(color: Colors.white12),
                            Text('سعر المنتجات: $productsTotal ر.ي', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('رسوم التوصيل: $deliveryFee ر.ي', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                            Text('الإجمالي الكلي: $totalPrice ر.ي', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold, fontSize: 14)),
                            const SizedBox(height: 6),
                            Text('المندوب المعين: $assignedCourier', style: const TextStyle(color: Colors.amberAccent, fontSize: 13)),
                          ],
                        ),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext), 
                          child: const Text('إغلاق', style: TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ),
                icon: const Icon(Icons.info_outline, size: 16),
                label: const Text('عرض التفاصيل الكاملة', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCustomerPricingDialog(BuildContext context, AppState appState, String orderId, dynamic deliveryFee, dynamic totalPrice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.notification_important, color: AppConstants.gold),
              SizedBox(width: 8),
              Text('تسعيرة جديدة من المشرف', style: TextStyle(color: AppConstants.gold, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Text(
            'قام المشرف بتحديد رسوم التوصيل ($deliveryFee ر.ي).\nالإجمالي الكلي: $totalPrice ر.ي.\nهل توافق على المتابعة وتأكيد الطلب؟',
            style: const TextStyle(color: Colors.white70, fontSize: 14, height: 1.5),
          ),
          actions: [
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              onPressed: () {
                appState.customerCancelOrder(orderId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تم رفض التسعيرة وإلغاء الطلب 🔴')),
                );
              },
              child: const Text('رفض وإلغاء', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.gold, 
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                appState.customerApprovePricing(orderId);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('تمت الموافقة بنجاح، جاري إسناد الطلب للمندوب! 🚀')),
                );
              },
              child: const Text('موافقة وقبول', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildOrderStatusTimeline(String status) {
    int getStepIndex() {
      switch (status) {
        case 'waitingForPricing': return 0;
        case 'pricingSentToCustomer': return 1;
        case 'waitingCourierApproval': return 2;
        case 'onTheWay': return 3;
        case 'arrived': return 4;
        case 'delivered': return 5;
        default: return 0;
      }
    }

    final steps = ['التسعير', 'الرسوم', 'التأكيد', 'الطريق', 'الوصول', 'التسليم'];
    int currentStep = getStepIndex();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(steps.length, (index) {
        bool isDone = index <= currentStep;
        return Column(
          children: [
            CircleAvatar(
              radius: 11,
              backgroundColor: isDone ? AppConstants.gold : Colors.grey[800],
              child: isDone ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
            ),
            const SizedBox(height: 6),
            Text(steps[index], style: TextStyle(fontSize: 10, color: isDone ? AppConstants.gold : Colors.grey, fontWeight: FontWeight.bold)),
          ],
        );
      }),
    );
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'waitingForPricing': return 'بانتظار التسعير';
      case 'pricingSentToCustomer': return 'تم إرسال السعر';
      case 'waitingCourierApproval': return 'بانتظار المندوب';
      case 'onTheWay': return 'المندوب في الطريق';
      case 'arrived': return 'وصل المندوب';
      case 'delivered': return 'تم التسليم';
      case 'cancelledByCustomer': return 'ملغي من العميل';
      default: return status;
    }
  }
}
