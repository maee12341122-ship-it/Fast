import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_state.dart';
import '../utils/constants.dart';
import '../utils/validators.dart';
import 'delivery_dashboard.dart';

class DeliveryLoginScreen extends StatefulWidget {
  const DeliveryLoginScreen({super.key});

  @override
  State<DeliveryLoginScreen> createState() => _DeliveryLoginScreenState();
}

class _DeliveryLoginScreenState extends State<DeliveryLoginScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    final courier = context.read<AppState>().courierByPhone(_phoneController.text);
    if (courier == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لا يوجد مندوب مفعّل بهذا الرقم على هذا الجهاز.')));
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => DeliveryDashboard(deliveryId: courier.id)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 2,
          title: const Text('دخول المندوب', style: TextStyle(color: AppConstants.gold, fontWeight: FontWeight.bold, fontSize: 16)),
        ),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppConstants.gold.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppConstants.gold.withOpacity(0.3)),
                  ),
                  child: const Icon(Icons.delivery_dining, size: 60, color: AppConstants.gold),
                ),
                const SizedBox(height: 24),
                const Text('أدخل رقم الهاتف المسجل للمندوب', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Text('سيتم التحقق من رقم الهاتف للوصول للوحة المندوب', style: TextStyle(color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'رقم الهاتف اليمني',
                    labelStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(),
                    filled: true,
                    fillColor: Color(0xFF1E1E1E),
                    prefixIcon: Icon(Icons.phone, color: AppConstants.gold),
                  ),
                  validator: Validators.yemeniPhone,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppConstants.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: _login,
                    icon: const Icon(Icons.login, color: Colors.black),
                    label: const Text('دخول حساب المندوب 🚀', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.withOpacity(0.3)),
                  ),
                  child: const Text(
                    'تنبيه: هذا تحقق محلي بالرقم فقط لأغراض الاختبار، وليس مصادقة آمنة. يجب ربط حسابات المندوبين بخادم قبل الإطلاق.',
                    style: TextStyle(color: Colors.orangeAccent, fontSize: 11, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
