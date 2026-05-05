// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class AppLocalizationsVi extends AppLocalizations {
  AppLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appTitle => 'Học Toán Vui';

  @override
  String get welcomeGreeting => 'Xin chào, bé yêu!';

  @override
  String get welcomeTitle => 'Bắt đầu học!';

  @override
  String get welcomeParentAccess => 'Bố mẹ nhấn vào đây';

  @override
  String get welcomeSubtitle =>
      'Hãy cùng học Toán vui nhé! Chọn cách học của bé.';

  @override
  String get welcomeLanguageVi => 'Tiếng Việt';

  @override
  String get welcomeGoogleSignIn => 'Đăng nhập bằng Google';

  @override
  String get welcomeSelectPersona => 'Chọn nhân vật';

  @override
  String get welcomeBackButton => 'Quay lại';

  @override
  String assessmentProgress(int current, int total) {
    return 'Câu hỏi $current/$total';
  }

  @override
  String get assessmentQuestion1 => 'Bé đã đếm được đến số mấy rồi?';

  @override
  String get assessmentQuestion2 => 'Bé đã biết cộng trừ chưa?';

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
  String get homeContinueAchieverTopic => 'Phép cộng 1 – 10';

  @override
  String get homeContinueGamerLabel => 'Kiếm thêm 50 điểm!';

  @override
  String get homeContinueGamerTopic => 'Đếm vui – Cấp độ 2';

  @override
  String get homeContinueStrugglerLabel => 'Hôm nay mình học gì?';

  @override
  String get homeContinueStrugglerTopic => 'Nhận biết số 1 – 5';

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
  String get celebrationGamerUnlock => 'Mở khóa: Phép cộng cấp độ 2!';

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
  String get parentDashboardSubjectNumbers => 'Số học';

  @override
  String get parentDashboardSubjectGeometry => 'Hình học';

  @override
  String get parentDashboardSubjectMeasurement => 'Đo lường';

  @override
  String get parentDashboardSubjectLogic => 'Tư duy';

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
  String get logout => 'Đăng xuất';

  @override
  String get guestUser => 'Khách';

  @override
  String get comingSoon => 'Sắp ra mắt';
}
