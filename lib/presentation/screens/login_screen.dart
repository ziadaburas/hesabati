import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/presentation/controllers/controllers.dart';
import '/presentation/screens/signup_complete_screen.dart';
import '/presentation/screens/dashboard_screen.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('تسجيل الدخول'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              const Icon(
                Icons.account_circle_rounded,
                size: 100,
                color: AppColors.primary,
              ),
              const SizedBox(height: 32),
              
              // Title
              const Text(
                'تسجيل الدخول',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'استخدم حساب Google للمتابعة',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 48),
              
              // Error Message
              Obx(() {
                if (authController.errorMessage.value.isNotEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.error.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: AppColors.error),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            authController.errorMessage.value,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: AppColors.error, size: 20),
                          onPressed: () => authController.clearError(),
                        ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              
              // Google Sign-in Button
              Obx(() => ElevatedButton.icon(
                onPressed: authController.isLoading.value
                    ? null
                    : () => _signInWithGoogle(authController),
                icon: authController.isLoading.value
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.g_mobiledata_rounded, size: 32),
                label: Text(
                  authController.isLoading.value
                      ? 'جاري تسجيل الدخول...'
                      : 'تسجيل الدخول عبر Google',
                  style: const TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              )),
              const SizedBox(height: 24),
              
              // Continue without account
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: const Text('متابعة بدون حساب'),
              ),
              
              const Spacer(),
              
              // Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: AppColors.info),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'تسجيل الدخول يتيح لك المزامنة والحسابات المشتركة',
                        style: TextStyle(
                          color: AppColors.info,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _signInWithGoogle(AuthController authController) async {
    final success = await authController.signInWithGoogle();
    
    if (success) {
      // التحقق إذا كان المستخدم جديداً
      final user = authController.currentUser.value;
      if (user != null && (user.phone == null || user.phone!.isEmpty)) {
        // مستخدم جديد - الانتقال لإكمال البيانات
        Get.off(() => const SignupCompleteScreen());
      } else {
        // مستخدم موجود - الانتقال للوحة التحكم
        Get.off(() => const DashboardScreen());
      }
    }
  }
}
