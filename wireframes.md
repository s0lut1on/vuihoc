# Math Learning App Wireframes
## Prototype Flow for Persona-Based Onboarding

---

## Screen 1: Welcome & Persona Selection

### Layout (375x812 - iPhone SE / Android equivalent)

```
+----------------------------------+
|                                  |
|        (pink background)         |
|                                  |
|      +------------------+        |
|      |                  |        |
|      |     [FROG]       |        |
|      |    🐸 Mascot     |        |
|      |                  |        |
|      +------------------+        |
|                                  |
|   Xin chào, bé yêu!              |
|   Hãy cùng học Toán vui nhé!    |
|                                  |
|   Chọn cách học của bé:          |
|                                  |
|  +----------+   +----------+     |
|  |  [STAR]  |   | [GAME]   |     |
|  |   ⭐      |   |   🎮      |     |
|  | Học giỏi |   | Chơi nhiều|     |
|  |Thích đua |   | Thích game|     |
|  +----------+   +----------+     |
|                                  |
|  +----------+   +----------+     |
|  |[HEART]   |   | [OWL]    |     |
|  |   💙      |   |   🦉      |     |
|  | Động viên|   | Nhút nhát |     |
|  |Chậm rãi  |   | Học âm   |     |
|  +----------+   +----------+     |
|                                  |
|  [ 🇻🇳 Tiếng Việt  ▼ ]          |
|                                  |
|  +----------------------------+  |
|  |      BẮT ĐẦU HỌC!         |  |
|  |      (pink button)         |  |
|  +----------------------------+  |
|                                  |
|  Bố mẹ nhấn vào đây             |
+----------------------------------+
```

### Design Notes
- **Background:** `#FFE8F0` soft pink
- **Mascot:** 140px circle `#FF6B9D`, green frog emoji 🐸
- **Cards:** 150x160px, 16px corner radius, emoji 40px + text 13px
- **Persona color coding:**
  - ⭐ **High Achiever** — `#FFF3E0` (orange bg), `#E65100` text
  - 🎮 **Gamer** — `#E8F5E9` (green bg), `#2E7D32` text
  - 💙 **Struggler** — `#E3F2FD` (blue bg), `#1565C0` text
  - 🦉 **Silent Learner** — `#F3E5F5` (purple bg), `#7B1FA2` text
- **Selected state:** 2px border `#FF6B9D`, slight scale up
- **Language toggle:** White pill, 44px height, subtle border
- **CTA:** 220x52px, `#FF6B9D`, white text, 26px radius
- **Touch targets:** Minimum 48px for all tappable areas
- **Font size:** Title 32px bold, subtitle 18px, cards 13px

### Interaction
1. Child taps persona card → highlight selected, mascot winks
2. Language toggle → switches between 🇻🇳 / 🇬🇧 (Vietnamese / English)
3. "Bắt đầu học!" → navigates to Assessment Screen

---

## Screen 2: Skippable Onboarding Assessment

### Layout

```
+----------------------------------+
|  [====|====|====|    ]          |   Progress: 3/4
|                                  |
|  🦉                 +----------+ |
|  (owl)   "Bé đã đếm| Đếm đến 10?| |
|          được đến |+----------+||
|          số mấy    |           ||
|          rồi?"     +-----------+|
|                                  |
|                                  |
|  +-----------------------------+ |
|  |  10                           | |
|  |  Đếm đến 10                   | |
|  |  (selected - pink border)    |
|  +-----------------------------+ |
|                                  |
|  +-----------------------------+ |
|  |  50                           | |
|  |  Đếm đến 50                   | |
|  |  (default - gray border)      | |
|  +-----------------------------+ |
|                                  |
|  +-----------------------------+ |
|  |  100+                         | |
|  |  Đếm đến 100 hoặc hơn       | |
|  |  (default - gray border)      | |
|  +-----------------------------+ |
|                                  |
|  💡 Không biết? Chọn câu gần     |
|     đúng nhất nhé!               |
|                                  |
+----------------------------------+
```

### Design Notes
- **Background:** `#FFF8E1` warm cream
- **Progress bars:** 4 segments, 80px wide, 8px height, `#FF6B9D` filled, `#E0E0E0` remaining
- **Mascot bubble:** White, 16px radius, subtle gray border, owl positioned left
- **Options:** Full width, 64px height, 16px radius
  - Selected: 2px `#FF6B9D` border
  - Unselected: 1px `#E0E0E0` border
- **Answer value:** 24px bold, colored `#FF6B9D`
- **Hint text:** 14px, `#888888`, centered
- **Skip logic:** If user taps "Không biết", auto-select middle option

### Questions Flow (4 questions)
1. Counting range: 10 / 50 / 100+
2. Basic operations: Yes / No / Sometimes
3. Learning speed: Fast / Normal / Need help
4. Preferred activity: Competing / Games / Quiet / Help from friend

---

## Screen 3: Adaptive Home Dashboard

### Layout (Personalized by Persona)

```
+----------------------------------+
| 🐸 Bé Minh Anh      💎 248       |
| 🔥 7 ngày liên tiếp!             |
|                                  |
|   Hôm nay học gì?                |
|                                  |
|  +-----------+  +-----------+    |
|  |    12     |  |     3     |    |
|  | Bài đã học|  |⭐ Sao tích|    |
|  |           |  |   lũy     |    |
|  +-----------+  +-----------+    |
|                                  |
|  +-----------------------------+ |
|  |  ▶️ Tiếp tục học             | |
|  |     Phép cộng 1 - 10        | |
|  |     (bright pink card)       | |
|  +-----------------------------+ |
|                                  |
|   Các chủ đề                     |
|                                  |
|  +-----------+  +-----------+    |
|  |    🔢     |  |    📐      |    |
|  |  Số học   |  | Hình học   |    |
|  |  #FFE8F0  |  |  #E8F5E9   |    |
|  +-----------+  +-----------+    |
|  +-----------+  +-----------+    |
|  |    📏     |  |    🧩      |    |
|  | Đo lường  |  | Tư duy     |    |
|  |  #FFF3E0  |  |  #E3F2FD   |    |
|  +-----------+  +-----------+    |
|                                  |
+----------------------------------+
```

### Persona Adaptations

| Element | High Achiever | Struggler | Gamer | Silent |
|---------|--------------|-----------|-------|--------|
| **Continue card text** | "Tiếp tục giành 3 sao!" | "Hôm nay mình học gì?" | "Kiếm thêm 50 điểm!" | "Bé sẵn sàng chưa?" |
| **Stats emphasis** | Stars (#2), Streak visible | Encouragement message, days | Gems, XP bar | Private streak (subtle) |
| **Subject tiles** | Lock icons on advanced | Highlight easiest subject | Game icons prominent | Same, softer colors |
| **Ranking** | Class rank shown | Hidden | Friend leaderboard | None |
| **Push notification** | "You're #3! Beat Mai Anh?" | "Bé đã học 3 ngày!" | "Open chest now!" | "Cú về nhà đang chờ!" |

---

## Screen 4: Math Lesson (Counting)

### Layout

```
+----------------------------------+
|  [####|####|####|####|    ]     |   Progress 4/5
|                              ✕   |
|                                  |
|   🍎 Đếm có bao nhiêu quả táo?   |
|                                  |
|                                  |
|        🍎    🍎    🍎            |
|                                  |
|        🍎    🍎                  |
|                                  |
|                                  |
|     +-----+    +-----+    +-----+|
|     |  3  |    |  5  |    |  4  ||
|     |     |    |     |    |     ||
|     |(pink)|(gray) |(gray) ||
|     +-----+    +-----+    +-----+|
|                                  |
|  +-----------------------------+ |
|  | 💡 Gợi ý: Chỉ vào từng quả  | |
|  |    và đếm từng quả một!      | |
|  +-----------------------------+ |
|                                  |
|              (  🔊  )             |
|           Voice button           |
|                                  |
+----------------------------------+
```

### Design Notes
- **Background:** `#E3F2FD` light blue
- **Progress:** 5 segments, 5px height, `#4CAF50` filled, `#E0E0E0` empty
- **Close button:** 24px, top right, `#888888`
- **Question:** 22px, `#2D1B4E`, bold, emoji + text
- **Visual:** Apples arranged in visual groupings (3 top, 2 bottom), 64px emoji
- **Answers:** 90x90px circles/squares, 20px radius
  - Selected wrong: gentle shake, "Hmm, thử lại nhé!"
  - Selected right: bounce + confetti, "Chính xác! 🎉"
- **Touch targets:** 90px minimum (well above 48px)
- **Hint:** White card, 16px radius, pink text
- **Voice button:** 60px circle, `#FF6B9D`, reads question aloud in Vietnamese

### Answer States
```
+----------+     +----------+     +----------+
|    3     |     |    3     |     |    3     |
|  default | --> | selected | --> | correct  |
|  gray    |     | pink     |     | green    |
+----------+     +----------+     +----------+
```

```
+----------+     +----------+
|    5     |     |    5     |
| selected | --> |  wrong   |
|  pink    |     |  shake   |
+----------+     +----------+
```

---

## Screen 5: Success Celebration

### Layout (Correct Answer Feedback)

```
+----------------------------------+
|                                  |
|                                  |
|        ✨ CONGRATS ✨              |
|                                  |
|       +------------------+       |
|       |                  |       |
|       |   ⭐ 3 SAO! ⭐      |       |
|       |                  |       |
|       |   CHÍNH XÁC!      |       |
|       |                  |       |
|       +------------------+       |
|                                  |
|        🎉  +5 💎              |
|                                  |
|   +--------+     +--------+      |
|   | Học tiếp |     | Về nhà |      |
|   | (green)  |     | (gray) |      |
|   +--------+     +--------+      |
|                                  |
+----------------------------------+
```

### Design Notes
- **Background:** Dark overlay on lesson screen, or full-screen `#FFF8E1`
- **Animation:** Confetti burst, mascot jumps, stars fly in from edges
- **Audio:** Celebration sound + "Chính xác! Bé giỏi quá!" (Vietnamese praise)
- **Star colors:**
  - 1 star: Bronze, "Bé đã hoàn thành!"
  - 2 stars: Silver, "Bé làm tốt lắm!"
  - 3 stars: Gold, "Xuất sắc! Bé giỏi quá!"
- **Gamification:** Gems +5, XP bar fills
- **Buttons:**
  - "Học tiếp" — Primary green, 140x48px
  - "Về nhà" — Secondary gray, 140x48px

### Persona Variations

| Persona | Additional Elements |
|-----------|---------------------|
| High Achiever | "Bé nhanh hơn 80% bạn bè!" rank |
| Gamer | Chest opens, drops random item |
| Struggler | Extra praise: "Bé đã cố gắng rất nhiều!" |
| Silent | Calm animation, no leaderboard prompt |
| Bilingual | "Correct! / Chính xác!" dual text |

---

## Screen 6: Parent Dashboard

### Layout (From "Bố mẹ nhấn vào đây")

```
+----------------------------------+
|  ←  Bảng Điều Khiển Phụ Huynh    |
|                                  |
|  🐸 Bé Minh Anh                   |
|  Đã học: 12 bài | Streak: 7 ngày |
|                                  |
|  +-----------------------------+ |
|  | 📊 Tiến độ tuần này          | |
|  |                             | |
|  |  ████████████░░░░  80%      | |
|  |                             | |
|  +-----------------------------+ |
|                                  |
|  📚 Chủ đề đã học:                |
|  ✅ Số học cơ bản (Hoàn thành)    |
|  📐 Hình học (Đang học)           |
|                                  |
|  ⚠️ Điểm yếu cần luyện tập:       |
|  • Phép cộng có nhớ              |
|  • So sánh số lớn hơn 50         |
|                                  |
|  +-----------------------------+ |
|  | ⏱️ Giới hạn thời gian: 30p  | |
|  | [===========O---]            | |
|  +-----------------------------+ |
|                                  |
|  [📤 Chia sẻ tiến bộ]  [⚙️ Cài đặt]|
|                                  |
+----------------------------------+
```

### Design Notes
- **Background:** `#F5F7FA`
- **Progress bars:** `#4CAF50` for completion, `#FF6B9D` for streaks
- **Weak areas:** Orange `#FF9800` warning, specific actionable items
- **Time slider:** 15/30/45/60 minute options
- **Share:** Zalo, Facebook, Email buttons
- **Language:** Vietnamese UI, content exportable in both languages

---

## Responsive Considerations

| Screen Size | Adjustments |
|-------------|-------------|
| **Small (320px)** | Single column cards, 120px wide, reduce padding to 16px |
| **Standard (375px)** | As designed above |
| **Large (414px+)** | 2 columns for subjects, larger touch targets (100px) |
| **Tablet (768px)** | Side-by-side layout, lesson on left, visual on right |

---

## Onboarding Flow Diagram

```
[OPEN APP]
    │
    ▼
[1. Welcome Screen]
    ├── Select Persona (4 options)
    └── Toggle Language (Vietnamese default)
    │
    ▼ (Tap "Bắt đầu học!")
[2. Assessment] ──→ Optional: Skip all → Home
    ├── Q1: Counting range
    ├── Q2: Basic operations
    ├── Q3: Learning speed
    └── Q4: Preferred activity
    │
    ▼
[3. Home Dashboard]
    ├── Personalized content order
    ├── Adaptive difficulty
    └── Gamification tailored to persona
    │
    ├── Tap Subject → [4. Lesson]
    ├── Tap Continue → [4. Lesson]
    └── Tap Parent Link → [6. Parent Dashboard]
    │
    ▼
[4. Math Lesson]
    ├── Visual question
    ├── Voice hint
    └── 3 answer choices
    │
    ├── Correct → [5. Celebration]
    └── Wrong → Retry (unlimited)
    │
    ▼
[5. Celebration]
    ├── Stars earned
    ├── Gems/XP awarded
    └── Next lesson / Home
```

---

## Animation & Interaction Specs

| Element | Trigger | Animation | Duration | Easing |
|---------|---------|-----------|----------|--------|
| Mascot | On load | Bounce in | 600ms | `ease-out-back` |
| Persona card | Tap | Scale 1.05 + border glow | 200ms | `ease-out` |
| Answer button | Tap | Scale down 0.95 then up | 150ms | `ease-in-out` |
| Correct answer | Selection | Bounce + confetti | 800ms | `ease-out-back` |
| Wrong answer | Selection | Shake horizontal 3x | 400ms | `ease-in-out` |
| Progress bar | Stage complete | Fill width | 300ms | `ease-out` |
| Hint card | Appear | Slide up + fade in | 300ms | `ease-out` |
| Celebration | Trigger | Stars fly from center | 1000ms | `ease-out` |
| Voice button | Tap | Pulse ring animation | 200ms | `ease-in-out` |

---

## Accessibility Notes

1. **Voice guidance:** Every instruction read aloud (tap 🔊 button)
2. **Large touch targets:** Minimum 90px for answer buttons
3. **High contrast:** Text `#2D1B4E` on light backgrounds
4. **No reading required:** Icons + voice heavy, minimal text
5. **No penalties:** Wrong answers = retry, not punishment
6. **Offline:** All content cached locally for poor connectivity
7. **Parent gate:** Math problem to access settings (age verification)
