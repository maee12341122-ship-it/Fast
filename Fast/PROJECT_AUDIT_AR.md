# تقرير فحص مشروع FAST / تعز إكسبرس

## حدود العمل في هذه النسخة
- تم استلام `Fast.zip` وفحص محتوياته.
- تمت إضافة مجلد Android وتهيئة Codemagic لعملية بناء APK.
- لم يتم تعديل ملفات `lib/` أو ملفات SQL أو ملفات الاتصال بقاعدة البيانات.
- لا يحتوي ملف المصدر على مجلد Android سابقاً.
- لم يتم إنتاج APK أو إجراء Flutter build لأن Flutter/Dart غير مثبتين في بيئة الفحص. لذلك لا يمكن ضمان نجاح البناء قبل تشغيله فعلياً على Codemagic.

## ما هو موجود
- تطبيق Flutter منظم إلى `models`, `providers`, `screens`, `services`, `utils`, `widgets`.
- اعتماد `provider` لإدارة الحالة.
- اتصال Supabase SDK داخل Flutter.
- شاشات عميل ومشرف ومندوب وسلة وطلبات ومحادثة وخريطة.
- خادم Node.js منفصل وملفات PostgreSQL وDocker Compose.
- أذونات Android للإنترنت والموقع، وهوية Android: `com.taizexpress.taiz_express`.
- Codemagic يبني APK Release ويجمع ملف APK الناتج.

## نتائج فحص حاسمة

### أولوية حرجة - المصادقة والأمان
1. رمز الهاتف يُنشأ محلياً داخل التطبيق باستخدام `Random`؛ لا يوجد إرسال OTP حقيقي من الخادم.
2. `sendOtpViaWhatsAppDirect` يفتح `wa.me` مع رسالة جاهزة على الرقم المدخل؛ لا يرسلها تلقائياً ولا يؤكد استلام الخادم لها.
3. شاشة OTP تحتوي على `if (verified || true)`، وبالتالي تسمح بالاستمرار حتى عندما يكون الرمز خاطئاً.
4. كلمة مرور المشرف `admin1234` ثابتة داخل تطبيق Flutter.
5. كلمات مرور المندوبين تُرسل وتُحفظ في جدول Supabase كنص واضح، ثم تتم المقارنة محلياً.
6. لا يظهر في ملفات Flutter استخدام Supabase Auth لتسجيل المستخدمين أو إدارة الجلسات. جلسة المشرف والمندوب تُحفظ محلياً في SharedPreferences.
7. لا توجد في الأرشيف ملفات SQL واضحة لسياسات RLS أو تقييد وصول الجداول. يجب إعداد RLS وسياسات دقيقة قبل نشر مفتاح العميل.

### أولوية حرجة - عدم تطابق قاعدة البيانات
Flutter يتعامل مباشرة مع الجداول التالية: `customers`, `couriers`, `settings`, `products`, `orders`, `chat_messages`.
أما `backend/db/schema.sql` فينشئ: `users`, `restaurants`, `products`, `orders`, `order_items`, `courier_locations`, `app_settings`.
كما تختلف أسماء أعمدة مهمة، مثل:
- Flutter `products.price`, `products.available`, `products.restaurant_name` مقابل SQL `price_yer`, `is_available`, `restaurant_id`.
- Flutter `settings.start_hour/end_hour` مقابل SQL `app_settings.key/value`.
- Flutter `orders.phone/address/products_total/total_price` مقابل SQL `customer_phone/address_text/subtotal_yer/total_yer`.
- جداول `customers`, `couriers`, `settings`, `chat_messages` غير موجودة في ملف SQL المرفق.

بالتالي، لا يكفي أن يكون مشروع Supabase موجوداً؛ يجب توحيد مخطط الجداول والأعمدة وسياسات الوصول بين التطبيق وقاعدة البيانات قبل الاعتماد التشغيلي.

### أولوية عالية - الطلبات والدفع
1. حالات الطلب في التطبيق مثل `waitingForPricing`, `pricingSentToCustomer`, `waitingCourierApproval`, `onTheWay`, `arrived`, `cancelledByCustomer` لا تتطابق مع القيم المسموح بها في SQL مثل `pending`, `accepted`, `preparing`, `ready`, `assigned`, `picked_up`, `on_the_way`, `delivered`, `cancelled`.
2. إنشاء الطلب في Flutter لا يرسل كل الحقول الإلزامية الموجودة في مخطط SQL (منها `customer_id` و`restaurant_id` وفق المخطط المرفق).
3. `markOrderDelivered` يغير حالة الطلب إلى delivered لكنه لا يؤكد تحصيل المبلغ ولا يحدث `payment_status` أو حقول التحصيل، رغم أن SQL يشترط بيانات التحصيل عند حالة collected.
4. قيمة الطلب ورسومه تعتمد على أرقام `double` في التطبيق بينما المخطط يستخدم مبالغ صحيحة بالريال اليمني (`BIGINT`).
5. توزيع المندوبين وبعض انتقالات الحالة تتم محلياً أو بأسماء حقول مختلفة؛ يلزم نقل منطق الأعمال الحساس إلى الخادم والتحقق من صلاحيات كل دور.

### أولوية عالية - الربط والتشغيل
1. ملف `backend/src/config.js` يضع افتراضاً `sqlite:./db/database.sqlite` رغم أن طبقة الاتصال تستخدم مكتبة PostgreSQL `pg`. هذا الافتراض غير صالح كعنوان PostgreSQL.
2. يوجد JWT secret افتراضي ثابت داخل `backend/src/config.js`؛ يجب فرض متغير `JWT_SECRET` قوي في بيئة النشر وإيقاف الخادم إذا لم يُضبط في الإنتاج.
3. ملف `lib/utils/constants.dart` يستخدم `http://localhost:3000/api`. على هاتف العميل، localhost يشير إلى الهاتف نفسه وليس إلى خادم الإنترنت. كما لم يظهر استدعاء فعلي لهذا الـ API في شاشات Flutter التي فُحصت.
4. إعدادات Supabase داخل `main.dart` مكتوبة مباشرة في التطبيق. مفتاح publishable/anon مخصص للعميل ويمكن أن يكون في التطبيق بشرط RLS محكم؛ لا تضع مطلقاً مفتاح `service_role` أو أي سر إداري في Flutter.
5. لم توجد ملفات migration أو ملف واضح يشرح بنية جداول Supabase الفعلية وسياساتها داخل الأرشيف.

### أولوية عالية - وظائف لم تكتمل
1. `requestLocationAndNotificationPermissions` لا يطلب أذونات فعلية؛ يطبع رسالة ويضيف إشعاراً محلياً فقط.
2. الإشعارات الفعلية (FCM أو بديل) غير مهيأة.
3. تتبع المندوب المباشر وإرسال إحداثياته إلى الخادم/قاعدة البيانات غير مكتمل في تدفق التطبيق الظاهر.
4. `sendChatMessage` يحاول الحفظ في `chat_messages` لكنه يكتفي بالنسخة المحلية عند الفشل، والجدول غير موجود في SQL المرفق.
5. السلة والملف الشخصي وحساب العميل لا يظهر لها حفظ سحابي/استعادة متكاملة؛ بيانات الجلسة محلية ومحدودة.
6. خرائط OpenStreetMap تتطلب اتصال إنترنت، ولم يظهر تعامل كامل مع فشل تحميل البلاطات أو سياسة استخدام البلاطات في الإنتاج.

### أخطاء/تعارضات تحليل Dart إضافية
1. `lib/models/order_model.dart` يحتوي سطراً غير مكتمل نحوياً: `(json['items'] as List).whereType>()`؛ هذا يمنع تحليل هذا الملف عند دخوله ضمن التحليل.
2. `lib/screens/main_shell.dart` يقرأ `AppState.cartItemCount` غير الموجود، وينشئ `HomeScreen(onOpenDrawer: ...)` و`CartScreen(onOpenDrawer: ...)` مع أن منشئي هاتين الشاشتين لا يقبلان هذا الوسيط.
3. `lib/screens/profile_screen.dart` و`lib/screens/app_drawer.dart` و`lib/screens/register_screen.dart` تعتمد على `AppState.user` و`themeMode` و`setThemeMode` و`setUser` غير الموجودة في `AppState` الحالي.
4. `lib/screens/admin_dashboard.dart` يعتمد على دوال/خصائص غير موجودة في `AppState` مثل `assignOrderToCourier`, `setCourierAvailability`, `removeCourier`, `updateBusinessSettings`, `removeProduct`, `upsertProduct`, وخصائص ساعات/رسوم العمل البديلة.
5. لم يتم إصلاح هذه الأخطاء احتراماً لطلب عدم تعديل `lib/`؛ يجب إصلاحها قبل الاعتماد على نتيجة `flutter analyze`، وقد تمنع بعض الشاشات من التجميع أو التشغيل.

### ملاحظات تنظيمية وواجهات
1. نقطة بدء التطبيق في `main.dart` هي `HomeScreen` مباشرة، بينما توجد شاشات `TermsScreen` و`MainShell` و`RegisterScreen` و`ProfileScreen` وبنى أخرى منفصلة؛ يلزم تحديد تدفق تنقل موحد.
2. توجد ملفات/شاشات بديلة ومتداخلة مثل `admin_screen.dart` و`admin_dashboard.dart`، و`courier_screen.dart` و`delivery_dashboard.dart`، ومجلد `main_shell.dart`؛ يجب تحديد المعتمد وإزالة التكرار بعد موافقة المالك.
3. الهوية البصرية في الشاشات الظاهرة تميل إلى الأسود والذهبي، لكن الأسماء النصية تتنقل بين FAST وتعز إكسبرس.
4. أيقونة التطبيق المرفقة حالياً افتراضية من Android؛ لا يوجد شعار launcher خاص جاهز ضمن الأرشيف.
5. لا توجد اختبارات Flutter ظاهرة في مجلد `test/` ولا اختبارات تكامل للتدفقات الأساسية.

## فحوصات منفذة
- `node --check` على ملفات الخادم المحددة: ناجح.
- `node --test` على اختبارات Backend: 4 اختبارات ناجحة من 4.
- لم يتم تنفيذ `flutter analyze` أو `flutter test` أو `flutter build apk` لعدم توفر Flutter/Dart في بيئة الفحص.
- لم يتم الاتصال بقاعدة Supabase الحية، ولم يتم تعديل بياناتها.

## تعليمات Codemagic
1. ارفع مجلد المشروع إلى مستودع Git متصل بـ Codemagic، بحيث يكون `pubspec.yaml` و`codemagic.yaml` في جذر المشروع.
2. اختر Workflow: `taiz-express-android-apk`.
3. اضغط Start new build.
4. الملف المتوقع عند نجاح البناء: `build/app/outputs/flutter-apk/app-release.apk`.
5. هذا الإعداد يسمح ببناء APK تجريبي بتوقيع debug. لتوزيع تجاري أو تحديث تطبيق منشور، أنشئ مفتاح Release ورفعه إلى Codemagic، ولا تفقد مفتاح التوقيع الأصلي.

## الحكم النهائي
مجلد Android وتهيئة Codemagic أُضيفا، لكن المشروع **ليس جاهزاً للإطلاق التجاري بعد**. أكبر العوائق ليست Android: إنها تجاوز OTP، كلمات المرور غير الآمنة، عدم تطابق مخطط Supabase، حالات الطلبات، وصلاحيات RLS. يجب معالجة هذه النقاط واختبار التطبيق فعلياً قبل استخدامه مع العملاء.
