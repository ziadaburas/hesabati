import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '/core/constants/app_colors.dart';
import '/core/constants/app_constants.dart';
import '/presentation/controllers/controllers.dart';
import '/data/services/database_service.dart';
import '/presentation/screens/edit_profile_screen.dart';
import '/presentation/screens/sync_status_screen.dart';
import '/presentation/screens/reports_screen.dart';
import '/presentation/screens/initial_choice_screen.dart';

/// شاشة الإعدادات
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = Get.find<AuthController>();
    final settingsController = Get.find<SettingsController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('الإعدادات'),
      ),
      body: ListView(
        children: [
          // معلومات المستخدم
          _buildUserSection(authController),
          const Divider(height: 1),

          // إعدادات التطبيق
          _buildSettingsSection(settingsController),
          const Divider(height: 1),

          // الأدوات
          _buildToolsSection(authController),
          const Divider(height: 1),

          // حول التطبيق
          _buildAboutSection(),
          const Divider(height: 1),

          // تسجيل الخروج
          _buildLogoutSection(authController),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUserSection(AuthController authController) {
    return Obx(() {
      final user = authController.currentUser.value;
      final isAuthenticated = authController.isAuthenticatedMode;
      
      return ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          radius: 30,
          backgroundColor: AppColors.primary.withOpacity(0.1),
          backgroundImage: user?.profilePictureUrl != null
              ? NetworkImage(user!.profilePictureUrl!)
              : null,
          child: user?.profilePictureUrl == null
              ? const Icon(Icons.person, size: 30, color: AppColors.primary)
              : null,
        ),
        title: Text(
          user?.username ?? 'مستخدم محلي',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (user?.email != null && user!.email.isNotEmpty)
              Text(user.email),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (isAuthenticated ? AppColors.success : AppColors.warning)
                    .withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAuthenticated ? 'حساب مفعل' : 'وضع محلي',
                style: TextStyle(
                  fontSize: 12,
                  color: isAuthenticated ? AppColors.success : AppColors.warning,
                ),
              ),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Get.to(() => const EditProfileScreen()),
      );
    });
  }

  Widget _buildSettingsSection(SettingsController settingsController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'إعدادات التطبيق',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // اللغة
        Obx(() => ListTile(
          leading: const Icon(Icons.language),
          title: const Text('اللغة'),
          subtitle: Text(settingsController.currentLanguageLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showLanguageDialog(settingsController),
        )),

        // الثيم
        Obx(() => ListTile(
          leading: const Icon(Icons.palette),
          title: const Text('المظهر'),
          subtitle: Text(settingsController.currentThemeLabel),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showThemeDialog(settingsController),
        )),

        // الإشعارات
        Obx(() => SwitchListTile(
          secondary: const Icon(Icons.notifications),
          title: const Text('الإشعارات'),
          subtitle: const Text('تفعيل إشعارات التطبيق'),
          value: settingsController.notificationsEnabled.value,
          onChanged: (_) => settingsController.toggleNotifications(),
        )),

        // الصوت
        Obx(() => SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: const Text('الأصوات'),
          subtitle: const Text('تفعيل أصوات التنبيهات'),
          value: settingsController.soundEnabled.value,
          onChanged: (_) => settingsController.toggleSound(),
        )),
      ],
    );
  }

  Widget _buildToolsSection(AuthController authController) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'الأدوات',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // حالة المزامنة
        if (authController.isAuthenticatedMode)
          ListTile(
            leading: const Icon(Icons.sync),
            title: const Text('حالة المزامنة'),
            subtitle: const Text('عرض حالة مزامنة البيانات'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Get.to(() => const SyncStatusScreen()),
          ),

        // التقارير
        ListTile(
          leading: const Icon(Icons.bar_chart),
          title: const Text('التقارير'),
          subtitle: const Text('عرض تقارير الحسابات'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Get.to(() => const ReportsScreen()),
        ),

        // حذف البيانات
        ListTile(
          leading: const Icon(Icons.delete_forever, color: AppColors.error),
          title: const Text(
            'حذف جميع البيانات',
            style: TextStyle(color: AppColors.error),
          ),
          subtitle: const Text('حذف جميع الحسابات والعمليات'),
          trailing: const Icon(Icons.chevron_right, color: AppColors.error),
          onTap: () => _confirmDeleteAllData(),
        ),
      ],
    );
  }

  Widget _buildAboutSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Text(
            'حول التطبيق',
            style: TextStyle(
              color: Colors.grey[600],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        ListTile(
          leading: const Icon(Icons.info),
          title: const Text('عن التطبيق'),
          subtitle: Text('${AppConstants.appNameAr} v${AppConstants.appVersion}'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => _showAboutDialog(),
        ),

        ListTile(
          leading: const Icon(Icons.policy),
          title: const Text('سياسة الخصوصية'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // فتح سياسة الخصوصية
          },
        ),

        ListTile(
          leading: const Icon(Icons.article),
          title: const Text('شروط الاستخدام'),
          trailing: const Icon(Icons.chevron_right),
          onTap: () {
            // فتح شروط الاستخدام
          },
        ),
      ],
    );
  }

  Widget _buildLogoutSection(AuthController authController) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(authController),
        icon: const Icon(Icons.logout),
        label: Text(authController.isAuthenticatedMode
            ? 'تسجيل الخروج'
            : 'تغيير وضع الاستخدام'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          minimumSize: const Size(double.infinity, 48),
        ),
      ),
    );
  }

  void _showLanguageDialog(SettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('اختر اللغة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('العربية'),
              value: AppConstants.languageArabic,
              groupValue: controller.language.value,
              onChanged: (value) {
                controller.changeLanguage(value!);
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: const Text('English'),
              value: AppConstants.languageEnglish,
              groupValue: controller.language.value,
              onChanged: (value) {
                controller.changeLanguage(value!);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showThemeDialog(SettingsController controller) {
    Get.dialog(
      AlertDialog(
        title: const Text('اختر المظهر'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('فاتح'),
              secondary: const Icon(Icons.light_mode),
              value: 'light',
              groupValue: controller.themeMode.value,
              onChanged: (value) {
                controller.changeTheme(value!);
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: const Text('داكن'),
              secondary: const Icon(Icons.dark_mode),
              value: 'dark',
              groupValue: controller.themeMode.value,
              onChanged: (value) {
                controller.changeTheme(value!);
                Get.back();
              },
            ),
            RadioListTile<String>(
              title: const Text('النظام'),
              secondary: const Icon(Icons.settings_brightness),
              value: 'system',
              groupValue: controller.themeMode.value,
              onChanged: (value) {
                controller.changeTheme(value!);
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteAllData() {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: const Text(
          'هل أنت متأكد من حذف جميع البيانات؟\n\nهذا الإجراء لا يمكن التراجع عنه!',
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await DatabaseService.instance.clearAllData();
              Get.snackbar(
                'نجح',
                'تم حذف جميع البيانات',
                snackPosition: SnackPosition.BOTTOM,
                backgroundColor: AppColors.success,
                colorText: Colors.white,
              );
              // تحديث البيانات
              Get.find<LocalAccountController>().fetchLocalAccounts();
            },
            child: const Text('حذف', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.account_balance_wallet,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            const Text(AppConstants.appNameAr),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('الإصدار: ${AppConstants.appVersion}'),
            const SizedBox(height: 16),
            const Text(
              'تطبيق لإدارة الحسابات المالية الشخصية والمشتركة',
            ),
            const SizedBox(height: 16),
            const Text(
              '© 2024 جميع الحقوق محفوظة',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  void _confirmLogout(AuthController authController) {
    Get.dialog(
      AlertDialog(
        title: const Text('تأكيد'),
        content: Text(authController.isAuthenticatedMode
            ? 'هل أنت متأكد من تسجيل الخروج؟'
            : 'هل تريد تغيير وضع الاستخدام؟'),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () async {
              Get.back();
              await authController.signOut();
              Get.offAll(() => const InitialChoiceScreen());
            },
            child: Text(
              authController.isAuthenticatedMode ? 'تسجيل الخروج' : 'تغيير',
              style: const TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}
