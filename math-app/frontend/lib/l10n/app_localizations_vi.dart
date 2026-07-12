// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Học Vui';

  @override
  String get welcomeGreeting => 'Xin chào, bé yêu!';

  @override
  String get welcomeTitle => 'Bắt đầu học!';

  @override
  String get welcomeParentAccess => 'Bố mẹ nhấn vào đây';

  @override
  String get welcomeSubtitle => 'Cùng nhau học vui mỗi ngày nhé!';

  @override
  String get welcomeLanguageVi => 'Tiếng Việt';

  @override
  String get welcomeGoogleSignIn => 'Đăng nhập bằng Google';

  @override
  String get welcomeSelectPersona => 'Bé là ai nè?';

  @override
  String get welcomePersonaSubtitle => 'Chọn bạn đồng hành của mình nhé!';

  @override
  String get welcomeStartButton => 'Bắt đầu học thôi! 🚀';

  @override
  String get welcomeGuestButton => 'Học thử không cần tài khoản';

  @override
  String get welcomeOrDivider => 'hoặc';

  @override
  String get welcomeBackButton => 'Quay lại';

  @override
  String assessmentProgress(int current, int total) {
    return 'Câu hỏi $current/$total';
  }

  @override
  String get assessmentQuestion1 => 'Bé đã đếm và đọc được đến đâu rồi?';

  @override
  String get assessmentQuestion2 => 'Bé đã biết chữ cái và số chưa?';

  @override
  String get assessmentQuestion3 => 'Bé học nhanh hay chậm?';

  @override
  String get assessmentQuestion4 => 'Bé thích điều gì nhất?';

  @override
  String assessmentSkip(int count) {
    return 'Bỏ qua: đã trả lời $count/4';
  }

  @override
  String get assessmentHint => 'Không biết? Chọn câu gần đúng nhất nhé!';

  @override
  String get homeSubjects => 'Các chủ đề';

  @override
  String get homeNavSubjects => 'Chủ đề';

  @override
  String get homeNavPricing => 'Bảng giá';

  @override
  String get homeNavContact => 'Liên hệ';

  @override
  String get homeLessonsLearned => 'Bài đã học';

  @override
  String get homeStarsEarned => 'Sao tích lũy';

  @override
  String homeDayStreak(int streak) {
    return '$streak ngày liên tiếp';
  }

  @override
  String get homeContinueAchieverLabel => 'Tiếp tục giành 3 sao!';

  @override
  String get homeContinueAchieverTopic => 'Cộng trừ & Đọc chữ';

  @override
  String get homeContinueGamerLabel => 'Kiếm thêm 50 điểm!';

  @override
  String get homeContinueGamerTopic => 'Học vui – Cấp độ 2';

  @override
  String get homeContinueStrugglerLabel => 'Hôm nay mình học gì?';

  @override
  String get homeContinueStrugglerTopic => 'Chữ cái & Số';

  @override
  String get homeContinueSilentLabel => 'Bé sẵn sàng chưa?';

  @override
  String get homeContinueSilentTopic => 'Bắt đầu nhé';

  @override
  String get homeDefaultName => 'bé yêu';

  @override
  String get lessonNotFound => 'Không tìm thấy bài học';

  @override
  String get lessonClose => 'Đóng';

  @override
  String get lessonHintPrefix => 'Gợi ý';

  @override
  String get lessonCorrectFeedback => 'Chính xác!';

  @override
  String get lessonIncorrectFeedback => 'Thử lại nhé!';

  @override
  String get lessonSpeakQuestion => 'Đọc câu hỏi';

  @override
  String get celebrationTitle => 'Tuyệt vời!';

  @override
  String celebrationStars(int stars) {
    return 'Bé đã giành được $stars sao!';
  }

  @override
  String get celebrationNext => 'Học tiếp';

  @override
  String get celebrationHome => 'Về nhà';

  @override
  String get celebrationAchieverTitle => 'Chính xác!';

  @override
  String get celebrationAchieverSubtitle => 'Bé giỏi quá! Tiếp tục nào!';

  @override
  String get celebrationGamerTitle => 'Chiến thắng!';

  @override
  String get celebrationGamerSubtitle => 'Bé nhận được +15 điểm!';

  @override
  String get celebrationGamerUnlock => 'Mở khóa: Cấp độ học tiếp theo!';

  @override
  String get celebrationStrugglerTitle => 'Bé làm rất cố gắng!';

  @override
  String get celebrationStrugglerSubtitle =>
      'Đừng bỏ cuộc, mình làm tiếp bài khác nhé!';

  @override
  String get celebrationSilentTitle => 'Làm tốt lắm!';

  @override
  String get celebrationSilentSubtitle => 'Bé đã học được thứ mới rồi!';

  @override
  String get pinGateTitle => 'Khu vực cha mẹ';

  @override
  String get pinGateEnterPin => 'Nhập mã PIN để vào khu vực cha mẹ';

  @override
  String get pinGateBack => 'Quay lại';

  @override
  String get pinGateWrongPin => 'Sai mã PIN!';

  @override
  String get parentDashboardTitle => 'Khu vực cha mẹ';

  @override
  String get parentDashboardBackToHome => 'Về trang chủ';

  @override
  String get parentDashboardLessonsLearned => 'Bài đã học';

  @override
  String get parentDashboardStarsEarned => 'Sao tích lũy';

  @override
  String get parentDashboardStudyStreak => 'Liên tiếp học';

  @override
  String get parentDashboardProgress => 'Tiến độ học tập';

  @override
  String get parentDashboardSubjectMath => 'Toán học';

  @override
  String get parentDashboardSubjectNumbers => 'Số học';

  @override
  String get parentDashboardSubjectGeometry => 'Hình học';

  @override
  String get parentDashboardSubjectMeasurement => 'Đo lường';

  @override
  String get parentDashboardSubjectLogic => 'Tư duy';

  @override
  String get parentDashboardSubjectVietnamese => 'Tiếng Việt';

  @override
  String get parentDashboardSubjectEnglish => 'Tiếng Anh';

  @override
  String get parentDashboardSettings => 'Cài đặt';

  @override
  String get parentDashboardLanguage => 'Ngôn ngữ';

  @override
  String get parentDashboardLanguageValue => 'Tiếng Việt';

  @override
  String get parentDashboardStudyTime => 'Thời gian học';

  @override
  String get parentDashboardStudyTimeValue => '15 phút/ngày';

  @override
  String get parentDashboardNotifications => 'Thông báo';

  @override
  String get parentDashboardLogout => 'Đăng xuất';

  @override
  String get languageSwitcherLabel => 'Ngôn ngữ';

  @override
  String get profileTitle => 'Hồ sơ';

  @override
  String get profile => 'Hồ sơ';

  @override
  String get settings => 'Cài đặt';

  @override
  String get settingsTtsTitle => 'Đọc câu hỏi';

  @override
  String get settingsTtsSubtitle => 'Tự động đọc câu hỏi khi học';

  @override
  String get reviewScreenTitle => 'Ôn tập lỗi';

  @override
  String get reviewCardLabel => 'Ôn tập lỗi';

  @override
  String get reviewCardTopic => 'Sửa những câu đã làm sai';

  @override
  String get reviewAllClear => 'Bé đã làm đúng hết rồi! 🎉';

  @override
  String reviewWrongCount(Object count) {
    return 'Đã sai $count lần';
  }

  @override
  String get logout => 'Đăng xuất';

  @override
  String get guestUser => 'Khách';

  @override
  String get comingSoon => 'Sắp ra mắt';

  @override
  String get loginWelcomeTitle => 'Chào mừng bạn!';

  @override
  String get loginWelcomeSubtitle => 'Hãy chọn cách để bắt đầu học nhé';

  @override
  String get loginGoogleSignIn => 'Đăng nhập với Google';

  @override
  String get loginGuestSignIn => 'Tiếp tục không đăng nhập';

  @override
  String get loginOrDivider => 'hoặc';

  @override
  String get loginParentAccess => 'Dành cho phụ huynh';

  @override
  String get loginParentDialogTitle => 'Dành cho phụ huynh';

  @override
  String get loginParentDialogContent =>
      'Vui lòng nhập năm sinh để truy cập khu vực phụ huynh.';

  @override
  String get paywallTitle => 'Bạn đã học đủ bài hôm nay';

  @override
  String get paywallBody =>
      'Tài khoản miễn phí được học tối đa 50 bài mỗi ngày. Nâng cấp để học không giới hạn.';

  @override
  String get paywallGotIt => 'Đã hiểu';

  @override
  String get paywallClose => 'Đóng';

  @override
  String get profileStatLessons => 'Bài học';

  @override
  String get profileStatStars => 'Sao';

  @override
  String get profileStatStreak => 'Streak';

  @override
  String get achievementsTitle => 'Huy chương';

  @override
  String get achievementsEmpty =>
      'Chưa có huy chương nào — hoàn thành một bài học để bắt đầu!';

  @override
  String get achievementsNewBadge => 'Mới';

  @override
  String get leaderboardTitle => 'Bảng xếp hạng';

  @override
  String get leaderboardEmpty =>
      'Chưa có dữ liệu bảng xếp hạng — tham gia lớp học!';

  @override
  String get leaderboardJoinCodeLabel => 'Mã lớp học';

  @override
  String get leaderboardJoinCodeHint => 'Nhập mã 6 ký tự';

  @override
  String get leaderboardJoinButton => 'Tham gia';

  @override
  String get leaderboardLeaveButton => 'Rời lớp';

  @override
  String leaderboardWeeklyStars(Object count) {
    return '$count ⭐ tuần này';
  }

  @override
  String leaderboardRank(Object rank) {
    return 'Hạng $rank';
  }

  @override
  String get offlineBanner =>
      'Bạn đang ngoại tuyến. Dữ liệu sẽ được đồng bộ sau.';

  @override
  String get contactLabel => 'Liên hệ';

  @override
  String get pricingHeaderTitle => 'Bảng giá HocVui';

  @override
  String get pricingHeaderSubtitle =>
      'Học vui mỗi ngày, miễn phí hoặc nâng cấp Premium';

  @override
  String get pricingCurrentBadge => 'Đang dùng';

  @override
  String get pricingPopularBadge => 'Phổ biến';

  @override
  String pricingYearlySubtitle(String yearlyPrice) {
    return 'hoặc $yearlyPrice/năm (tiết kiệm 17%)';
  }

  @override
  String get pricingCtaUpgrade => 'Nâng cấp ngay 🚀';

  @override
  String get pricingCtaGetStarted => 'Bắt đầu';

  @override
  String get pricingCtaStartFree => 'Bắt đầu miễn phí';

  @override
  String get pricingCtaSave => 'Tiết kiệm ngay';

  @override
  String get pricingCtaUpgradeShort => 'Nâng cấp ngay';

  @override
  String get pricingCompareTitle => 'So sánh chi tiết';

  @override
  String get pricingCompareFeatureCol => 'Tính năng';

  @override
  String get pricingCompareFreeCol => 'Free';

  @override
  String get pricingComparePremiumCol => 'Premium';

  @override
  String pricingFooterNote(String email) {
    return 'Thanh toán online chưa tích hợp. Bé đang dùng gói Premium? Liên hệ $email — admin sẽ kích hoạt trong 24h.';
  }

  @override
  String get pricingFooterBrand => 'HocVui • Học vui mỗi ngày';

  @override
  String pricingEmailSubject(String tier) {
    return 'Nâng cấp HocVui $tier';
  }

  @override
  String get pricingBannerTitle => 'Bạn đã học hôm nay rồi!';

  @override
  String get pricingBannerBody =>
      'Nâng cấp Premium để học không giới hạn mỗi ngày.';

  @override
  String get pricingBannerCta => 'Xem gói học';

  @override
  String get pricingBannerRemindLater => 'Nhắc tôi sau';

  @override
  String get pricingHeroTitle => 'Gói học';

  @override
  String get pricingHeroSubtitle => 'Bắt đầu miễn phí. Nâng cấp khi cần.';

  @override
  String get pricingYearlySaveLine => 'Tiết kiệm 17% so với trả theo tháng';

  @override
  String get pricingRefundLine => 'Huỷ bất cứ lúc nào. Hoàn tiền trong 7 ngày.';

  @override
  String get pricingNoteLabel => 'Lưu ý: ';

  @override
  String pricingNoteBody(String email) =>
      'Hiện tại thanh toán chưa tích hợp online. Nâng cấp Premium qua liên hệ: $email';

  @override
  String get pricingBackTooltip => 'Quay lại';

  @override
  String get pricingBrandShort => 'HocVui';
}
