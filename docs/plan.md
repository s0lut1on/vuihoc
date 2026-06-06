# Kế hoạch phát triển Ứng dụng Học Toán cho Trẻ 6 tuổi

## 1. Tổng quan Dự án

### 1.1. Mục tiêu
Xây dựng ứng dụng học Toán đa nền tảng (Web, Android, mở rộng iOS sau) dành cho trẻ 6 tuổi (mẫu giáo lớn / lớp 1), với tiếng Việt là ngôn ngữ chính, tiếng Anh là ngôn ngữ thứ hai, có khả năng mở rộng đa ngôn ngữ trong tương lai.

### 1.2. Đối tượng người dùng
- **Người dùng chính:** Trẻ em 5-7 tuổi (tập trung 6 tuổi)
- **Người dùng phụ:** Phụ huynh, giáo viên mầm non/tiểu học

### 1.3. Nền tảng mục tiêu
| Nền tảng | Ưu tiên | Ghi chú |
|----------|---------|---------|
| Web (PWA) | Cao | Truy cập đa thiết bị, không cần cài đặt |
| Android | Cao | Thị phần lớn tại VN, thiết bị đa dạng |
| iOS | Trung bình | Mở rộng sau khi ổn định trên Android/Web |
| Tablet (iPad/Android) | Cao | Trải nghiệm tốt nhất cho trẻ em |

## 2. Phân tích Đối thủ Cạnh tranh

### 2.1. Thị trường Toàn cầu

| Ứng dụng | Độ tuổi | Mô hình | Điểm mạnh | Điểm yếu |
|----------|---------|---------|-----------|----------|
| **Khan Academy Kids** | 2-8 | Miễn phí | Miễn phí 100%, không quảng cáo, 4000+ hoạt động, chuẩn curriculum | Chủ yếu tiếng Anh, ít tùy biến cho thị trường VN |
| **Prodigy Math** | 6-14 | Freemium | Gamification RPG mạnh, 50,000+ câu hỏi, cộng đồng lớn | Phụ thuộc vào internet, nội dung phù hợp lớn hơn 6 tuổi |
| **SplashLearn** | 3-10 | $11.99/tháng | Adaptive learning, 8,000+ trò chơi, báo cáo tiến bộ chi tiết | Chi phí cao, thiết kế ít đa dạng văn hóa |
| **Funexpected Math** | 3-7 | $10.99/tháng | UI/UX đẹp, 10,000+ bài tập, digital tutor, logic puzzles | Giá cao, không có phiên bản tiếng Việt |
| **DragonBox** | 4-8 | $5.99/tháng | Phương pháp Montessori trực quan, học qua khám phá | Phạm vi hẹp (số học cơ bản), ít nội dung lặp lại |
| **Elephant Learning** | 2-8 | $99/năm | Cam kết tiến bộ (1 năm toán trong 3 tháng), thuật toán adapt | Giá cao, không curriculum-aligned, không đa ngôn ngữ |
| **IXL** | K-12 | Subscription | Toàn diện, theo chuẩn Common Core, báo cáo sâu | Quá nghiêm túc, ít gamification cho lứa tuổi 6 |
| **Moose Math** | 2-8 | Miễn phí | Hoàn toàn miễn phí, đơn giản, dễ tiếp cận | Nội dung hạn chế, ít tính năng nâng cao |

### 2.2. Thị trường Việt Nam

| Ứng dụng | Nhà phát triển | Mô hình | Điểm mạnh | Điểm yếu |
|----------|----------------|---------|-----------|----------|
| **Monkey Math** | Early Start (15M+ users) | Subscription | #1 VN, theo chương trình GDPT mới Bộ GD&ĐT, 10,000+ hoạt động, 60+ chủ đề, học qua tiếng Anh, 4 cấp độ | Học bằng tiếng Anh (rào cản một số phụ huynh), giá cao cho nhiều gia đình |
| **HelloMath (Vuihoc)** | VH Edtech | Freemium | Tiếng Việt 100%, 5000+ câu đố, video animation, offline mode | Mới hơn, ít thương hiệu so với Monkey, UI chưa bóng bẩy |
| **KidsUP Soroban** | KidsUP | Subscription | AI-powered, phương pháp Soroban Nhật Bản, tính nhẩm nhanh | Tập trung tính nhẩm, không đa dạng chủ đề toán |
| **vnEdu Tú Tài** | VNPT | Subscription | Adaptive learning, 90,000+ câu hỏi, thương hiệu VNPT mạnh | Tập trung học sinh lớn hơn (1-12), ít gamification |
| **VMonkey** | Early Start | Subscription | Hệ sinh thái Early Start, tiếng Việt, 750+ truyện | Tập trung ngôn ngữ/tiếng Việt, không chuyên sâu Toán |

### 2.3. Phân tích SWOT

**Strengths (Điểm mạnh cơ hội):**
- Tập trung độ tuổi 6 duy nhất (deep focus)
- Tiếng Việt native, không rào cản ngôn ngữ
- Thiết kế cho thiết bị cảm ứng đa dạng (điện thoại bình dân phổ biến tại VN)
- Offline-first design (phù hợp hạ tầng internet VN)

**Weaknesses (Thách thức):**
- Monkey Math đã chiếm thị phần lớn với ngân sách marketing lớn
- Early Start có hệ sinh thái vững chắc (Junior, Stories, Math)
- Chi phí marketing user acquisition tại VN cao

**Opportunities (Cơ hội):**
- Monkey Math học bằng tiếng Anh -> Cơ hội cho app học bằng tiếng Việt chất lượng cao
- Nhu cầu học toán tư duy tăng cao (phụ huynh VN quan tâm)
- Thiết bị Android giá rẻ phổ biến -> Cơ hội thị trường sâu
- Thiếu app miễn phí chất lượng cao bằng tiếng Việt

**Threats (Rủi ro):**
- Early Start có thể ra mắt phiên bản tiếng Việt
- Các ông lớn quốc tế (Khan Academy) có thể localize
- Xu hướng phụ huynh muốn con học toán bằng tiếng Anh song song

## 3. Kiến trúc Kỹ thuật

### 3.1. Lựa chọn Framework Đa nền tảng

So sánh các framework phù hợp cho app giáo dục trẻ em:

| Tiêu chí | Flutter | React Native + Expo | Ionic + Capacitor |
|----------|---------|---------------------|-------------------|
| **Hiệu suất Animation** | ưu tú (120fps, Impeller engine) | Tốt (60fps) | Trung bình (WebView) |
| **Kích thước App** | ~8-15MB | ~15-25MB | ~5-10MB (nhưng WebView nặng) |
| **Phát triển Game/Gamification** | Xuất sắc (Custom rendering) | Khá (cần thư viện ngoài) | Hạn chế |
| **Hỗ trợ Offline** | Native tốt | Khá (cần setup) | Khá (Service Workers) |
| **Web (PWA)** | Không native (cần build riêng) | Tốt (Expo Web) | Xuất sắc (Web-first) |
| **Android Low-end** | Tốt (AOT compile) | Khá (JS bridge overhead) | Kém (WebView chậm) |
| **Ecosystem Thư viện** | Tăng trưởng nhanh | Rất lớn | Lớn (web ecosystem) |
| **Khả năng đa ngôn ngữ** | Tốt (intl package) | Tốt (i18n libraries) | Tốt |
| **Thời gian học** | 2-4 tuần (Dart mới) | 1-2 tuần (nếu biết React) | 1 tuần (web dev) |
| **Chi phí thuê dev VN** | $$90-130/h | $$75-110/h | $$60-90/h |

**Khuyến nghị: Flutter**

Lý do chọn Flutter cho app này:
1. **Animation & Graphics:** App toán cho trẻ 6 tuổi cần nhiều animation mượt, hình ảnh sống động, gamification -> Flutter/Impeller engine cho hiệu suất gần native
2. **UI Consistency:** Trẻ em cần UI nhất quán, màu sắc rực rỡ, tương tác chính xác -> Flutter render UI độc lập, không phụ thuộc native components
3. **Offline-first:** Flutter hỗ trợ SQLite, local storage tốt -> phù hợp thị trường VN internet không ổn định
4. **Single Codebase:** Một codebase cho Android + iOS + Web (Flutter Web cho PWA)
5. **Future-proof:** Google backing, roadmap rõ ràng, community lớn

**Nhược điểm cần chấp nhận:**
- Flutter Web có kích thước bundle lớn hơn -> Tối ưu lazy loading, code splitting
- Cần học Dart (nhưng dễ học cho dev biết JS/Kotlin/Java)

### 3.2. Cấu trúc Hệ thống (System Architecture)

```
┌─────────────────────────────────────────────────────────────┐
│                        CLIENT LAYER                          │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Flutter Web  │  │   Android    │  │    iOS       │      │
│  │    (PWA)      │  │    (APK)     │  │   (Future)   │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │               │
│  ┌──────▼──────────────────▼──────────────────▼──────┐      │
│  │           Flutter Shared Codebase                 │      │
│  │  UI Layer | State Management | Business Logic    │      │
│  └──────┬──────────────────┬───────────────────────┘      │
│         │                  │                                │
│  ┌──────▼────────┐  ┌──────▼────────┐                      │
│  │  Local DB      │  │   Offline      │                      │
│  │  (SQLite/Hive) │  │   Sync Engine  │                      │
│  └────────────────┘  └────────────────┘                      │
└──────────────────────┬──────────────────────────────────────┘
                       │ HTTPS/REST + WebSocket
┌──────────────────────▼──────────────────────────────────────┐
│                      SERVER LAYER                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   API Gateway │  │  User Service│  │Content Service│      │
│  └──────┬───────┘  └──────────────┘  └──────────────┘      │
│         │                                                    │
│  ┌──────▼──────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Auth/JWT   │  │Progress Track│  │  Analytics   │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                              │
│  ┌────────────────────────────────────────────────────────┐│
│  │            Cloud Storage (CDN for assets)               ││
│  └────────────────────────────────────────────────────────┘│
└─────────────────────────────────────────────────────────────┘
```

### 3.3. Stack Công nghệ Chi tiết

#### Frontend (Flutter)
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod hoặc Bloc (khuyến nghị Riverpod cho code đơn giản)
- **Local Database:** Hive (nhanh, key-value phù hợp cache) + SQLite (dữ liệu có cấu trúc)
- **Networking:** Dio (HTTP client mạnh mẽ, hỗ trợ interceptor)
- **Animation:** Flutter built-in (AnimationController, Tween) + Lottie (complex animations)
- **Audio:** audioplayers (phát âm thanh, hướng dẫn bằng giọng nói)
- **Localization:** flutter_localizations + intl package
- **Offline:** connectivity_plus + workmanager (background sync)

#### Backend (Khuyến nghị)
- **Runtime:** Node.js (TypeScript) hoặc Python (FastAPI)
- **Framework:** NestJS (Node) hoặc FastAPI (Python) - chọn NestJS nếu team quen JS/TS
- **Database:** PostgreSQL (relational data) + Redis (cache/session)
- **Authentication:** Firebase Auth (Auth0 hoặc AWS Cognito)
- **Storage:** AWS S3 / Google Cloud Storage (lưu trữ hình ảnh, audio, video)
- **CDN:** CloudFront / CloudFlare (phân phối nội dung tĩnh)
- **Analytics:** Firebase Analytics (miễn phí, tích hợp tốt với Flutter)
- **Push Notification:** Firebase Cloud Messaging (FCM)

### 3.3. Stack Công nghệ Chi tiết

#### Frontend (Flutter)
- **Framework:** Flutter 3.x (Dart)
- **State Management:** Riverpod hoặc Bloc
- **Local Database:** Hive + SQLite
- **Networking:** Dio
- **Animation:** Flutter built-in + Lottie
- **Audio:** audioplayers
- **Localization:** flutter_localizations + intl
- **Offline:** connectivity_plus + workmanager
- **Docker:** Docker image cho CI/CD build và staging web container

#### Backend — Kiến trúc Component-Based (Dockerized)

Thay vì 1 monolith duy nhất, backend được chia thành **các services nhỏ**, mỗi service là 1 component/Microservice độc lập, có thể build & deploy riêng biệt bằng Docker.

| Component | Tech | Chức năng | Deploy |
|-----------|------|-----------|--------|
| **API Gateway** | Traefik / Nginx | Routing, rate-limit, SSL termination | Docker container |
| **Auth Service** | NestJS (TypeScript) | JWT, OAuth2, Firebase Auth adapter | Docker container |
| **User Service** | NestJS + PostgreSQL | Profiles, phụ huynh, trẻ em | Docker container |
| **Content Service** | NestJS + PostgreSQL | Bài học, câu hỏi, curriculum | Docker container |
| **Progress Service** | NestJS + PostgreSQL | Tiến độ học, points, streaks | Docker container |
| **Media Service** | Node.js + MinIO/S3 | Upload/Stream audio, images, video | Docker container |
| **Notification Service** | Node.js + Redis | Push notification, FCM, email queue | Docker container |
| **Analytics Service** | Node.js + ClickHouse/PostgreSQL | Báo cáo học tập, dashboards | Docker container |

**Container Orchestration:** Docker Compose (local/dev) → Kubernetes (production)

#### DevOps & Docker Stack
- **Container Runtime:** Docker + Docker Compose
- **CI/CD:** GitHub Actions (build Docker image, push to registry)
- **Registry:** GitHub Container Registry (ghcr.io) hoặc Docker Hub
- **Code Quality:** Very Good Analysis, SonarQube
- **Monitoring:** Sentry, Firebase Crashlytics, Prometheus + Grafana (Docker)
- **Design:** Figma
- **Project Management:** Linear / Jira

## 4. Thiết kế Sản phẩm (Product Design)

### 4.1. Đặc điểm Thiết kế cho Trẻ 6 tuổi

**Nguyên tắc thiết kế UX/UI:**
- **Touch targets tối thiểu 48x48dp** (ngón tay trẻ kém chính xác hơn người lớn)
- **Màu sắc rực rỡ, tương phản cao** (phù hợp thị giác đang phát triển)
- **Font size lớn** (tối thiểu 18sp cho body text, 24sp cho instructions)
- **Hình ảnh > Chữ** (trẻ 6 tuổi đọc chậm, cần icon/visual rõ ràng)
- **Phản hồi tức thì** (animation, âm thanh khi tương tác)
- **Không có chữ nhỏ/liên tục** (tối đa 1-2 câu hướng dẫn mỗi màn hình)
- **Hướng dẫn bằng giọng nói** (đọc câu hỏi, động viên, hướng dẫn)
- **Không có quảng cáo** (COPPA compliance, an toàn cho trẻ em)
- **Không có nút "Back/Exit" dễ vô tình nhấn** (tránh thoát app khi đang học)

### 4.2. Cấu trúc Nội dung (Content Structure)

**Chương trình học theo Chương trình GDPT Mới Việt Nam (Bộ GD&ĐT):**

```
Lớp Mẫu giáo lớn (5-6 tuổi) / Lớp 1 (6-7 tuổi)
├── Chuyên đề 1: Số và Phép tính
│   ├── Chủ đề 1.1: Đếm đến 100
│   ├── Chủ đề 1.2: Số hàng chục, hàng đơn vị
│   ├── Chủ đề 1.3: So sánh số
│   ├── Chủ đề 1.4: Phép cộng trong phạm vi 10
│   ├── Chủ đề 1.5: Phép trừ trong phạm vi 10
│   ├── Chủ đề 1.6: Phép cộng/trừ trong phạm vi 20
│   └── Chủ đề 1.7: Phép cộng/trừ có nhớ (nhẹ nhàng)
├── Chuyên đề 2: Hình học
│   ├── Chủ đề 2.1: Nhận biết hình tròn, vuông, tam giác, chữ nhật
│   ├── Chủ đề 2.2: Vẽ và tô màu hình
│   └── Chủ đề 2.3: Xếp hình, ghép hình
├── Chuyên đề 3: Đo lường
│   ├── Chủ đề 3.1: So sánh dài/ngắn, cao/thấp, nặng/nhẹ
│   ├── Chủ đề 3.2: Đo bằng đơn vị không chuẩn
│   └── Chủ đề 3.3: Giờ (kim giờ, kim phút đơn giản)
├── Chuyên đề 4: Tư duy Logic
│   ├── Chủ đề 4.1: Sắp xếp theo quy luật
│   ├── Chủ đề 4.2: Phân loại nhóm
│   ├── Chủ đề 4.3: So sánh số lượng
│   └── Chủ đề 4.4: Bài toán đố vui
└── Chuyên đề 5: Toán thực tiễn
    ├── Chủ đề 5.1: Đếm tiền (đồng, hào - đơn giản)
    ├── Chủ đề 5.2: Ngày trong tuần, tháng
    └── Chủ đề 5.3: Bài toán có lời văn đơn giản
```

### 4.3. Gamification System

**Hệ thống phần thưởng:**
- **Stars (1-3 sao):** Hoàn thành bài học (1 sao = hoàn thành, 2 sao = đúng >70%, 3 sao = đúng >90%)
- **Stickers/Badges:** Thu thập nhãn dán cho từng chủ đề hoàn thành
- ** streaks:** Chuỗi ngày học liên tiếp (ví dụ: "Bé đã học 7 ngày liên tiếp!")
- **Virtual Pet/Cây:** Nuôi thú ảo hoặc trồng cây bằng điểm thưởng (như Prodigy nhưng đơn giản hơn)
- **Unlock levels:** Mở khóa chủ đề mới, minigame mới
- **Minigames giải trí:** Thưởng bằng trò chơi nhẹ sau khi hoàn thành bài học

**Cơ chế Engagement:**
- **Session length phù hợp:** 10-15 phút/lần (thông báo khi đủ thời gian)
- **Adaptive difficulty:** Tự động điều chỉnh độ khó dựa trên hiệu suất
- **Hint system:** Gợi ý khi trẻ trả lời sai 2 lần liên tiếp
- **Celebration animations:** Pháo hoa, vỗ tay khi đạt thành tích

### 4.4. Tính năng dành cho Phụ huynh

- **Parental Dashboard:** Theo dõi tiến độ học tập (thời gian, chủ đề đã học, điểm yếu)
- **Time limits:** Giới hạn thời gian học mỗi ngày (15/30/45 phút)
- **Reports:** Báo cáo hàng tuần qua email/Zalo (phổ biến tại VN)
- **Offline mode toggle:** Cho phép học không cần internet
- **Multiple profiles:** Hỗ trợ nhiều con trong một tài khoản

## 5. Chiến lược Đa ngôn ngữ (i18n)

### 5.1. Kiến trúc Ngôn ngữ

```
┌──────────────────────────────────────────┐
│           Localization Layer              │
├──────────────────────────────────────────┤
│  Locale: vi_VN (Primary)                  │
│  ├── Content: 100% Vietnamese             │
│  ├── Audio: Vietnamese (Nam/Nữ)         │
│  ├── Text: Vietnamese                     │
│  └── Curriculum: Chương trình GDPT VN   │
├──────────────────────────────────────────┤
│  Locale: en_US (Secondary)                │
│  ├── Content: Math concepts universal      │
│  ├── Audio: English (US/UK)               │
│  ├── Text: English                       │
│  └── Curriculum: Common Core (reference) │
├──────────────────────────────────────────┤
│  Locale: future (Extensible)             │
│  ├── Structured for easy addition         │
│  └── JSON/ARB format for translators    │
└──────────────────────────────────────────┘
```

### 5.2. Kế hoạch Triển khai Ngôn ngữ

| Giai đoạn | Ngôn ngữ | Nội dung | Ghi chú |
|-----------|----------|----------|---------|
| **MVP** | Tiếng Việt | 100% UI, content, audio | Tập trung thị trường VN |
| **v1.1** | Tiếng Việt + English | UI toggle, song ngữ cơ bản | Phụ huynh muốn con học song ngữ |
| **v2.0** | Thêm tiếng Khmer, tiếng Lào | ASEAN neighbors | Mở rộng thị trường |
| **v3.0** | Tiếng Trung, tiếng Hàn | Cộng đồng lớn tại VN | Expats và người Việt ở nước ngoài |

### 5.3. Kỹ thuật Localization

- **Format:** ARB (Application Resource Bundle) files - chuẩn Flutter
- **Audio:** Mỗi locale có thư mục audio riêng, tên file trùng key
- **Text direction:** Chỉ hỗ trợ LTR (Left-to-Right) ban đầu
- **Date/Number:** intl package (định dạng số VN: 1.000,50 thay vì 1,000.50)
- **Curriculum mapping:** Mỗi locale có thể có curriculum khác nhau (VN dùng GDPT, US dùng Common Core)

## 6. Lộ trình Phát triển (Roadmap)

### 6.1. Giai đoạn 1: MVP (Tháng 1-3)
**Mục tiêu:** App Android cơ bản, tiếng Việt, offline

- [ ] Thiết kế UI/UX (Figma prototype)
- [ ] Cài đặt Flutter project với localization framework
- [ ] Xây dựng 3 Chuyên đề đầu tiên (Số và Phép tính cơ bản)
- [ ] Hệ thống gamification cơ bản (stars, badges đơn giản)
- [ ] Audio hướng dẫn bằng tiếng Việt (text-to-speech hoặc thu âm)
- [ ] Local database (SQLite) cho offline content
- [ ] Parent dashboard cơ bản
- [ ] Beta test với 20 gia đình

### 6.2. Giai đoạn 2: Hoàn thiện Nền tảng (Tháng 4-6)
**Mục tiêu:** Web PWA, đầy đủ nội dung lớp 1

- [ ] Build Flutter Web (PWA) với offline support
- [ ] Hoàn thiện toàn bộ 5 Chuyên đề cho lớp 1
- [ ] Backend API (NestJS/FastAPI) cho đồng bộ dữ liệu
- [ ] Authentication (Firebase Auth)
- [ ] Cloud sync (học tiến độ, thành tích)
- [ ] Hệ thống adaptive learning thuật toán đơn giản
- [ ] Analytics và crash reporting
- [ ] Soft launch trên CH Play và Web

### 6.3. Giai đoạn 3: Mở rộng (Tháng 7-9)
**Mục tiêu:** Song ngữ Việt-Anh, iOS, nâng cao AI

- [ ] Thêm locale tiếng Anh (UI + content + audio)
- [ ] Build iOS version (App Store)
- [ ] AI-powered hint system (gợi ý thông minh dựa trên lỗi sai)
- [ ] Advanced analytics cho phụ huynh
- [ ] Social features (chia sẻ thành tích, bảng xếp hạng)
- [ ] In-app purchase / Subscription model
- [ ] Marketing campaign tại VN

### 6.4. Giai đoạn 4: Tăng trưởng (Tháng 10-12)
**Mục tiêu:** Quốc tế hóa, nâng cao

- [ ] Thêm ngôn ngữ mới (Khmer, Lào)
- [ ] Curriculum cho lớp 2 (mở rộng đối tượng)
- [ ] Live tutor integration (tương tự Brighterly)
- [ ] AR/VR minigames (nếu phù hợp)
- [ ] API cho trường học/B2B
- [ ] White-label cho các trung tâm giáo dục

## 7. Mô hình Kinh doanh

### 7.1. Freemium Strategy

| Tier | Giá | Tính năng |
|------|-----|-----------|
| **Free** | Miễn phí | 3 chủ đề đầu tiên, quảng cáo không xâm lấn (banner nhẹ), giới hạn 15 phút/ngày |
| **Premium** | 99,000 VNĐ/tháng hoặc 799,000 VNĐ/năm | Toàn bộ nội dung, không giới hạn thời gian, không quảng cáo, đồng bộ đa thiết bị, báo cáo chi tiết |
| **Family** | 149,000 VNĐ/tháng | Tài khoản Premium cho 3 trẻ, báo cáo so sánh anh chị em |

### 7.2. So sánh Giá cả với Đối thủ

| Ứng dụng | Giá (VNĐ/tháng) | Nhận xét giá |
|----------|----------------|---------------|
| Monkey Math | ~250,000-350,000 | Giá cao, học bằng tiếng Anh |
| HelloMath | ~150,000-200,000 | Tầm trung |
| KidsUP Soroban | ~200,000-300,000 | Niche, phương pháp đặc biệt |
| vnEdu Tú Tài | ~100,000-150,000 | B2B oriented |
| **Đề xuất của chúng ta** | **99,000/tháng** | Cạnh tranh, tiếng Việt native |

## 8. Rủi ro và Giải pháp

| Rủi ro | Mức độ | Giải pháp |
|--------|---------|-----------|
| Monkey Math phản ứng cạnh tranh | Cao | Tập trung差异化: tiếng Việt native, offline, giá rẻ, UX thân thiện hơn |
| User acquisition cost cao | Cao | Chiến lược organic: content marketing (blog phụ huynh), TikTok/YouTube shorts, partnerships với trường mầm non |
| Trẻ em mất hứng nhanh | Trung bình | Adaptive content, cập nhật nội dung hàng tuần, minigames đa dạng |
| Cô giáo/Phụ huynh không tin tưởng | Trung bình | Đảm bảo nội dung theo chuẩn Bộ GD&ĐT, testimonials, báo cáo tiến bộ rõ ràng |
| Technical debt khi mở rộng ngôn ngữ | Trung bình | Thiết kế i18n từ đầu, sử dụng flutter_localizations, không hardcode text |
| Performance trên thiết bị giá rẻ | Trung bình | Optimization từ sớm: lazy loading, image compression, giảm animation complexity |

## 9. Docker Deployment Architecture

### 9.1. Docker Compose (Development)

```yaml
# docker-compose.yml
version: '3.8'
services:
  # Frontend (Flutter Web PWA)
  flutter-web:
    build: ./frontend
    ports:
      - "8080:80"
    container_name: math_frontend
    restart: unless-stopped

  # API Gateway
  gateway:
    image: traefik:v2.10
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./gateway/traefik.yml:/etc/traefik/traefik.yml
      - /var/run/docker.sock:/var/run/docker.sock
    command:
      - "--api.insecure=true"
      - "--providers.docker=true"
      - "--entrypoints.web.address=:80"
    restart: unless-stopped

  # Auth Service
  auth-service:
    build: ./backend/auth
    labels:
      - "traefik.http.routers.auth.rule=PathPrefix(`/api/auth`)"
    environment:
      - DB_URL=postgres://auth_user:auth_pass@auth-db:5432/auth_db
      - JWT_SECRET=dev-secret
    depends_on:
      - auth-db
      - redis
    restart: unless-stopped

  # User Service
  user-service:
    build: ./backend/user
    labels:
      - "traefik.http.routers.user.rule=PathPrefix(`/api/users`)"
    environment:
      - DB_URL=postgres://user_user:user_pass@user-db:5432/user_db
    depends_on:
      - user-db
      - redis
    restart: unless-stopped

  # Content Service
  content-service:
    build: ./backend/content
    labels:
      - "traefik.http.routers.content.rule=PathPrefix(`/api/content`)"
    environment:
      - DB_URL=postgres://content_user:content_pass@content-db:5432/content_db
    depends_on:
      - content-db
      - redis
    restart: unless-stopped

  # Progress Service
  progress-service:
    build: ./backend/progress
    labels:
      - "traefik.http.routers.progress.rule=PathPrefix(`/api/progress`)"
    environment:
      - DB_URL=postgres://progress_user:progress_pass@progress-db:5432/progress_db
    depends_on:
      - progress-db
      - redis
    restart: unless-stopped

  # Notification Service
  notification-service:
    build: ./backend/notification
    labels:
      - "traefik.http.routers.notification.rule=PathPrefix(`/api/notifications`)"
    environment:
      - REDIS_URL=redis://redis:6379
      - FCM_API_KEY=${FCM_API_KEY}
    depends_on:
      - redis
    restart: unless-stopped

  # Media Service
  media-service:
    build: ./backend/media
    labels:
      - "traefik.http.routers.media.rule=PathPrefix(`/api/media`)"
    environment:
      - S3_ENDPOINT=minio:9000
      - S3_ACCESS_KEY=${MINIO_ACCESS_KEY}
      - S3_SECRET_KEY=${MINIO_SECRET_KEY}
    depends_on:
      - minio
    restart: unless-stopped

  # Database Services
  auth-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: auth_db
      POSTGRES_USER: auth_user
      POSTGRES_PASSWORD: auth_pass
    volumes:
      - auth_db_data:/var/lib/postgresql/data

  user-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: user_db
      POSTGRES_USER: user_user
      POSTGRES_PASSWORD: user_pass
    volumes:
      - user_db_data:/var/lib/postgresql/data

  content-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: content_db
      POSTGRES_USER: content_user
      POSTGRES_PASSWORD: content_pass
    volumes:
      - content_db_data:/var/lib/postgresql/data

  progress-db:
    image: postgres:15-alpine
    environment:
      POSTGRES_DB: progress_db
      POSTGRES_USER: progress_user
      POSTGRES_PASSWORD: progress_pass
    volumes:
      - progress_db_data:/var/lib/postgresql/data

  # Redis
  redis:
    image: redis:7-alpine
    restart: unless-stopped

  # MinIO (S3 compatible)
  minio:
    image: minio/minio:latest
    ports:
      - "9000:9000"
      - "9001:9001"
    environment:
      MINIO_ROOT_USER: ${MINIO_ACCESS_KEY}
      MINIO_ROOT_PASSWORD: ${MINIO_SECRET_KEY}
    command: server /data --console-address ":9001"
    volumes:
      - minio_data:/data
    restart: unless-stopped

volumes:
  auth_db_data:
  user_db_data:
  content_db_data:
  progress_db_data:
  minio_data:
```

### 9.2. Dockerfile Example (Frontend)

```dockerfile
# frontend/Dockerfile
FROM ghcr.io/cirruslabs/flutter:3.22-stable AS builder

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

FROM nginx:alpine
COPY --from=builder /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
```

### 9.3. Dockerfile Example (Backend Service)

```dockerfile
# backend/auth/Dockerfile
FROM node:20-alpine

WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

EXPOSE 3000
CMD ["node", "dist/main.js"]
```

### 9.4. CI/CD Pipeline (GitHub Actions)

```yaml
# .github/workflows/deploy.yml
name: Deploy
on:
  push:
    branches: [main]

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Set up Docker Buildx
        uses: docker/setup-buildx-action@v3
      
      - name: Login to Container Registry
        uses: docker/login-action@v3
        with:
          registry: ghcr.io
          username: ${{ github.actor }}
          password: ${{ secrets.GITHUB_TOKEN }}
      
      - name: Build and push frontend
        run: |
          docker build -t ghcr.io/${{ github.repository }}/frontend:${{ github.sha }} ./frontend
          docker push ghcr.io/${{ github.repository }}/frontend:${{ github.sha }}
      
      - name: Build and push services
        run: |
          for service in auth user content progress notification media; do
            docker build -t ghcr.io/${{ github.repository }}/$service:${{ github.sha }} ./backend/$service
            docker push ghcr.io/${{ github.repository }}/$service:${{ github.sha }}
          done
```

## 10. Đề xuất Hành động Tiếp theo

1. **Khảo sát thị trường:** Thu thập feedback từ 50 phụ huynh có con 5-7 tuổi
2. **Xây dựng prototype:** Thiết kế UI/UX trên Figma, test với 5-10 trẻ em
3. **Setup project:** Khởi tạo Flutter project với i18n, tạo Docker Compose cho backend services
4. **Biên soạn nội dung:** Soạn 100 bài tập đầu tiên theo chuẩn GDPT, thu âm audio hướng dẫn
5. **Tuyển dụng đội ngũ:** 1 Flutter developer, 1 Backend developer (NestJS), 1 UI/UX designer
6. **Sprint 0 (2 tuần):** Setup CI/CD, Docker registry, core architecture, design system

## 11. Tài liệu Tham khảo

- [Flutter Documentation](https://docs.flutter.dev/)
- [NestJS Documentation](https://docs.nestjs.com/)
- [Docker Documentation](https://docs.docker.com/)
- [Traefik Documentation](https://doc.traefik.io/traefik/)
- [Chương trình GDPT Mới 2018 - Bộ GD&ĐT Việt Nam](https://moet.gov.vn/)
- [COPPA Compliance Guidelines](https://www.ftc.gov/business-guidance/resources/complying-coppa-frequently-asked-questions)
- [Firebase for Flutter](https://firebase.google.com/docs/flutter/setup)
- [Material Design for Kids](https://m3.material.io/)

---

*Kế hoạch này được biên soạn dựa trên nghiên cứu thị trường và phân tích công nghệ cập nhật đến tháng 4/2026.*
