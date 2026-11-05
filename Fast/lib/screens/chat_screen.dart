import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({Key? key}) : super(key: key);

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  
  // 👈 متغيرات طريقة الدفع الجديدة
  String _selectedPaymentMethod = 'cash'; // 'cash' أو 'الكريمي' أو 'القطيبي'
  final TextEditingController _accountNumberController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final appState = Provider.of<AppState>(context, listen: false);
    if (appState.userProfile != null) {
      _nameController.text = appState.userProfile!['name'] ?? '';
      _phoneController.text = appState.userProfile!['phone'] ?? '';
      _addressController.text = appState.userProfile!['address'] ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _accountNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<AppState>();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('سلة المشتريات وإتمام الطلب 🛒', style: TextStyle(color: Colors.amber)),
          backgroundColor: const Color(0xFF1E1E1E),
        ),
        body: appState.cartItems.isEmpty
            ? const Center(
                child: Text('السلة فارغة حالياً 📦', style: TextStyle(color: Colors.grey, fontSize: 16)),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...appState.cartItems.map((item) => Card(
                        color: const Color(0xFF1E1E1E),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(item.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('السعر: ${item.price} ر.ي | الكمية: ${item.quantity}', style: const TextStyle(color: Colors.white70)),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.redAccent),
                            onPressed: () => appState.removeFromCart(item.id),
                          ),
                        ),
                      )),
                  const Divider(color: Colors.amber, height: 30),
                  Text('إجمالي المنتجات: ${appState.totalAmount} ر.ي', style: const TextStyle(color: Colors.amber, fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  const Text('بيانات العميل للتوصيل:', style: TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _nameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'اسم العميل الكامل', filled: true, fillColor: Color(0xFF1E1E1E), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'رقم الهاتف', filled: true, fillColor: Color(0xFF1E1E1E), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _addressController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(labelText: 'العنوان بالتفصيل في تعز', filled: true, fillColor: Color(0xFF1E1E1E), border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 20),
                  
                  // 👈 قسم اختيار طريقة الدفع الجديدة (نقدي أو محافظ إلكترونية)
                  const Text('طريقة الدفع:', style: TextStyle(color: Colors.amber, fontSize: 15, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    dropdownColor: const Color(0xFF1E1E1E),
                    style: const TextStyle(color: Colors.white),
                    value: _selectedPaymentMethod,
                    decoration: const InputDecoration(filled: true, fillColor: Color(0xFF1E1E1E), border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('💵 نقداً عند الاستلام (Cash on Delivery)')),
                      DropdownMenuItem(value: 'الكريمي', child: Text('💳 بنك الكريمي (Al-Kuraimi Mobile)')),
                      DropdownMenuItem(value: 'القطيبي', child: Text('💳 القطيبي لحظي (Al-Qutaibi)')),
                      DropdownMenuItem(value: 'جوال موني', child: Text('💳 جوال موني (Mobile Money)')),
                    ],
                    onChanged: (val) => setState(() => _selectedPaymentMethod = val!),
                  ),
                  
                  // إذا اختار العميل محفظة إلكترونية، يظهر حقل إدخال رقم الحساب
                  if (_selectedPaymentMethod != 'cash') ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _accountNumberController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'رقم الحساب أو الهاتف المحول منه (${_selectedPaymentMethod})',
                        labelStyle: const TextStyle(color: Colors.amberAccent),
                        filled: true,
                        fillColor: const Color(0xFF1E1E1E),
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ],

                  const SizedBox(height: 25),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.amber, minimumSize: const Size(double.infinity, 50)),
                    onPressed: () {
                      if (_nameController.text.isNotEmpty && _phoneController.text.isNotEmpty && _addressController.text.isNotEmpty) {
                        if (_selectedPaymentMethod != 'cash' && _accountNumberController.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إدخال رقم الحساب المحول منه لمطابقة الدفع')));
                          return;
                        }

                        String itemsDesc = appState.cartItems.map((e) => '${e.name} (x${e.quantity})').join(', ');
                        
                        appState.createOrder(
                          customerName: _nameController.text,
                          phone: _phoneController.text,
                          address: _addressController.text,
                          itemsDesc: itemsDesc,
                          productsTotal: appState.totalAmount,
                          paymentMethod: _selectedPaymentMethod,
                          paymentAccount: _selectedPaymentMethod == 'cash' ? 'نقدي' : _accountNumberController.text,
                        );

                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم إرسال طلبك بنجاح وبانتظار تسعير المشرف! 🚀')));
                        Navigator.pop(context);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الرجاء إكمال كافة بيانات العميل')));
                      }
                    },
                    child: const Text('إتمام وإرسال الطلب 🚀', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
      ),
    );
  }
}
