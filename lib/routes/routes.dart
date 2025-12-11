abstract class Routes {
  static const String login = '/login';
  static const String forgotReset = '/forgot-reset';
  static const String signUp = '/sign-up';
  static const String verifyEmail = '/verify-email';

  /// The bottom-bar screen for mobile and side-bar for web
  static const String home = '/user/home';

  // web-side-bar routes
  static const String tax = '/user/tax';
  static const String cpaNetwork = '/user/cpa-network';
  static const String tokens = '/user/token';
  static const String report = '/user/report';
  static const String aiChat = '/user/ai-chat';
  static const String chat = '/user/chat';
  static const String settings = '/user/settings';

  //
  static const String earnTokens = '/user/earn-tokens';
  static const String bulkReview = '/user/bulk-review';
  static const String buyTokens = '/user/buy-tokens';
  static const String streakUnlocked = '/user/streak-unlocked';
  static const String tokenWallet = '/user/token-wallet';
  static const String rulesManagement = '/user/rules-management';
  static const String subscription = '/user/subscription';

  static const String aiStrategy = '/user/ai-strategy';
  static const String profileScreen = '/user/profile';

  /// ====
  /// =====
  /// ======
  /// CPA MODULE ROUTES
  /// ======
  /// =====
  /// ====

  static const String dashboardCPA = '/cpa/dashboard';
  static const String leadsCPA = '/cpa/leads';
  static const String billingCPA = '/cpa/earnings';
  static const String chatCPA = '/cpa/chat';
  static const String settingsCPA = '/cpa/settings';
  static const String profileScreenCPA = '/cpa/profile';
  static const String profileUnderReviewCPA = '/cpa/profile-under-review';
}
