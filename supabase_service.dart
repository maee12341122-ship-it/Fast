lib/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  final _supabase = Supabase.instance.client;

  // ==================== المنتجات (Products) ====================

  // جلب جميع المنتجات
  Future<List>> getProducts() async {
    final response = await _supabase.from('products').select();
    return List>.from(response);
  }

  // إضافة منتج جديد
  Future<void> addProduct({
    required String id,
    required String name,
    required String restaurantName,
    required double price,
    required String category,
    bool available = true,
    String? imageUrl,
  }) async {
    await _supabase.from('products').insert({
      'id': id,
      'name': name,
      'restaurant_name': restaurantName,
      'price': price,
      'category': category,
      'available': available,
      'image_url': imageUrl,
    });
  }

  // ==================== المناديب (Couriers) ====================

  // جلب المناديب
  Future<List>> getCouriers() async {
    final response = await _supabase.from('couriers').select();
    return List>.from(response);
  }

  // إضافة مندوب جديد
  Future<void> addCourier({
    required String id,
    required String name,
    required String phone,
    String? username,
    String? password,
    String status = 'active',
  }) async {
    await _supabase.from('couriers').insert({
      'id': id,
      'name': name,
      'phone': phone,
      'username': username,
      'password': password,
      'status': status,
      'is_logged_in': false,
      'completed_orders': 0,
    });
  }

  // ==================== العملاء (Customers) ====================

  // حفظ بيانات العميل عند التسجيل
  Future<void> saveCustomer({
    required String name,
    required String phone,
    required String address,
    String city = 'تعز',
  }) async {
    await _supabase.from('customers').insert({
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
