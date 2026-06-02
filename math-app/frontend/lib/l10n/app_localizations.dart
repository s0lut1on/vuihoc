import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi')
  ];

  /// No description provided for @appTitle.
  ///
  /// In vi, this message translates to:
  /// **'Học Toán Vui'**
  String get appTitle;

  /// No description provided for @welcomeGreeting.
  ///
  /// In vi, this message translates to:
  /// **'Xin chào, bé yêu!'**
  String get welcomeGreeting;

  /// No description provided for @welcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu học!'**
  String get welcomeTitle;

  /// No description provided for @welcomeParentAccess.
  ///
  /// In vi, this message translates to:
  /// **'Bố mẹ nhấn vào đây'**
  String get welcomeParentAccess;

  /// No description provided for @welcomeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hãy cùng học Toán vui nhé! Chọn cách học của bé.'**
  String get welcomeSubtitle;

  /// No description provided for @welcomeLanguageVi.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get welcomeLanguageVi;

  /// No description provided for @welcomeGoogleSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập bằng Google'**
  String get welcomeGoogleSignIn;

  /// No description provided for @welcomeSelectPersona.
  ///
  /// In vi, this message translates to:
  /// **'Chọn nhân vật'**
  String get welcomeSelectPersona;

  /// No description provided for @welcomeBackButton.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get welcomeBackButton;

  /// No description provided for @assessmentProgress.
  ///
  /// In vi, this message translates to:
  /// **'Câu hỏi {current}/{total}'**
  String assessmentProgress(int current, int total);

  /// No description provided for @assessmentQuestion1.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã đếm được đến số mấy rồi?'**
  String get assessmentQuestion1;

  /// No description provided for @assessmentQuestion2.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã biết cộng trừ chưa?'**
  String get assessmentQuestion2;

  /// No description provided for @assessmentQuestion3.
  ///
  /// In vi, this message translates to:
  /// **'Bé học nhanh hay chậm?'**
  String get assessmentQuestion3;

  /// No description provided for @assessmentQuestion4.
  ///
  /// In vi, this message translates to:
  /// **'Bé thích điều gì nhất?'**
  String get assessmentQuestion4;

  /// No description provided for @assessmentSkip.
  ///
  /// In vi, this message translates to:
  /// **'Bỏ qua: đã trả lời {count}/4'**
  String assessmentSkip(int count);

  /// No description provided for @assessmentHint.
  ///
  /// In vi, this message translates to:
  /// **'Không biết? Chọn câu gần đúng nhất nhé!'**
  String get assessmentHint;

  /// No description provided for @homeSubjects.
  ///
  /// In vi, this message translates to:
  /// **'Các chủ đề'**
  String get homeSubjects;

  /// No description provided for @homeNavSubjects.
  ///
  /// In vi, this message translates to:
  /// **'Chủ đề'**
  String get homeNavSubjects;

  /// No description provided for @homeNavPricing.
  ///
  /// In vi, this message translates to:
  /// **'Bảng giá'**
  String get homeNavPricing;

  /// No description provided for @homeNavContact.
  ///
  /// In vi, this message translates to:
  /// **'Liên hệ'**
  String get homeNavContact;

  /// No description provided for @homeLessonsLearned.
  ///
  /// In vi, this message translates to:
  /// **'Bài đã học'**
  String get homeLessonsLearned;

  /// No description provided for @homeStarsEarned.
  ///
  /// In vi, this message translates to:
  /// **'Sao tích lũy'**
  String get homeStarsEarned;

  /// No description provided for @homeDayStreak.
  ///
  /// In vi, this message translates to:
  /// **'{streak} ngày liên tiếp'**
  String homeDayStreak(int streak);

  /// No description provided for @homeContinueAchieverLabel.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục giành 3 sao!'**
  String get homeContinueAchieverLabel;

  /// No description provided for @homeContinueAchieverTopic.
  ///
  /// In vi, this message translates to:
  /// **'Phép cộng 1 – 10'**
  String get homeContinueAchieverTopic;

  /// No description provided for @homeContinueGamerLabel.
  ///
  /// In vi, this message translates to:
  /// **'Kiếm thêm 50 điểm!'**
  String get homeContinueGamerLabel;

  /// No description provided for @homeContinueGamerTopic.
  ///
  /// In vi, this message translates to:
  /// **'Đếm vui – Cấp độ 2'**
  String get homeContinueGamerTopic;

  /// No description provided for @homeContinueStrugglerLabel.
  ///
  /// In vi, this message translates to:
  /// **'Hôm nay mình học gì?'**
  String get homeContinueStrugglerLabel;

  /// No description provided for @homeContinueStrugglerTopic.
  ///
  /// In vi, this message translates to:
  /// **'Nhận biết số 1 – 5'**
  String get homeContinueStrugglerTopic;

  /// No description provided for @homeContinueSilentLabel.
  ///
  /// In vi, this message translates to:
  /// **'Bé sẵn sàng chưa?'**
  String get homeContinueSilentLabel;

  /// No description provided for @homeContinueSilentTopic.
  ///
  /// In vi, this message translates to:
  /// **'Bắt đầu nhé'**
  String get homeContinueSilentTopic;

  /// No description provided for @homeDefaultName.
  ///
  /// In vi, this message translates to:
  /// **'bé yêu'**
  String get homeDefaultName;

  /// No description provided for @lessonNotFound.
  ///
  /// In vi, this message translates to:
  /// **'Không tìm thấy bài học'**
  String get lessonNotFound;

  /// No description provided for @lessonClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get lessonClose;

  /// No description provided for @lessonHintPrefix.
  ///
  /// In vi, this message translates to:
  /// **'Gợi ý'**
  String get lessonHintPrefix;

  /// No description provided for @lessonCorrectFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Chính xác!'**
  String get lessonCorrectFeedback;

  /// No description provided for @lessonIncorrectFeedback.
  ///
  /// In vi, this message translates to:
  /// **'Thử lại nhé!'**
  String get lessonIncorrectFeedback;

  /// No description provided for @lessonSpeakQuestion.
  ///
  /// In vi, this message translates to:
  /// **'Đọc câu hỏi'**
  String get lessonSpeakQuestion;

  /// No description provided for @celebrationTitle.
  ///
  /// In vi, this message translates to:
  /// **'Tuyệt vời!'**
  String get celebrationTitle;

  /// No description provided for @celebrationStars.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã giành được {stars} sao!'**
  String celebrationStars(int stars);

  /// No description provided for @celebrationNext.
  ///
  /// In vi, this message translates to:
  /// **'Học tiếp'**
  String get celebrationNext;

  /// No description provided for @celebrationHome.
  ///
  /// In vi, this message translates to:
  /// **'Về nhà'**
  String get celebrationHome;

  /// No description provided for @celebrationAchieverTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chính xác!'**
  String get celebrationAchieverTitle;

  /// No description provided for @celebrationAchieverSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bé giỏi quá! Tiếp tục nào!'**
  String get celebrationAchieverSubtitle;

  /// No description provided for @celebrationGamerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chiến thắng!'**
  String get celebrationGamerTitle;

  /// No description provided for @celebrationGamerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bé nhận được +15 điểm!'**
  String get celebrationGamerSubtitle;

  /// No description provided for @celebrationGamerUnlock.
  ///
  /// In vi, this message translates to:
  /// **'Mở khóa: Phép cộng cấp độ 2!'**
  String get celebrationGamerUnlock;

  /// No description provided for @celebrationStrugglerTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bé làm rất cố gắng!'**
  String get celebrationStrugglerTitle;

  /// No description provided for @celebrationStrugglerSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Đừng bỏ cuộc, mình làm tiếp bài khác nhé!'**
  String get celebrationStrugglerSubtitle;

  /// No description provided for @celebrationSilentTitle.
  ///
  /// In vi, this message translates to:
  /// **'Làm tốt lắm!'**
  String get celebrationSilentTitle;

  /// No description provided for @celebrationSilentSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã học được thứ mới rồi!'**
  String get celebrationSilentSubtitle;

  /// No description provided for @pinGateTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực cha mẹ'**
  String get pinGateTitle;

  /// No description provided for @pinGateEnterPin.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã PIN để vào khu vực cha mẹ'**
  String get pinGateEnterPin;

  /// No description provided for @pinGateBack.
  ///
  /// In vi, this message translates to:
  /// **'Quay lại'**
  String get pinGateBack;

  /// No description provided for @pinGateWrongPin.
  ///
  /// In vi, this message translates to:
  /// **'Sai mã PIN!'**
  String get pinGateWrongPin;

  /// No description provided for @parentDashboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Khu vực cha mẹ'**
  String get parentDashboardTitle;

  /// No description provided for @parentDashboardBackToHome.
  ///
  /// In vi, this message translates to:
  /// **'Về trang chủ'**
  String get parentDashboardBackToHome;

  /// No description provided for @parentDashboardLessonsLearned.
  ///
  /// In vi, this message translates to:
  /// **'Bài đã học'**
  String get parentDashboardLessonsLearned;

  /// No description provided for @parentDashboardStarsEarned.
  ///
  /// In vi, this message translates to:
  /// **'Sao tích lũy'**
  String get parentDashboardStarsEarned;

  /// No description provided for @parentDashboardStudyStreak.
  ///
  /// In vi, this message translates to:
  /// **'Liên tiếp học'**
  String get parentDashboardStudyStreak;

  /// No description provided for @parentDashboardProgress.
  ///
  /// In vi, this message translates to:
  /// **'Tiến độ học tập'**
  String get parentDashboardProgress;

  /// No description provided for @parentDashboardSubjectNumbers.
  ///
  /// In vi, this message translates to:
  /// **'Số học'**
  String get parentDashboardSubjectNumbers;

  /// No description provided for @parentDashboardSubjectGeometry.
  ///
  /// In vi, this message translates to:
  /// **'Hình học'**
  String get parentDashboardSubjectGeometry;

  /// No description provided for @parentDashboardSubjectMeasurement.
  ///
  /// In vi, this message translates to:
  /// **'Đo lường'**
  String get parentDashboardSubjectMeasurement;

  /// No description provided for @parentDashboardSubjectLogic.
  ///
  /// In vi, this message translates to:
  /// **'Tư duy'**
  String get parentDashboardSubjectLogic;

  /// No description provided for @parentDashboardSettings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get parentDashboardSettings;

  /// No description provided for @parentDashboardLanguage.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get parentDashboardLanguage;

  /// No description provided for @parentDashboardLanguageValue.
  ///
  /// In vi, this message translates to:
  /// **'Tiếng Việt'**
  String get parentDashboardLanguageValue;

  /// No description provided for @parentDashboardStudyTime.
  ///
  /// In vi, this message translates to:
  /// **'Thời gian học'**
  String get parentDashboardStudyTime;

  /// No description provided for @parentDashboardStudyTimeValue.
  ///
  /// In vi, this message translates to:
  /// **'15 phút/ngày'**
  String get parentDashboardStudyTimeValue;

  /// No description provided for @parentDashboardNotifications.
  ///
  /// In vi, this message translates to:
  /// **'Thông báo'**
  String get parentDashboardNotifications;

  /// No description provided for @parentDashboardLogout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get parentDashboardLogout;

  /// No description provided for @languageSwitcherLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ngôn ngữ'**
  String get languageSwitcherLabel;

  /// No description provided for @profileTitle.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profileTitle;

  /// No description provided for @profile.
  ///
  /// In vi, this message translates to:
  /// **'Hồ sơ'**
  String get profile;

  /// No description provided for @settings.
  ///
  /// In vi, this message translates to:
  /// **'Cài đặt'**
  String get settings;

  /// No description provided for @settingsTtsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Đọc câu hỏi'**
  String get settingsTtsTitle;

  /// No description provided for @settingsTtsSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Tự động đọc câu hỏi khi học'**
  String get settingsTtsSubtitle;

  /// No description provided for @reviewScreenTitle.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập lỗi'**
  String get reviewScreenTitle;

  /// No description provided for @reviewCardLabel.
  ///
  /// In vi, this message translates to:
  /// **'Ôn tập lỗi'**
  String get reviewCardLabel;

  /// No description provided for @reviewCardTopic.
  ///
  /// In vi, this message translates to:
  /// **'Sửa những câu đã làm sai'**
  String get reviewCardTopic;

  /// No description provided for @reviewAllClear.
  ///
  /// In vi, this message translates to:
  /// **'Bé đã làm đúng hết rồi! 🎉'**
  String get reviewAllClear;

  /// No description provided for @reviewWrongCount.
  ///
  /// In vi, this message translates to:
  /// **'Đã sai {count} lần'**
  String reviewWrongCount(Object count);

  /// No description provided for @logout.
  ///
  /// In vi, this message translates to:
  /// **'Đăng xuất'**
  String get logout;

  /// No description provided for @guestUser.
  ///
  /// In vi, this message translates to:
  /// **'Khách'**
  String get guestUser;

  /// No description provided for @comingSoon.
  ///
  /// In vi, this message translates to:
  /// **'Sắp ra mắt'**
  String get comingSoon;

  /// No description provided for @loginWelcomeTitle.
  ///
  /// In vi, this message translates to:
  /// **'Chào mừng bạn!'**
  String get loginWelcomeTitle;

  /// No description provided for @loginWelcomeSubtitle.
  ///
  /// In vi, this message translates to:
  /// **'Hãy chọn cách để bắt đầu học toán nhé'**
  String get loginWelcomeSubtitle;

  /// No description provided for @loginGoogleSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Đăng nhập với Google'**
  String get loginGoogleSignIn;

  /// No description provided for @loginGuestSignIn.
  ///
  /// In vi, this message translates to:
  /// **'Tiếp tục không đăng nhập'**
  String get loginGuestSignIn;

  /// No description provided for @loginOrDivider.
  ///
  /// In vi, this message translates to:
  /// **'hoặc'**
  String get loginOrDivider;

  /// No description provided for @loginParentAccess.
  ///
  /// In vi, this message translates to:
  /// **'Dành cho phụ huynh'**
  String get loginParentAccess;

  /// No description provided for @loginParentDialogTitle.
  ///
  /// In vi, this message translates to:
  /// **'Dành cho phụ huynh'**
  String get loginParentDialogTitle;

  /// No description provided for @loginParentDialogContent.
  ///
  /// In vi, this message translates to:
  /// **'Vui lòng nhập năm sinh để truy cập khu vực phụ huynh.'**
  String get loginParentDialogContent;

  /// No description provided for @paywallTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bạn đã học đủ bài hôm nay'**
  String get paywallTitle;

  /// No description provided for @paywallBody.
  ///
  /// In vi, this message translates to:
  /// **'Tài khoản miễn phí được học tối đa 50 bài mỗi ngày. Nâng cấp để học không giới hạn.'**
  String get paywallBody;

  /// No description provided for @paywallGotIt.
  ///
  /// In vi, this message translates to:
  /// **'Đã hiểu'**
  String get paywallGotIt;

  /// No description provided for @paywallClose.
  ///
  /// In vi, this message translates to:
  /// **'Đóng'**
  String get paywallClose;

  /// No description provided for @profileStatLessons.
  ///
  /// In vi, this message translates to:
  /// **'Bài học'**
  String get profileStatLessons;

  /// No description provided for @profileStatStars.
  ///
  /// In vi, this message translates to:
  /// **'Sao'**
  String get profileStatStars;

  /// No description provided for @profileStatStreak.
  ///
  /// In vi, this message translates to:
  /// **'Streak'**
  String get profileStatStreak;

  /// No description provided for @achievementsTitle.
  ///
  /// In vi, this message translates to:
  /// **'Huy chương'**
  String get achievementsTitle;

  /// No description provided for @achievementsEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có huy chương nào — hoàn thành một bài học để bắt đầu!'**
  String get achievementsEmpty;

  /// No description provided for @achievementsNewBadge.
  ///
  /// In vi, this message translates to:
  /// **'Mới'**
  String get achievementsNewBadge;

  /// No description provided for @leaderboardTitle.
  ///
  /// In vi, this message translates to:
  /// **'Bảng xếp hạng'**
  String get leaderboardTitle;

  /// No description provided for @leaderboardEmpty.
  ///
  /// In vi, this message translates to:
  /// **'Chưa có dữ liệu bảng xếp hạng — tham gia lớp học!'**
  String get leaderboardEmpty;

  /// No description provided for @leaderboardJoinCodeLabel.
  ///
  /// In vi, this message translates to:
  /// **'Mã lớp học'**
  String get leaderboardJoinCodeLabel;

  /// No description provided for @leaderboardJoinCodeHint.
  ///
  /// In vi, this message translates to:
  /// **'Nhập mã 6 ký tự'**
  String get leaderboardJoinCodeHint;

  /// No description provided for @leaderboardJoinButton.
  ///
  /// In vi, this message translates to:
  /// **'Tham gia'**
  String get leaderboardJoinButton;

  /// No description provided for @leaderboardLeaveButton.
  ///
  /// In vi, this message translates to:
  /// **'Rời lớp'**
  String get leaderboardLeaveButton;

  /// No description provided for @leaderboardWeeklyStars.
  ///
  /// In vi, this message translates to:
  /// **'{count} ⭐ tuần này'**
  String leaderboardWeeklyStars(Object count);

  /// No description provided for @leaderboardRank.
  ///
  /// In vi, this message translates to:
  /// **'Hạng {rank}'**
  String leaderboardRank(Object rank);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'vi':
      return AppLocalizationsVi();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
