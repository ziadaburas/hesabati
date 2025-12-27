import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '/data/services/firebase_service.dart';
import '/data/services/database_service.dart';
import '/domain/entities/entities.dart';
import '/core/constants/app_constants.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/foundation.dart';

/// وحدة التحكم في المصادقة
class AuthController extends GetxController {
  // Properties
  final isLoggedIn = false.obs;
  final isLoading = false.obs;
  final currentUser = Rxn<UserEntity>();
  final errorMessage = ''.obs;
  final userType = AppConstants.userTypeLocal.obs;
  final lastSyncTime = ''.obs;

  // Services
  final FirebaseService _firebaseService = FirebaseService.instance;
  final DatabaseService _databaseService = DatabaseService.instance;

  @override
  void onInit() {
    super.onInit();
    _initAuthState();
  }

  /// تهيئة حالة المصادقة
  Future<void> _initAuthState() async {
    await restoreSession();
    
    // الاستماع لتغييرات حالة المصادقة من Firebase
    _firebaseService.authStateChanges.listen((user) {
      if (user != null) {
        isLoggedIn.value = true;
        userType.value = AppConstants.userTypeAuthenticated;
        _loadUserData();
      }
    });
  }

  /// استعادة الجلسة المحفوظة
  Future<void> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUserId = prefs.getString(AppConstants.keyUserId);
      final savedUserType = prefs.getString(AppConstants.keyUserType);
      final savedIsLoggedIn = prefs.getBool(AppConstants.keyIsLoggedIn) ?? false;
      final savedLastSync = prefs.getString(AppConstants.keyLastSyncTime);

      if (savedLastSync != null) {
        lastSyncTime.value = savedLastSync;
      }

      if (savedIsLoggedIn && savedUserId != null) {
        userType.value = savedUserType ?? AppConstants.userTypeLocal;
        
        if (userType.value == AppConstants.userTypeAuthenticated) {
          // تحميل بيانات المستخدم من Firebase
          await _loadUserData();
        } else {
          // تحميل بيانات المستخدم المحلي
          await _loadLocalUser(savedUserId);
        }
        
        isLoggedIn.value = true;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Restore session error: $e');
      }
    }
  }

  /// تحميل بيانات المستخدم من Firebase
  Future<void> _loadUserData() async {
    try {
      final userData = await _firebaseService.getUserData();
      if (userData != null) {
        currentUser.value = userData;
        await _saveSession(userData.userId, AppConstants.userTypeAuthenticated);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Load user data error: $e');
      }
    }
  }

  /// تحميل بيانات المستخدم المحلي
  Future<void> _loadLocalUser(String userId) async {
    try {
      final results = await _databaseService.query(
        'users',
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results.isNotEmpty) {
        currentUser.value = UserEntity.fromMap(results.first);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Load local user error: $e');
      }
    }
  }

  /// تسجيل الدخول باستخدام Google
  Future<bool> signInWithGoogle() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final userCredential = await _firebaseService.signInWithGoogle();
      
      if (userCredential != null && userCredential.user != null) {
        // تحميل بيانات المستخدم
        await _loadUserData();
        
        isLoggedIn.value = true;
        userType.value = AppConstants.userTypeAuthenticated;
        
        return true;
      }
      
      return false;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء تسجيل الدخول: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// إنشاء مستخدم محلي
  Future<bool> createLocalUser() async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      final userId = const Uuid().v4();
      final now = DateTime.now();
      
      final localUser = UserEntity(
        userId: userId,
        username: 'مستخدم محلي',
        email: '',
        userType: AppConstants.userTypeLocal,
        createdAt: now,
        updatedAt: now,
        isSynced: false,
      );

      // حفظ في قاعدة البيانات المحلية
      await _databaseService.insert('users', localUser.toMap());

      // حفظ الجلسة
      await _saveSession(userId, AppConstants.userTypeLocal);

      currentUser.value = localUser;
      isLoggedIn.value = true;
      userType.value = AppConstants.userTypeLocal;

      return true;
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء إنشاء المستخدم المحلي: $e';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  /// حفظ الجلسة
  Future<void> _saveSession(String userId, String type) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.keyUserId, userId);
      await prefs.setString(AppConstants.keyUserType, type);
      await prefs.setBool(AppConstants.keyIsLoggedIn, true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Save session error: $e');
      }
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() async {
    try {
      isLoading.value = true;
      
      if (userType.value == AppConstants.userTypeAuthenticated) {
        await _firebaseService.signOut();
      }

      // مسح الجلسة
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.keyUserId);
      await prefs.remove(AppConstants.keyUserType);
      await prefs.setBool(AppConstants.keyIsLoggedIn, false);

      // إعادة تعيين الحالة
      currentUser.value = null;
      isLoggedIn.value = false;
      userType.value = AppConstants.userTypeLocal;
      errorMessage.value = '';
    } catch (e) {
      errorMessage.value = 'حدث خطأ أثناء تسجيل الخروج: $e';
    } finally {
      isLoading.value = false;
    }
  }

  /// التحقق مما إذا كان المستخدم مصادقاً
  Future<bool> isUserAuthenticated() async {
    return _firebaseService.isLoggedIn;
  }

  /// مسح رسالة الخطأ
  void clearError() {
    errorMessage.value = '';
  }

  /// تحديث وقت آخر مزامنة
  Future<void> updateLastSyncTime() async {
    final now = DateTime.now().toIso8601String();
    lastSyncTime.value = now;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.keyLastSyncTime, now);
  }

  /// الحصول على User ID الحالي
  String get currentUserId => currentUser.value?.userId ?? 'local_user';

  /// هل المستخدم في الوضع المحلي؟
  bool get isLocalMode => userType.value == AppConstants.userTypeLocal;

  /// هل المستخدم في الوضع المتصل؟
  bool get isAuthenticatedMode => userType.value == AppConstants.userTypeAuthenticated;
}
