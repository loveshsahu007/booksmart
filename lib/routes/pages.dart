import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/modules/cpa/ui/chat_list_screen.dart';
import 'package:booksmart/modules/cpa/ui/profile_screen.dart';
import 'package:booksmart/modules/cpa/ui/profile_under_review_screen.dart';
import 'package:booksmart/modules/cpa/ui/settings_screen.dart';
import 'package:booksmart/modules/common/ui/authentication/login_screen.dart';
import 'package:booksmart/modules/common/ui/authentication/signup_screen.dart';
import 'package:booksmart/modules/user/ui/chat/chat_screen.dart';
import 'package:booksmart/modules/user/ui/cpa/dashboard_screen.dart';
import 'package:booksmart/modules/user/ui/home/template/web_template.dart';
import 'package:booksmart/modules/user/ui/bulk_review/bulk_review_screen.dart';
import 'package:booksmart/modules/user/ui/token/streak_unlocked_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../modules/common/ui/authentication/verify_email_screen.dart';
import '../modules/cpa/ui/earning_screen.dart';
import '../modules/cpa/ui/home/home_screen.dart';
import '../modules/cpa/ui/home/template/web_template.dart';
import '../modules/cpa/ui/leads_screen.dart';
import '../modules/user/ui/ai_strategy_screen.dart';
import '../modules/common/ui/authentication/forgot.dart';
import '../modules/user/ui/financial_statement/financial_statement.dart';
import '../modules/user/ui/home/home_screen.dart';
import '../modules/user/ui/profile_screen.dart';
import '../modules/user/ui/rules_management/rules_management_screen.dart';
import '../modules/user/ui/settings/settings_screen.dart';
import '../modules/user/ui/subscription/subscription_screen.dart';
import '../modules/user/ui/tax_filling/tax_filling.dart';
import '../modules/user/ui/token/buy_tokens_screen.dart';
import '../modules/user/ui/token/earn_tokens_screen.dart';

class AppPages {
  static final routes = [
    // external
    GetPage(name: Routes.login, page: () => const LoginScreen()),
    GetPage(
      name: Routes.forgotReset,
      page: () => const ForgotResetPasswordScreen(isReset: true),
    ),
    GetPage(name: Routes.signUp, page: () => const SignupScreen()),
    GetPage(name: Routes.verifyEmail, page: () => const VerifyEmailScreen()),

    // internal
    GetPage(name: Routes.bulkReview, page: () => const BulkReviewScreen()),
    GetPage(name: Routes.buyTokens, page: () => const BuyTokensScreen()),
    GetPage(
      name: Routes.streakUnlocked,
      page: () => const StreakUnlockedScreen(),
    ),
    // GetPage(
    //   name: Routes.organization,
    //   page: () => const OrganizationListScreen(),
    // ),
    GetPage(
      name: Routes.rulesManagement,
      page: () => const RulesManagementScreen(),
    ),
    GetPage(name: Routes.subscription, page: () => const SubscriptionScreen()),

    // Web Side-bar
    GetPage(name: Routes.home, page: () => HomeScreen()),
    GetPage(
      name: Routes.report,
      page: () => kIsWeb
          ? WebTemplate(child: FinancialReportPage())
          : FinancialReportPage(),
    ),
    GetPage(
      name: Routes.tax,
      page: () =>
          kIsWeb ? WebTemplate(child: TexFillingSceen()) : TexFillingSceen(),
    ),
    GetPage(
      name: Routes.tokens,
      page: () =>
          kIsWeb ? WebTemplate(child: EarnTokensScreen()) : EarnTokensScreen(),
    ),
    GetPage(
      name: Routes.aiChat,
      page: () =>
          kIsWeb ? WebTemplate(child: AIChatingScreen()) : AIChatingScreen(),
    ),
    GetPage(
      name: Routes.chat,
      page: () =>
          kIsWeb ? WebTemplate(child: ChatListScreen()) : ChatListScreen(),
    ),
    GetPage(
      name: Routes.cpaNetwork,
      page: () =>
          kIsWeb ? WebTemplate(child: CpaNetworkScreen()) : CpaNetworkScreen(),
    ),
    GetPage(
      name: Routes.settings,
      page: () =>
          kIsWeb ? WebTemplate(child: SettingsScreen()) : SettingsScreen(),
    ),
    GetPage(
      name: Routes.aiStrategy,
      page: () => kIsWeb
          ? WebTemplate(child: AiStrategyScreen())
          : const AiStrategyScreen(),
    ),
    // TODO: need to finilize the profile-screen
    GetPage(
      name: Routes.profileScreen,
      page: () =>
          // kIsWeb
          //     ? WebTemplate(child: UserProfileScreen())
          //     :
          const UserProfileScreen(),
    ),

    /// ====
    /// =====
    /// ======
    /// CPA MODULE ROUTES
    /// ======
    /// =====
    /// ====
    GetPage(name: Routes.dashboardCPA, page: () => HomeScreenCPA()),
    GetPage(
      name: Routes.leadsCPA,
      page: () => kIsWeb
          ? WebTemplateCPA(child: LeadsScreenCPA())
          : const LeadsScreenCPA(),
    ),
    GetPage(
      name: Routes.billingCPA,
      page: () => kIsWeb
          ? WebTemplateCPA(child: EarningScreenCPA())
          : const EarningScreenCPA(),
    ),
    GetPage(
      name: Routes.chatCPA,
      page: () =>
          kIsWeb ? WebTemplateCPA(child: ChatListScreen()) : ChatListScreen(),
    ),

    GetPage(
      name: Routes.settingsCPA,
      page: () => kIsWeb
          ? WebTemplateCPA(child: SettingsScreenCPA())
          : const SettingsScreenCPA(),
    ),

    GetPage(name: Routes.profileScreenCPA, page: () => ProfileScreenCPA()),
    GetPage(
      name: Routes.profileUnderReviewCPA,
      page: () => ProfileUnderReviewScreenCPA(),
    ),
  ];
}
