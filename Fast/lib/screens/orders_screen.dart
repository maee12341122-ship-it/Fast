import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../widgets/empty_state.dart';

class OrdersScreen extends StatelessWidget {
  final VoidCallback? onOpenDrawer;
  const OrdersScreen({super.key, this.onOpenDrawer});

  @override
  Widget build(BuildContext context) {
    // 👈 استخدام customerOrders لعزل طلبيات العميل الحالي برقم هاتفه فقط
    final orders = context.watch<AppState>().customerOrders;
    
    return Scaffold(
      appBar: AppBar(
        leading: onOpenDrawer == null ? null : IconButton(icon: const Icon(Icons.menu), onPressed: onOpenDrawer),
        title: const Text('طلباتي'),
      ),
      body: orders.isEmpty
          ? const EmptyState(message: 'لا توجد طلبات محفوظة خاصة بك حتى الآن', icon: Icons.receipt_long_outlined)
          : ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: orders.length,
              itemBuilder: (context, index) => _orderCard(context, orders[index]),
            ),
    );
  }

  Widget _orderCard(BuildContext context, dynamic order) {
    final appState = context.read<AppState>();
    
    // التعامل مع الطلب سواء كان Map أو كائن Model
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

    // إظهار الإشعار المنبثق للعميل تلقائياً إذا أرسل المشرف السعر
    if (status == 'pricingSentToCustomer') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showCustomerPricingDialog(context, appState, orderId, deliveryFee, totalPrice);
      });
    }

    return Card(
      color: Theme.of(context).colorScheme.surface,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: AppConstants.gold,
          child: Icon(Icons.receipt, color: Colors.black),
        ),
        title: Text('طلب #$orderId', style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.gold)),
        subtitle: Text('الحالة: $status\nالإجمالي: $totalPrice ر.ي\nالمندوب: $assignedCourier'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_left),
        onTap: () => showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('تفاصيل الطلب #$orderId'),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('مراحل الطلب:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppConstants.gold)),
                  const SizedBox(height: 8),
                  buildOrderStatusTimeline(status),
                  const Divider(height: 20),

                  Text('الحالة الحالية: $status'),
                  if (adminMessage.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text('ملاحظة الإدارة: $adminMessage', style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold)),
                  ],
                  const Divider(),
                  Text('العميل: $customerName'),
                  Text('الهاتف: $customerPhone'),
                  Text('العنوان: $address'),
                  const Divider(),
                  Text('تفاصيل الطلب: $itemsDesc', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('سعر المنتجات: $productsTotal ر.ي'),
                  Text('رسوم التوصيل: $deliveryFee ر.ي'),
                  Text('الإجمالي الكلي: $totalPrice ر.ي', style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('المندوب المعين: $assignedCourier'),
                ],
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('إغلاق'))],
          ),
        ),
      ),
    );
  }

  // --- نافذة الإشعار المنبثق لتسعيرة المشرف على شاشة العميل ---
  void _showCustomerPricingDialog(BuildContext context, AppState appState, String orderId, dynamic deliveryFee, dynamic totalPrice) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: const [
            Icon(Icons.notification_important, color: AppConstants.gold),
            SizedBox(width: 8),
            Text('تسعيرة جديدة من المشرف', style: TextStyle(color: Colors.white, fontSize: 16)),
          ],
        ),
        content: Text(
          'قام المشرف بتحديد رسوم التوصيل ($deliveryFee ر.ي).\nالإجمالي الكلي: $totalPrice ر.ي.\nهل توافق على المتابعة وتأكيد الطلب؟',
          style: const TextStyle(color: Colors.white70, fontSize: 14),
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
            child: const Text('رفض وإلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppConstants.gold, foregroundColor: Colors.black),
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
    );
  }

  // --- دالة رسم الخط الزمني لحالة الطلب ---
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
              radius: 10,
              backgroundColor: isDone ? AppConstants.gold : Colors.grey[700],
              child: isDone ? const Icon(Icons.check, size: 12, color: Colors.black) : null,
            ),
            const SizedBox(height: 4),
            Text(steps[index], style: TextStyle(fontSize: 9, color: isDone ? AppConstants.gold : Colors.grey)),
          ],
        );
      }),
    );
  }
}
