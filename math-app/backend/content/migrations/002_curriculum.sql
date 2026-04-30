DROP TABLE IF EXISTS exercises CASCADE;
DROP TABLE IF EXISTS lessons CASCADE;
DROP TABLE IF EXISTS subjects CASCADE;

CREATE TABLE subjects (
    id VARCHAR(50) PRIMARY KEY,
    name_vi VARCHAR(255) NOT NULL,
    name_en VARCHAR(255) NOT NULL,
    description_vi TEXT,
    description_en TEXT,
    icon VARCHAR(10) DEFAULT '📚',
    color VARCHAR(50) DEFAULT '#FFE8F0',
    display_order INT NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE lessons (
    id VARCHAR(50) PRIMARY KEY,
    subject_id VARCHAR(50) NOT NULL REFERENCES subjects(id) ON DELETE CASCADE,
    title_vi VARCHAR(255) NOT NULL,
    title_en VARCHAR(255) NOT NULL,
    description_vi TEXT,
    description_en TEXT,
    lesson_order INT NOT NULL DEFAULT 1,
    difficulty INT NOT NULL DEFAULT 1 CHECK (difficulty BETWEEN 1 AND 3),
    is_premium BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE exercises (
    id VARCHAR(50) PRIMARY KEY,
    lesson_id VARCHAR(50) NOT NULL REFERENCES lessons(id) ON DELETE CASCADE,
    question_vi TEXT NOT NULL,
    question_en TEXT NOT NULL,
    options TEXT[] NOT NULL DEFAULT '{}',
    correct_index INT NOT NULL DEFAULT 0,
    visual_asset VARCHAR(50) DEFAULT '',
    hint_vi TEXT,
    hint_en TEXT,
    exercise_order INT NOT NULL DEFAULT 1,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_lessons_subject ON lessons(subject_id);
CREATE INDEX idx_exercises_lesson ON exercises(lesson_id);
CREATE INDEX idx_subjects_order ON subjects(display_order);

INSERT INTO subjects (id, name_vi, name_en, icon, color, display_order) VALUES
('numbers',      'Số học',      'Numbers',      '🔢', '#FFE8F0', 1),
('geometry',     'Hình học',    'Geometry',     '📐', '#E8F5E9', 2),
('measurement',  'Đo lường',    'Measurement',  '📏', '#FFF3E0', 3),
('logic',        'Tư duy',      'Logic',        '🧩', '#E3F2FD', 4);

INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty) VALUES
('lesson_n1', 'numbers', 'Đếm đến 10',         'Count to 10',       1, 1),
('lesson_n2', 'numbers', 'Các số 11 đến 20',   'Numbers 11 to 20',  2, 1),
('lesson_n3', 'numbers', 'So sánh các số',     'Compare numbers',   3, 1),
('lesson_n4', 'numbers', 'Phép cộng 1 – 10',    'Addition 1–10',     4, 1),
('lesson_n5', 'numbers', 'Phép trừ nhỏ hơn 10','Subtraction under 10',5, 2);

INSERT INTO exercises (id, lesson_id, question_vi, question_en, options, correct_index, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_n1_01', 'lesson_n1',
 'Có bao nhiêu quả táo 🍎?', 'How many apples 🍎?',
 ARRAY['3','5','4'], 1,
 '🍎🍎🍎🍎🍎',
 'Đếm từng quả táo và nhớ số cuối cùng!', 'Count each apple, the last number is the answer!',
 1),
('ex_n1_02', 'lesson_n1',
 'Đếm ngôi sao: ⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐', 'Count the stars: ⭐ ⭐ ⭐ ⭐ ⭐ ⭐ ⭐',
 ARRAY['6','7','8'], 1,
 '⭐⭐⭐⭐⭐⭐⭐',
 'Chỉ vào từng ngôi sao và đếm to', 'Point at each star and count aloud!',
 2),
('ex_n1_03', 'lesson_n1',
 'Số nào đứng sau số 8?', 'Which number comes after 8?',
 ARRAY['7','9','10'], 1,
 '🔢',
 'Đếm: 1, 2, 3... đến 8, số tiếp theo là gì?', 'Count: 1, 2, 3... up to 8, what comes next?',
 3),
('ex_n2_01', 'lesson_n2',
 'Có bao nhiêu bông hoa 🌸?', 'How many flowers 🌸?',
 ARRAY['11','12','13'], 0,
 '🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸🌸',
 'Đếm thật chậm, không bỏ quả nào nhé!', 'Count slowly, do not skip any!',
 1),
('ex_n2_02', 'lesson_n2',
 'Số nào lớn hơn: 15 hay 18?', 'Which number is bigger: 15 or 18?',
 ARRAY['15','18','Bằng nhau'], 1,
 '⚖️',
 'Đếm trên ngón tay đến 15, rồi tiếp tục đến 18!', 'Count on your fingers to 15, then keep going to 18!',
 2),
('ex_n3_01', 'lesson_n3',
 'So sánh: 7 ___ 3', 'Compare: 7 ___ 3',
 ARRAY['>','<','='], 0,
 '⭐⭐⭐⭐⭐⭐⭐  |  ⭐⭐⭐',
 'Đếm ngôi sao bên trái và bên phải, bên nào nhiều hơn?', 'Count stars on left and right, which side has more?',
 1),
('ex_n3_02', 'lesson_n3',
 'Số nào nhỏ hơn 10?', 'Which number is smaller than 10?',
 ARRAY['12','9','11'], 1,
 '🔢',
 'Nhớ: 9 đứng trước 10!', 'Remember: 9 comes before 10!',
 2),
('ex_n4_01', 'lesson_n4',
 '3 + 5 = ?', '3 + 5 = ?',
 ARRAY['7','8','9'], 1,
 '🍎🍎🍎  +  🍎🍎🍎🍎🍎',
 'Đếm tất cả quả táo lại với nhau!', 'Count all apples together!',
 1),
('ex_n4_02', 'lesson_n4',
 '2 + 7 = ?', '2 + 7 = ?',
 ARRAY['8','9','10'], 1,
 '⭐⭐ + ⭐⭐⭐⭐⭐⭐⭐',
 'Bắt đầu từ 7, đếm thêm 2 bước.', 'Start from 7, count forward 2 steps.',
 2),
('ex_n4_03', 'lesson_n4',
 '4 + 4 = ?', '4 + 4 = ?',
 ARRAY['7','8','9'], 1,
 '🐸🐸🐸🐸 + 🐸🐸🐸🐸',
 'Hai nhóm bằng nhau, gấp đôi lên!', 'Two equal groups, double it!',
 3),
('ex_n5_01', 'lesson_n5',
 '7 – 3 = ?', '7 – 3 = ?',
 ARRAY['3','4','5'], 1,
 '🍎🍎🍎🍎🍎🍎🍎  (❌🍎🍎🍎)',
 'Có 7 quả, bỏ đi 3 quả, còn bao nhiêu?', 'Start with 7, take away 3, how many left?',
 1),
('ex_n5_02', 'lesson_n5',
 '9 – 4 = ?', '9 – 4 = ?',
 ARRAY['4','5','6'], 1,
 '⭐⭐⭐⭐⭐⭐⭐⭐⭐  (-⭐⭐⭐⭐)',
 'Đếm ngược từ 9: 9, 8, 7, 6, 5!', 'Count backwards from 9: 9, 8, 7, 6, 5!',
 2);

INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty) VALUES
('lesson_g1', 'geometry', 'Nhận biết hình tròn',        'Recognize circles',       1, 1),
('lesson_g2', 'geometry', 'Nhận biết hình vuông',       'Recognize squares',       2, 1),
('lesson_g3', 'geometry', 'Nhận biết hình tam giác',    'Recognize triangles',     3, 1);

INSERT INTO exercises (id, lesson_id, question_vi, question_en, options, correct_index, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_g1_01', 'lesson_g1',
 'Hình nào là hình tròn?', 'Which shape is a circle?',
 ARRAY['Tam giác','Hình tròn','Hình vuông'], 1,
 '🔺 🔴 ⬜',
 'Hình tròn tròn trịa, không có góc cạnh!', 'A circle is round with no corners!',
 1),
('ex_g2_01', 'lesson_g2',
 'Hình nào có 4 cạnh bằng nhau?', 'Which shape has 4 equal sides?',
 ARRAY['Hình chữ nhật','Hình tam giác','Hình vuông'], 2,
 '⬜ 🔺 📏',
 'Hình vuông có 4 cạnh giống hệt nhau!', 'A square has 4 identical sides!',
 1),
('ex_g3_01', 'lesson_g3',
 'Hình nào có 3 cạnh?', 'Which shape has 3 sides?',
 ARRAY['Hình vuông','Hình tròn','Hình tam giác'], 2,
 '⬜ 🔴 🔺',
 'Tam giác có 3 cạnh và 3 góc!', 'A triangle has 3 sides and 3 corners!',
 1);

INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty) VALUES
('lesson_m1', 'measurement', 'So sánh dài ngắn',             'Compare length',         1, 1),
('lesson_m2', 'measurement', 'So sánh nặng nhẹ',             'Compare weight',         2, 1),
('lesson_m3', 'measurement', 'Nhận biết thời gian cơ bản', 'Basic time telling',     3, 1);

INSERT INTO exercises (id, lesson_id, question_vi, question_en, options, correct_index, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_m1_01', 'lesson_m1',
 'Cây bút nào dài hơn?', 'Which pencil is longer?',
 ARRAY['Bút ngắn ✏️','Bút dài 📏','Bằng nhau'], 1,
 '✏️  |  📏',
 'Nhìn kỹ, cây nào vươn dài hơn?', 'Look closely, which one stretches further?',
 1),
('ex_m2_01', 'lesson_m2',
 'Vật nào nặng hơn?', 'Which object is heavier?',
 ARRAY['Bóng bay 🎈','Quả táo 🍎','Bằng nhau'], 1,
 '🎈  |  🍎',
 'Bóng bay bay lên trời, quả táo rơi xuống đất!', 'Balloons float, apples fall down!',
 1),
('ex_m3_01', 'lesson_m3',
 'Kim đồng hồ chỉ mấy giờ? 🕐', 'What time does the clock show? 🕐',
 ARRAY['1 giờ','12 giờ','6 giờ'], 0,
 '🕐',
 'Kim ngắn chỉ số, kim dài chỉ phút!', 'Short hand points to the hour!',
 1);

INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty) VALUES
('lesson_l1', 'logic', 'Tìm quy luật số',       'Number patterns',       1, 1),
('lesson_l2', 'logic', 'Phân loại hình',        'Shape sorting',         2, 1),
('lesson_l3', 'logic', 'Sắp xếp theo thứ tự',   'Ordering',              3, 1);

INSERT INTO exercises (id, lesson_id, question_vi, question_en, options, correct_index, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_l1_01', 'lesson_l1',
 'Số tiếp theo: 2, 4, 6, ...?', 'Next number: 2, 4, 6, ...?',
 ARRAY['7','8','9'], 1,
 '🔢',
 'Cộng thêm 2 mỗi lần: 2+2=4, 4+2=6, 6+2=?', 'Add 2 each time: 2+2=4, 4+2=6, 6+2=?',
 1),
('ex_l1_02', 'lesson_l1',
 'Số tiếp theo: 1, 3, 5, ...?', 'Next number: 1, 3, 5, ...?',
 ARRAY['6','7','8'], 1,
 '🔢',
 'Cộng thêm 2: 1+2=3, 3+2=5, 5+2=?', 'Add 2: 1+2=3, 3+2=5, 5+2=?',
 2),
('ex_l2_01', 'lesson_l2',
 'Hình nào khác loại?', 'Which shape does not belong?',
 ARRAY['🟢','🔵','🔺'], 2,
 '🟢 🔵 ⭐ 🔺',
 'Tìm hình có số cạnh khác biệt!', 'Find the shape with a different number of sides!',
 1),
('ex_l3_01', 'lesson_l3',
 'Sắp xếp nhỏ đến lớn: 3, 1, 2', 'Arrange small to big: 3, 1, 2',
 ARRAY['1, 2, 3','3, 2, 1','2, 3, 1'], 0,
 '🔢',
 'Đếm: 1 là nhỏ nhất, kế tiếp là 2, lớn nhất là 3!', 'Count: 1 is smallest, then 2, then 3 is biggest!',
 1);
