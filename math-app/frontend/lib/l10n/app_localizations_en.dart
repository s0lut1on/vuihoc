// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Learning Fun';

  @override
  String get welcomeGreeting => 'Hello, little friend!';

  @override
  String get welcomeTitle => 'Start Learning!';

  @override
  String get welcomeParentAccess => 'Parent access';

  @override
  String get welcomeSubtitle => 'Let\'s learn together every day!';

  @override
  String get welcomeLanguageVi => 'English';

  @override
  String get welcomeGoogleSignIn => 'Sign in with Google';

  @override
  String get welcomeSelectPersona => 'Who are you?';

  @override
  String get welcomePersonaSubtitle => 'Pick your learning buddy!';

  @override
  String get welcomeStartButton => 'Start learning! 🚀';

  @override
  String get welcomeGuestButton => 'Try without signing in';

  @override
  String get welcomeOrDivider => 'or';

  @override
  String get welcomeBackButton => 'Back';

  @override
  String assessmentProgress(int current, int total) {
    return 'Question $current/$total';
  }

  @override
  String get assessmentQuestion1 => 'How far can your child count and read?';

  @override
  String get assessmentQuestion2 => 'Does your child know letters and numbers?';

  @override
  String get assessmentQuestion3 => 'How fast do you learn?';

  @override
  String get assessmentQuestion4 => 'What do you like most?';

  @override
  String assessmentSkip(int count) {
    return 'Skip: answered $count/4';
  }

  @override
  String get assessmentHint => 'Don\'t know? Pick the closest answer!';

  @override
  String get homeSubjects => 'Subjects';

  @override
  String get homeNavSubjects => 'Subjects';

  @override
  String get homeNavPricing => 'Pricing';

  @override
  String get homeNavContact => 'Contact';

  @override
  String get homeLessonsLearned => 'Lessons learned';

  @override
  String get homeStarsEarned => 'Stars earned';

  @override
  String homeDayStreak(int streak) {
    return '$streak day streak';
  }

  @override
  String get homeContinueAchieverLabel => 'Grab 3 stars!';

  @override
  String get homeContinueAchieverTopic => 'Addition & Reading';

  @override
  String get homeContinueGamerLabel => 'Earn 50 points!';

  @override
  String get homeContinueGamerTopic => 'Fun learning – Level 2';

  @override
  String get homeContinueStrugglerLabel => 'What today?';

  @override
  String get homeContinueStrugglerTopic => 'Letters & Numbers';

  @override
  String get homeContinueSilentLabel => 'Ready?';

  @override
  String get homeContinueSilentTopic => 'Start gently';

  @override
  String get homeDefaultName => 'Little friend';

  @override
  String get lessonNotFound => 'Lesson not found';

  @override
  String get lessonClose => 'Close';

  @override
  String get lessonHintPrefix => 'Hint';

  @override
  String get lessonCorrectFeedback => 'Correct!';

  @override
  String get lessonIncorrectFeedback => 'Try again!';

  @override
  String get lessonSpeakQuestion => 'Read question';

  @override
  String get celebrationTitle => 'Great job!';

  @override
  String celebrationStars(int stars) {
    return 'You earned $stars stars!';
  }

  @override
  String get celebrationNext => 'Continue';

  @override
  String get celebrationHome => 'Home';

  @override
  String get celebrationAchieverTitle => 'Correct!';

  @override
  String get celebrationAchieverSubtitle => 'Great job! Keep going!';

  @override
  String get celebrationGamerTitle => 'Victory!';

  @override
  String get celebrationGamerSubtitle => 'You earned +15 points!';

  @override
  String get celebrationGamerUnlock => 'Unlock: Next learning level!';

  @override
  String get celebrationStrugglerTitle => 'Great effort!';

  @override
  String get celebrationStrugglerSubtitle =>
      'Don\'t give up, let\'s try another!';

  @override
  String get celebrationSilentTitle => 'Well done!';

  @override
  String get celebrationSilentSubtitle => 'You learned something new!';

  @override
  String get pinGateTitle => 'Parent Dashboard';

  @override
  String get pinGateEnterPin => 'Enter PIN to access parent area';

  @override
  String get pinGateBack => 'Back';

  @override
  String get pinGateWrongPin => 'Wrong PIN!';

  @override
  String get parentDashboardTitle => 'Parent Dashboard';

  @override
  String get parentDashboardBackToHome => 'Back to Home';

  @override
  String get parentDashboardLessonsLearned => 'Lessons learned';

  @override
  String get parentDashboardStarsEarned => 'Stars earned';

  @override
  String get parentDashboardStudyStreak => 'Study streak';

  @override
  String get parentDashboardProgress => 'Learning Progress';

  @override
  String get parentDashboardSubjectMath => 'Math';

  @override
  String get parentDashboardSubjectNumbers => 'Numbers';

  @override
  String get parentDashboardSubjectGeometry => 'Geometry';

  @override
  String get parentDashboardSubjectMeasurement => 'Measurement';

  @override
  String get parentDashboardSubjectLogic => 'Logic';

  @override
  String get parentDashboardSubjectVietnamese => 'Vietnamese';

  @override
  String get parentDashboardSubjectEnglish => 'English';

  @override
  String get parentDashboardSettings => 'Settings';

  @override
  String get parentDashboardLanguage => 'Language';

  @override
  String get parentDashboardLanguageValue => 'English';

  @override
  String get parentDashboardStudyTime => 'Study Time';

  @override
  String get parentDashboardStudyTimeValue => '15 min/day';

  @override
  String get parentDashboardNotifications => 'Notifications';

  @override
  String get parentDashboardLogout => 'Logout';

  @override
  String get languageSwitcherLabel => 'Language';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profile => 'Profile';

  @override
  String get settings => 'Settings';

  @override
  String get settingsTtsTitle => 'Read question aloud';

  @override
  String get settingsTtsSubtitle => 'Auto-read questions during lessons';

  @override
  String get reviewScreenTitle => 'Review mistakes';

  @override
  String get reviewCardLabel => 'Review mistakes';

  @override
  String get reviewCardTopic => 'Fix questions you got wrong';

  @override
  String get reviewAllClear => 'Great job — no mistakes! 🎉';

  @override
  String reviewWrongCount(Object count) {
    return 'Wrong $count times';
  }

  @override
  String get logout => 'Logout';

  @override
  String get guestUser => 'Guest';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get loginWelcomeTitle => 'Welcome!';

  @override
  String get loginWelcomeSubtitle => 'Choose a way to start learning';

  @override
  String get loginGoogleSignIn => 'Sign in with Google';

  @override
  String get loginGuestSignIn => 'Continue without signing in';

  @override
  String get loginOrDivider => 'or';

  @override
  String get loginParentAccess => 'For parents';

  @override
  String get loginParentDialogTitle => 'For parents';

  @override
  String get loginParentDialogContent =>
      'Please enter your birth year to access the parent area.';

  @override
  String get paywallTitle => 'You have reached today\'s limit';

  @override
  String get paywallBody =>
      'Free accounts can study up to 50 lessons per day. Upgrade for unlimited access.';

  @override
  String get paywallGotIt => 'Got it';

  @override
  String get paywallClose => 'Close';

  @override
  String get profileStatLessons => 'Lessons';

  @override
  String get profileStatStars => 'Stars';

  @override
  String get profileStatStreak => 'Streak';

  @override
  String get achievementsTitle => 'Achievements';

  @override
  String get achievementsEmpty =>
      'No achievements yet — complete a lesson to start earning!';

  @override
  String get achievementsNewBadge => 'New';

  @override
  String get leaderboardTitle => 'Leaderboard';

  @override
  String get leaderboardEmpty => 'No leaderboard data — join a classroom!';

  @override
  String get leaderboardJoinCodeLabel => 'Classroom code';

  @override
  String get leaderboardJoinCodeHint => 'Enter 6-character code';

  @override
  String get leaderboardJoinButton => 'Join';

  @override
  String get leaderboardLeaveButton => 'Leave';

  @override
  String leaderboardWeeklyStars(Object count) {
    return '$count ⭐ this week';
  }

  @override
  String leaderboardRank(Object rank) {
    return '#$rank';
  }

  @override
  String get offlineBanner => 'You are offline. Changes will sync later.';

  @override
  String get contactLabel => 'Contact';

  @override
  String get pricingHeaderTitle => 'HocVui Pricing';

  @override
  String get pricingHeaderSubtitle =>
      'Learn joyfully every day — free or upgrade to Premium';

  @override
  String get pricingCurrentBadge => 'Current plan';

  @override
  String get pricingPopularBadge => 'Popular';

  @override
  String pricingYearlySubtitle(String yearlyPrice) {
    return 'or $yearlyPrice/year (save 17%)';
  }

  @override
  String get pricingCtaUpgrade => 'Upgrade now 🚀';

  @override
  String get pricingCtaGetStarted => 'Get started';

  @override
  String get pricingCtaStartFree => 'Start free';

  @override
  String get pricingCtaSave => 'Save 17%';

  @override
  String get pricingCtaUpgradeShort => 'Upgrade now';

  @override
  String get pricingCompareTitle => 'Detailed comparison';

  @override
  String get pricingCompareFeatureCol => 'Feature';

  @override
  String get pricingCompareFreeCol => 'Free';

  @override
  String get pricingComparePremiumCol => 'Premium';

  @override
  String pricingFooterNote(String email) {
    return 'Online payment is not yet integrated. Need Premium? Email $email — admin activates within 24h.';
  }

  @override
  String get pricingFooterBrand => 'HocVui • Learn joyfully every day';

  @override
  String pricingEmailSubject(String tier) {
    return 'Upgrade HocVui $tier';
  }

  @override
  String get pricingBannerTitle => 'You\'ve hit today\'s lesson limit!';

  @override
  String get pricingBannerBody =>
      'Upgrade to Premium for unlimited lessons every day.';

  @override
  String get pricingBannerCta => 'View pricing';

  @override
  String get pricingBannerRemindLater => 'Remind me later';

  @override
  String get pricingHeroTitle => 'Pricing';

  @override
  String get pricingHeroSubtitle => 'Free to start. Upgrade when you need more.';

  @override
  String get pricingYearlySaveLine => 'Save 17% vs monthly';

  @override
  String get pricingRefundLine => 'Cancel anytime. 7-day refund.';

  @override
  String get pricingNoteLabel => 'Note: ';

  @override
  String pricingNoteBody(String email) =>
      'Online payment is not yet integrated. Upgrade to Premium via: $email';

  @override
  String get pricingBackTooltip => 'Back';

  @override
  String get pricingBrandShort => 'HocVui';
}
