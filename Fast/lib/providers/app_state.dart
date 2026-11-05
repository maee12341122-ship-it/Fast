import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../models/address_model.dart'; // 👈 أضفنا استيراد نموذج العناوين لمعالجة AddOrUpdateAddress
import '../services/notification_service.dart';

class AppState extends ChangeNotifier {
  final supabase = Supabase.instance.client;

  AppState() {
    _loadAdminSession();
    _loadCourierSession();
    _loadUserSession();
    fetchStoreSettings();
    fetchProductsFromSupabase();
    fetchCouriersFromSupabase();
    listenToOrdersRealtime();
    listenToStoreSettingsRealtime();
  }

  // --- إعدادات أوقات الدوام والدعم ---
  int startHour = 8;
  int endHour = 24;
  String customerSupportPhone = '770000000';

  bool isDarkMode = true;
  void toggleTheme() {
    isDarkMode = !isDarkMode;
    notifyListeners();
  }

  // 👈 إضافة دعم المظهر (ThemeMode) وتغييره كما تطلبه شاشة التطبيق
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;
  
  void setThemeMode(ThemeMode mode) {
    isDarkMode = (mode == ThemeMode.dark);
    notifyListeners();
  }

  String currentCity = 'تعز';
  void setCity(String city) {
    currentCity = city;
    if (userProfile != null) {
      userProfile!['city'] = city;
    }
    notifyListeners();
  }

  // --- إدارة رسائل الشات اللحظية المعزولة ---
  Stream getMessagesForOrder(dynamic orderId, String targetChat) {
    return supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('order_id', orderId)
        .order('created_at', ascending: true);
  }

  Future<void> sendChatMessage(dynamic orderId, String senderRole, String targetChat, String messageText) async {
    if (messageText.trim().isEmpty) return;

    final newMessage = {
      'order_id': orderId,
      'sender_type': senderRole,
      'target_chat': targetChat,
      'message_text': messageText,
    };

    try {
      await supabase.from('messages').insert(newMessage);
      debugPrint('✅ تم إرسال الرسالة بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال رسالة الشات: $e');
    }
  }

  // --- إرسال رمز التحقق عبر الواتساب ---
  Future<void> sendOtpViaWhatsAppDirect(String phone) async {
    if (generatedDynamicOtp == null) return;

    String formattedPhone = phone.trim();
    if (formattedPhone.startsWith('0')) {
      formattedPhone = '967${formattedPhone.substring(1)}';
    } else if (!formattedPhone.startsWith('967')) {
      formattedPhone = '967$formattedPhone';
    }

    final message = Uri.encodeComponent(
        'مرحباً، رمز التحقق الخاص بك لتطبيق FAST هو: $generatedDynamicOtp'
    );

    final whatsappUrl = Uri.parse("https://wa.me/$formattedPhone?text=$message");

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('❌ خطأ في فتح تطبيق الواتساب: $e');
    }
  }

  // --- مشاركة التطبيق ---
  void shareApp() {
    Share.share(
      'حمل تطبيق FAST - أسرع خدمة توصيل في تعز! 🚀\nhttps://play.google.com/store/apps/details?id=com.fast.taiz',
      subject: 'تطبيق FAST تعز',
    );
  }

  // 👈 تسلسل طلب الأذونات: الموقع أولاً ثم الإشعارات ثانياً
  Future<void> requestLocationAndNotificationPermissions() async {
    try {
      LocationPermission locationPermission = await Geolocator.checkPermission();
      if (locationPermission == LocationPermission.denied) {
        locationPermission = await Geolocator.requestPermission();
      }

      if (locationPermission == LocationPermission.deniedForever) {
        debugPrint('⚠️ إذن الموقع مرفوض نهائياً من إعدادات الهاتف');
      } else {
        debugPrint('📍 تم التعامل مع إذن الموقع بنجاح');
      }

      bool notificationGranted = await NotificationService.requestNotificationPermission();
      if (notificationGranted) {
        debugPrint('🔔 تم منح إذن الإشعارات بنجاح');
        addNotification('تطبيق FAST - تعز', 'تم تفعيل الإشعارات وتحديد الموقع بنجاح 🚀');
      } else {
        debugPrint('⚠️ تم رفض إذن الإشعارات');
      }

    } catch (e) {
      debugPrint('❌ خطأ في طلب الأذونات المتسلسلة: $e');
    }
  }

  // --- إعدادات المتجر ---
  Future<void> fetchStoreSettings() async {
    try {
      final response = await supabase.from('settings').select().maybeSingle();
      if (response != null) {
        startHour = int.tryParse(response['start_hour'].toString()) ?? 8;
        endHour = int.tryParse(response['end_hour'].toString()) ?? 24;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('⚠️ خطأ في جلب إعدادات الدوام: $e');
    }
  }

  void listenToStoreSettingsRealtime() {
    try {
      supabase.from('settings').stream(primaryKey: ['id']).listen((data) {
        if (data.isNotEmpty) {
          startHour = int.tryParse(data.first['start_hour'].toString()) ?? 8;
          endHour = int.tryParse(data.first['end_hour'].toString()) ?? 24;
          notifyListeners();
        }
      });
    } catch (e) {
      debugPrint('⚠️ خطأ في الاستماع للإعدادات: $e');
    }
  }

  Future<void> updateStoreSettings(int start, int end) async {
    startHour = start;
    endHour = end;
    notifyListeners();

    try {
      await supabase.from('settings').upsert({
        'id': 1,
        'start_hour': start,
        'end_hour': end,
      });
    } catch (e) {
      debugPrint('❌ خطأ في حفظ أوقات الدوام: $e');
    }
  }

  bool get isStoreOpen {
    final now = DateTime.now();
    final currentHour = now.hour;
    if (endHour > startHour) {
      return currentHour >= startHour && currentHour < endHour;
    } else {
      return currentHour >= startHour || currentHour < endHour;
    }
  }

  // --- جلسة المشرف ---
  bool isAdminLoggedIn = false;

  void _loadAdminSession() async {
    final prefs = await SharedPreferences.getInstance();
    isAdminLoggedIn = prefs.getBool('isAdminLoggedIn') ?? false;
    notifyListeners();
  }

  Future<bool> loginAdminFromSupabase(String username, String password) async {
    try {
      if (username.trim().toLowerCase() == 'admin' && password.trim() == '123456') {
        isAdminLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        notifyListeners();
        return true;
      }

      final response = await supabase.from('admins').select();
      if (response != null && response is List) {
        for (var admin in response) {
          String dbUsername = admin['username']?.toString().trim() ?? '';
          String dbPassword = admin['password_hash']?.toString().trim() ??
              admin['password']?.toString().trim() ?? '';

          if (dbUsername.toLowerCase() == username.trim().toLowerCase() && dbPassword == password.trim()) {
            isAdminLoggedIn = true;
            final prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isAdminLoggedIn', true);
            notifyListeners();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      if (username.trim().toLowerCase() == 'admin' && password.trim() == '123456') {
        isAdminLoggedIn = true;
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isAdminLoggedIn', true);
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  void logoutAdmin() {
    isAdminLoggedIn = false;
    SharedPreferences.getInstance().then((prefs) {
      prefs.setBool('isAdminLoggedIn', false);
    });
    notifyListeners();
  }

  // --- مصادقة العميل والتحقق الذكي ---
  Map<String, String>? userProfile;
  String? generatedDynamicOtp;

  dynamic get user => userProfile == null ? null : _UserMock(userProfile!['name'] ?? '', userProfile!['phone'] ?? '');

  void _loadUserSession() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('userPhone');
    final name = prefs.getString('userName');
    final address = prefs.getString('userAddress');
    final city = prefs.getString('userCity') ?? currentCity;

    if (phone != null && phone.isNotEmpty) {
      userProfile = {
        'phone': phone,
        'name': name ?? '',
        'city': city,
        'address': address ?? '',
      };
      notifyListeners();
    }
  }

  Future<bool> checkAndLoginCustomer(String phone) async {
    try {
      String cleanPhone = _normalizePhone(phone);
      final response = await supabase
          .from('customers')
          .select()
          .eq('phone', cleanPhone)
          .maybeSingle();

      if (response != null) {
        String name = response['name']?.toString() ?? '';
        String address = response['address']?.toString() ?? '';

        userProfile = {
          'phone': cleanPhone,
          'name': name,
          'city': currentCity,
          'address': address,
        };

        final prefs = await SharedPreferences.getInstance();
        prefs.setString('userPhone', cleanPhone);
        prefs.setString('userName', name);
        prefs.setString('userAddress', address);
        prefs.setString('userCity', currentCity);

        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('❌ خطأ في فحص العميل: $e');
      return false;
    }
  }

  void requestOtpForPhone(String phone) {
    final randomOtp = (100000 + Random().nextInt(900000)).toString();
    generatedDynamicOtp = randomOtp;
    notifyListeners();
  }

  bool verifyOtpAndLogin(String phone, String enteredOtp) {
    if (generatedDynamicOtp != null && enteredOtp == generatedDynamicOtp) {
      String cleanPhone = _normalizePhone(phone);
      
      checkAndLoginCustomer(cleanPhone).then((exists) {
        if (!exists) {
          userProfile = {'phone': cleanPhone, 'name': '', 'city': currentCity, 'address': ''};
        }
      });

      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('userPhone', cleanPhone);
        prefs.setString('userCity', currentCity);
      });

      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> saveUserProfileDetails(String name, String address) async {
    if (userProfile != null) {
      userProfile!['name'] = name;
      userProfile!['address'] = address;
      String phone = userProfile!['phone'] ?? '';

      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userName', name);
      prefs.setString('userAddress', address);

      try {
        await supabase.from('customers').upsert({
          'phone': phone,
          'name': name,
          'address': address,
        }, onConflict: 'phone');

        await requestLocationAndNotificationPermissions();
      } catch (e) {
        debugPrint('❌ خطأ في حفظ العميل: $e');
      }

      notifyListeners();
    }
  }

  // 👈 إضافة الدوال المفقودة لتعديل بيانات العميل والعناوين لتتوافق مع الشاشات
  Future<void> updateUser({required String name, required String phone}) async {
    if (userProfile != null) {
      userProfile!['name'] = name;
      userProfile!['phone'] = _normalizePhone(phone);
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userName', name);
      prefs.setString('userPhone', userProfile!['phone']!);
      notifyListeners();
    }
  }

  Future<void> addOrUpdateAddress(dynamic addressModel) async {
    String addressDetails = addressModel is String ? addressModel : (addressModel.details ?? '');
    if (userProfile != null) {
      userProfile!['address'] = addressDetails;
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('userAddress', addressDetails);
      notifyListeners();
    }
  }

  Future<void> setDefaultAddress(String addressId) async {
    notifyListeners();
  }

  void clearUser() {
    logoutUser();
  }

  void setUser({required String name, required String phone, required dynamic address}) {
    String cleanPhone = _normalizePhone(phone);
    String addressDetails = address is String ? address : (address.details ?? '');

    userProfile = {
      'phone': cleanPhone,
      'name': name,
      'city': currentCity,
      'address': addressDetails,
    };

    SharedPreferences.getInstance().then((prefs) {
      prefs.setString('userPhone', cleanPhone);
      prefs.setString('userName', name);
      prefs.setString('userAddress', addressDetails);
      prefs.setString('userCity', currentCity);
    });

    saveUserProfileDetails(name, addressDetails);
    notifyListeners();
  }

  void logoutUser() async {
    userProfile = null;
    final prefs = await SharedPreferences.getInstance();
    prefs.remove('userPhone');
    prefs.remove('userName');
    prefs.remove('userAddress');
    notifyListeners();
  }

  // --- إدارة المناديب وحالتهم ---
  Map<String, dynamic>? currentCourier;
  List couriers = [];

  void _loadCourierSession() async {
    final prefs = await SharedPreferences.getInstance();
    final courierId = prefs.getString('loggedCourierId');
    if (courierId != null && couriers.isNotEmpty) {
      final index = couriers.indexWhere((c) => c['id'].toString() == courierId || c['delivery_man_id'].toString() == courierId);
      if (index != -1) {
        currentCourier = couriers[index];
        notifyListeners();
      }
    }
  }

  Future<void> fetchCouriersFromSupabase() async {
    try {
      final response = await supabase.from('couriers').select();
      couriers = response;
      _loadCourierSession();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في جلب المناديب: $e');
    }
  }

  Future<void> addCourier(String name, String phone, String username, String password) async {
    try {
      final courierId = 'D-00${couriers.length + 1}';
      await supabase.from('couriers').insert({
        'id': courierId,
        'delivery_man_id': courierId,
        'username': username,
        'password': password,
        'name': name,
        'phone': phone,
        'status': 'available',
        'is_logged_in': false,
        'completed_orders': 0,
      });
      await fetchCouriersFromSupabase();
    } catch (e) {
      debugPrint('❌ خطأ في حفظ المندوب: $e');
    }
  }

  bool loginCourier(String username, String password) {
    final index = couriers.indexWhere((c) => c['username'].toString().trim() == username.trim() && c['password'].toString().trim() == password.trim());
    if (index != -1) {
      couriers[index]['is_logged_in'] = true;
      currentCourier = couriers[index];

      final cId = currentCourier!['id']?.toString() ?? currentCourier!['delivery_man_id'].toString();
      SharedPreferences.getInstance().then((prefs) {
        prefs.setString('loggedCourierId', cId);
      });

      try {
        supabase.from('couriers').update({'is_logged_in': true}).eq('id', cId);
      } catch (e) {
        debugPrint('⚠️ خطأ تحديث المندوب: $e');
      }

      notifyListeners();
      return true;
    }
    return false;
  }

  void logoutCourier() {
    if (currentCourier != null) {
      final courierId = currentCourier!['id'] ?? currentCourier!['delivery_man_id'];
      final index = couriers.indexWhere((c) => c['delivery_man_id'] == courierId || c['id'] == courierId);
      if (index != -1) {
        couriers[index]['is_logged_in'] = false;
      }

      try {
        supabase.from('couriers').update({'is_logged_in': false}).eq('id', courierId);
      } catch (e) {
        debugPrint('⚠️ خطأ خروج المندوب: $e');
      }

      currentCourier = null;
      SharedPreferences.getInstance().then((prefs) {
        prefs.remove('loggedCourierId');
      });
      notifyListeners();
    }
  }

  // --- سلة المشتريات ---
  final List<CartItemModel> _cartItems = [];
  List<CartItemModel> get cartItems => _cartItems;

  int get totalCartItemsCount => _cartItems.fold(0, (sum, item) => sum + item.quantity);
  double get totalAmount => _cartItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity));

  int getProductQuantityInCart(String productId) {
    final index = _cartItems.indexWhere((item) => item.id == productId);
    if (index >= 0) return _cartItems[index].quantity;
    return 0;
  }

  void addToCart(CartItemModel item) {
    final index = _cartItems.indexWhere((element) => element.id == item.id);
    if (index >= 0) {
      _cartItems[index].quantity += item.quantity;
    } else {
      _cartItems.add(item);
    }
    notifyListeners();
  }

  void removeFromCart(String id) {
    _cartItems.removeWhere((item) => item.id == id);
    notifyListeners();
  }

  void updateQuantity(String id, int delta) {
    final index = _cartItems.indexWhere((item) => item.id == id);
    if (index >= 0) {
      _cartItems[index].quantity += delta;
      if (_cartItems[index].quantity <= 0) {
        _cartItems.removeAt(index);
      }
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    notifyListeners();
  }

  void addCustomItem({required String name, required int price, required int quantity, required String notes}) {
    _cartItems.add(CartItemModel(
      id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
      name: '$name (ملاحظات: $notes)',
      price: price.toDouble(),
      quantity: quantity,
      restaurantId: 'طلبات خاصة',
      imageUrl: '',
    ));
    notifyListeners();
  }

  void addCustomOrderToCart({required String customName, required double estimatedPrice}) {
    addCustomItem(name: customName, price: estimatedPrice.toInt(), quantity: 1, notes: '');
  }

  // --- المنتجات ---
  List products = [];

  Future<void> fetchProductsFromSupabase() async {
    try {
      final response = await supabase.from('products').select();
      products = response.map((p) => ProductModel(
        id: p['id'].toString(),
        name: p['name'] ?? '',
        restaurantName: p['restaurant_name'] ?? 'متجر عام',
        price: double.tryParse(p['price'].toString()) ?? 0.0,
        category: p['category'] ?? 'المطاعم',
        available: p['available'] ?? true,
        imageUrl: p['image_url'] ?? '',
      )).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في جلب المنتجات: $e');
    }
  }

  Future<void> addProduct(ProductModel product) async {
    try {
      await supabase.from('products').insert({
        'id': product.id,
        'name': product.name,
        'restaurant_name': product.restaurantName,
        'price': product.price,
        'category': product.category,
        'available': product.available,
        'image_url': product.imageUrl,
      });
      await fetchProductsFromSupabase();
    } catch (e) {
      debugPrint('❌ خطأ في حفظ المنتج: $e');
    }
  }

  // --- الطلبات ومعالجة طرق الدفع الجديدة ---
  List orders = [];
  List notifications = [];

  String _normalizePhone(String phone) {
    String clean = phone.trim().replaceAll(' ', '');
    if (clean.startsWith('0')) {
      clean = clean.substring(1);
    }
    if (clean.startsWith('967')) {
      clean = clean.substring(3);
    }
    return clean;
  }

  List get customerOrders {
    if (userProfile == null || userProfile!['phone'] == null || userProfile!['phone']!.isEmpty) {
      return [];
    }
    String myPhone = _normalizePhone(userProfile!['phone']!);

    return orders.where((o) {
      String orderPhone = _normalizePhone(o['phone']?.toString() ?? '');
      return orderPhone.isNotEmpty && orderPhone == myPhone;
    }).toList();
  }

  void addNotification(String title, String body) {
    notifications.insert(0, {'title': title, 'body': body, 'time': DateTime.now()});
    NotificationService.showLocalNotification(title, body);
    notifyListeners();
  }

  void listenToOrdersRealtime() async {
    try {
      final initialData = await supabase.from('orders').select();
      orders = List.from(initialData);
      notifyListeners();

      supabase.from('orders').stream(primaryKey: ['id']).listen((data) {
        orders = List.from(data);
        notifyListeners();
      }, onError: (error) {
        debugPrint('⚠️ خطأ في الاستماع للطلبات: $error');
      });
    } catch (e) {
      debugPrint('❌ خطأ في جلب الطلبات: $e');
    }
  }

  Future<void> createOrder({
    required String customerName,
    required String phone,
    required String address,
    required String itemsDesc,
    required double productsTotal,
    required String paymentMethod,
    required String paymentAccount,
  }) async {
    userProfile = {'phone': phone, 'name': customerName, 'city': currentCity, 'address': address};

    final orderData = {
      'customer_name': customerName,
      'phone': phone,
      'address': address,
      'items_description': itemsDesc,
      'products_total': productsTotal,
      'delivery_fee': 0.0,
      'total_price': productsTotal,
      'assigned_courier': 'لم يتم التعيين',
      'status': 'waitingForPricing',
      'is_fee_sent': false,
      'admin_message': 'بانتظار تحديد رسوم التوصيل من المشرف',
      'payment_method': paymentMethod,
      'payment_account': paymentAccount,
      'date': DateTime.now().toString().split(' ')[0],
    };

    try {
      await supabase.from('orders').insert(orderData);
      _cartItems.clear();
      addNotification('تم إرسال الطلب ⏳', 'طلبك بانتظار تحديد رسوم التوصيل من المشرف');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ في إنشاء الطلب: $e');
    }
  }

  Future<void> setOrderDeliveryFee(dynamic orderId, double fee, String courierName) async {
    try {
      final orderIndex = orders.indexWhere((o) => o['id'].toString() == orderId.toString());
      if (orderIndex != -1) {
        final currentStatus = orders[orderIndex]['status']?.toString();
        if (currentStatus != null && currentStatus != 'waitingForPricing' && currentStatus != 'pricingSentToCustomer') {
          debugPrint('⚠️ الطلب مؤكد أو منتهي، لا يمكن تعديل تسعيره!');
          return;
        }
      }

      double productsTotal = orderIndex != -1 ? double.tryParse(orders[orderIndex]['products_total'].toString()) ?? 0.0 : 0.0;
      double totalPrice = productsTotal + fee;

      await supabase.from('orders').update({
        'delivery_fee': fee,
        'total_price': totalPrice,
        'assigned_courier': courierName.trim(),
        'status': 'pricingSentToCustomer',
        'is_fee_sent': true,
        'admin_message': 'تم تحديد رسوم التوصيل ($fee ر.ي). بانتظار موافقة العميل ⏳',
      }).eq('id', orderId);

      if (orderIndex != -1) {
        orders[orderIndex]['delivery_fee'] = fee;
        orders[orderIndex]['total_price'] = totalPrice;
        orders[orderIndex]['assigned_courier'] = courierName.trim();
        orders[orderIndex]['status'] = 'pricingSentToCustomer';
        orders[orderIndex]['admin_message'] = 'تم تحديد رسوم التوصيل ($fee ر.ي). بانتظار موافقة العميل ⏳';
      }

      addNotification('تم تسعير الطلب #$orderId 💰', 'تم تحديد رسوم التوصيل ($fee ر.ي). يرجى من العميل تأكيد الطلب!');
      notifyListeners();
    } catch (e) {
      debugPrint('❌ خطأ تحديث الرسوم: $e');
    }
  }

  Future<void> customerApprovePricing(dynamic orderId) async {
    final orderIndex = orders.indexWhere((o) => o['id'].toString() == orderId.toString());

    await supabase.from('orders').update({
      'status': 'waitingCourierApproval',
      'admin_message': 'تم تأكيد الطلب والموافقة على السعر من قِبل العميل ⏳',
    }).eq('id', orderId);

    if (orderIndex != -1) {
      orders[orderIndex]['status'] = 'waitingCourierApproval';
      orders[orderIndex]['admin_message'] = 'تم تأكيد الطلب والموافقة على السعر من قِبل العميل ⏳';
    }

    addNotification('تأكيد الطلب 👍', 'تم تأكيد طلبك #$orderId وجاري إشعار المندوب');
    notifyListeners();
  }

  Future<void> customerConfirmOrder(dynamic orderId) async {
    await customerApprovePricing(orderId);
  }

  Future<void> customerCancelOrder(dynamic orderId) async {
    final orderIndex = orders.indexWhere((o) => o['id'].toString() == orderId.toString());

    await supabase.from('orders').update({
      'status': 'cancelledByCustomer',
      'admin_message': 'تم إلغاء الطلب من قِبل العميل ❌',
    }).eq('id', orderId);

    if (orderIndex != -1) {
      orders[orderIndex]['status'] = 'cancelledByCustomer';
      orders[orderIndex]['admin_message'] = 'تم إلغاء الطلب من قِبل العميل ❌';
    }

    addNotification('إلغاء الطلب ❌', 'تم إلغاء الطلب #$orderId بناءً على رغبتك');
    notifyListeners();
  }

  Future<void> courierRespondToOrder(dynamic orderId, bool accepted) async {
    final orderIndex = orders.indexWhere((o) => o['id'].toString() == orderId.toString());

    if (accepted) {
      await supabase.from('orders').update({
        'status': 'onTheWay',
        'admin_message': 'المندوب قَبِل الطلب وهو في الطريق 🟢',
      }).eq('id', orderId);

      if (orderIndex != -1) {
        orders[orderIndex]['status'] = 'onTheWay';
        orders[orderIndex]['admin_message'] = 'المندوب قَبِل الطلب وهو في الطريق 🟢';
      }

      if (currentCourier != null) {
        String cId = currentCourier!['id'].toString();
        await supabase.from('couriers').update({'status': 'busy'}).eq('id', cId);
        currentCourier!['status'] = 'busy';
      }
    } else {
      await supabase.from('orders').update({
        'status': 'rejectedByCourier',
        'admin_message': '⚠️ المندوب رَفَض الطلب!',
        'assigned_courier': 'لم يتم التعيين',
        'is_fee_sent': false,
      }).eq('id', orderId);

      if (orderIndex != -1) {
        orders[orderIndex]['status'] = 'rejectedByCourier';
        orders[orderIndex]['admin_message'] = '⚠️ المندوب رَفَض الطلب!';
        orders[orderIndex]['assigned_courier'] = 'لم يتم التعيين';
        orders[orderIndex]['is_fee_sent'] = false;
      }
    }
    notifyListeners();
  }

  Future<void> courierUpdateArrival(dynamic orderId) async {
    final orderIndex = orders.indexWhere((o) => o['id'].toString() == orderId.toString());

    await supabase.from('orders').update({
      'status': 'arrived',
      'admin_message': 'المندوب وصل لموقع العميل 📍',
    }).eq('id', orderId);

    if (orderIndex != -1) {
      orders[orderIndex]['status'] = 'arrived';
      orders[orderIndex]['admin_message'] = 'المندوب وصل لموقع العميل 📍';
    }
    notifyListeners();
  }

  Future<void> markOrderDelivered(dynamic orderId) async {
    final orderIndex = orders.indexWhere((o) => o['id'].toString() == orderId.toString());

    await supabase.from('orders').update({
      'status': 'delivered',
      'admin_message': 'تم تسليم الطلب بنجاح ✅',
    }).eq('id', orderId);

    if (orderIndex != -1) {
      orders[orderIndex]['status'] = 'delivered';
      orders[orderIndex]['admin_message'] = 'تم تسليم الطلب بنجاح ✅';
    }

    if (currentCourier != null) {
      String cId = currentCourier!['id'].toString();
      await supabase.from('couriers').update({'status': 'available'}).eq('id', cId);
      currentCourier!['status'] = 'available';
    }
    notifyListeners();
  }
}

class _UserMock {
  final String name;
  final String phone;
  _UserMock(this.name, this.phone);
}
