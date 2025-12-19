import 'dart:developer';

import 'package:booksmart/constant/exports.dart';
import 'package:booksmart/controllers/auth_controller.dart';
import 'package:booksmart/controllers/organization_controller.dart';
import 'package:booksmart/modules/common/providers/auth_provider.dart';
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
import 'package:booksmart/utils/initial_utils.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/user_base_model.dart';
import '../modules/common/ui/authentication/verify_email_screen.dart';
import '../modules/common/ui/error_screen.dart';
import '../modules/cpa/ui/earning_screen.dart';
import '../modules/cpa/ui/home/home_screen.dart';
import '../modules/cpa/ui/home/template/web_template.dart';
import '../modules/cpa/ui/leads_screen.dart';
import '../modules/user/ui/ai_strategy_screen.dart';
import '../modules/common/ui/authentication/forgot.dart';
import '../modules/user/ui/financial_statement/financial_statement.dart';
import '../modules/user/ui/home/home_screen.dart';
import '../modules/user/ui/organization/organization_list_screen.dart';
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
    GetPage(
      name: Routes.bulkReview,
      page: () => getRequiredScreen(const BulkReviewScreen(), UserRole.user),
    ),
    GetPage(
      name: Routes.buyTokens,
      page: () => getRequiredScreen(const BuyTokensScreen(), UserRole.user),
    ),
    GetPage(
      name: Routes.streakUnlocked,
      page: () =>
          getRequiredScreen(const StreakUnlockedScreen(), UserRole.user),
    ),
    GetPage(
      name: Routes.rulesManagement,
      page: () =>
          getRequiredScreen(const RulesManagementScreen(), UserRole.user),
    ),
    GetPage(
      name: Routes.subscription,
      page: () => getRequiredScreen(const SubscriptionScreen(), UserRole.user),
    ),

    // Web Side-bar
    GetPage(
      name: Routes.home,
      page: () => getRequiredScreen(HomeScreen(), UserRole.user),
    ),
    GetPage(
      name: Routes.report,
      page: () => getRequiredScreen(
        kIsWeb
            ? WebTemplate(child: FinancialReportPage())
            : FinancialReportPage(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.tax,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: TexFillingSceen()) : TexFillingSceen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.tokens,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: EarnTokensScreen()) : EarnTokensScreen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.aiChat,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: AIChatingScreen()) : AIChatingScreen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.chat,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: ChatListScreen()) : ChatListScreen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.cpaNetwork,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: CpaNetworkScreen()) : CpaNetworkScreen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.settings,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: SettingsScreen()) : SettingsScreen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.aiStrategy,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: AiStrategyScreen()) : AiStrategyScreen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.userProfile,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplate(child: UserProfileScreen()) : UserProfileScreen(),
        UserRole.user,
      ),
    ),
    GetPage(
      name: Routes.userOrganizations,
      page: () => getRequiredScreen(
        kIsWeb
            ? WebTemplate(child: OrganizationListScreen())
            : OrganizationListScreen(),
        UserRole.user,
      ),
    ),

    /// ====
    /// =====
    /// ======
    /// CPA MODULE ROUTES
    /// ======
    /// =====
    /// ====
    GetPage(
      name: Routes.cpaDashboard,
      page: () => getRequiredScreen(HomeScreenCPA(), UserRole.cpa),
    ),
    GetPage(
      name: Routes.cpaLeads,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplateCPA(child: LeadsScreenCPA()) : LeadsScreenCPA(),
        UserRole.cpa,
      ),
    ),
    GetPage(
      name: Routes.cpaBilling,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplateCPA(child: EarningScreenCPA()) : EarningScreenCPA(),
        UserRole.cpa,
      ),
    ),
    GetPage(
      name: Routes.cpaChat,
      page: () => getRequiredScreen(
        kIsWeb ? WebTemplateCPA(child: ChatListScreen()) : ChatListScreen(),
        UserRole.cpa,
      ),
    ),

    GetPage(
      name: Routes.cpaSettings,
      page: () => getRequiredScreen(
        kIsWeb
            ? WebTemplateCPA(child: SettingsScreenCPA())
            : const SettingsScreenCPA(),
        UserRole.cpa,
      ),
    ),

    GetPage(
      name: Routes.cpaProfile,
      page: () => getRequiredScreen(ProfileScreenCPA(), UserRole.cpa),
    ),
    GetPage(
      name: Routes.cpaProfileUnderReview,
      page: () =>
          getRequiredScreen(ProfileUnderReviewScreenCPA(), UserRole.cpa),
    ),
  ];
}

Widget getRequiredScreen(Widget desiredWidget, UserRole role) {
  log("=== ${Get.currentRoute} === ");
  if (isUserLoggedIn && Get.isRegistered<AuthController>()) {
    if (authPerson?.role == role) {
      if (role == UserRole.user) {
        bool isUserProfileOk = isUserProfileCompleted(authUser!);
        bool isOrganizationsOk = isAnyOrganizationAvailable;
        if (isUserProfileOk && isOrganizationsOk) {
          return desiredWidget;
        } else {
          if (!isUserProfileOk && Get.currentRoute == Routes.userProfile) {
            return desiredWidget;
          } else if (!isOrganizationsOk &&
              Get.currentRoute == Routes.userOrganizations) {
            return desiredWidget;
          }
          return const ErrorScreen();
        }
      }
      return desiredWidget;
    } else {
      return const ErrorScreen();
    }
  } else {
    return const ErrorScreen(isLogInType: true);
  }
}

String getHomeScreenRoute() {
  switch (authPerson?.role) {
    case UserRole.user:
      return Routes.home;
    case UserRole.cpa:
      return Routes.cpaDashboard;
    default:
      return Routes.home;
  }
}
