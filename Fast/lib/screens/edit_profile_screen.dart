import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/app_state.dart';
import '../utils/constants.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  @override
  void initState() {
    super.initState();
    final appState = context.read<AppState>();
    final profile = appState.userProfile;

    _nameController = TextEditingController(text: profile?['name'] ?? '');
    _phoneController = TextEditingController(text: profile?['phone'] ?? '734910250');
    _addressController = TextEditingController(text: profile?['address'] ?? 'ديليكس');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تعديل الحساب', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // حقل الاسم الشخصي
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'الاسم الشخصي',
                prefixIcon: const Icon(Icons.person, color: AppConstants.gold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 15),

            // حقل رقم الهاتف (غير قابل للتعديل أو أساسي)
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'رقم الهاتف',
                prefixIcon: const Icon(Icons.phone, color: AppConstants.gold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 15),

            // حقل العنوان التفصيلي
            TextField(
              controller: _addressController,
              decoration: InputDecoration(
                labelText: 'العنوان (مثال: ديلوكس، العصيفرة...)',
                prefixIcon: const Icon(Icons.home, color: AppConstants.gold),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(height: 20),

            // قسم الخريطة المصغرة لتحديد الموقع
            const Text(
              'تحديد الموقع على الخريطة',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.gold),
            ),
            const SizedBox(height: 5),
            const Text(
              'في حال اختلاف موقعك الحالي عن موقع التوصيل، يرجى تحديد الموقع الخاص بك.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 10),

            // تصميم عنصر خريطة وهمية تفاعلية (أو مكان خريطة جوجل)
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: AppConstants.gold, width: 1.5),
                borderRadius: BorderRadius.circular(12),
                image: const DecorationImage(
                  image: AssetImage('assets/images/map_placeholder.png'), // أو صورة خريطة افتراضية
                  fit: BoxFit.cover,
                ),
                color: Colors.grey[900],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(Icons.location_pin, size: 50, color: Colors.red),
                  Positioned(
                    bottom: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'انقر لتحديد الموقع بدقة على الخريطة 📍',
                        style: TextStyle(fontSize: 11, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // زر الحفظ بتصميم جذاب مطابق للصورة
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.gold,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () async {
                  // حفظ البيانات في الـ AppState وقاعدة البيانات
                  await context.read<AppState>().saveUserProfileDetails(
                    _nameController.text.trim(),
                    _addressController.text.trim(),
                  );

                  // العودة للصفحة السابقة مع إشعار نجاح
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ وتحديث بيانات الحساب بنجاح! ✅')),
                  );
                },
                child: const Text(
                  'حفظ',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
