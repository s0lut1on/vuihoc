BEGIN;

DELETE FROM language_exercises WHERE lesson_id LIKE 'vn_%';
DELETE FROM language_lessons WHERE subject_id = 'vietnamese';
DELETE FROM language_subjects WHERE id = 'vietnamese';

INSERT INTO language_subjects (id, name_vi, name_en, icon, color, display_order, target_language)
VALUES ('vietnamese', 'Tiếng Việt', 'Vietnamese', '🇻🇳', '#FFEBEE', 1, 'vi');

-- ===== U1: Bảng chữ cái (Letters 1-10) =====
INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('vn_l01', 'vietnamese', 'Chữ cái a, ă, â',      'Letters a, ă, â',      'Học 3 chữ cái đầu tiên.', 'Learn the first 3 letters.', 1, 1),
('vn_l02', 'vietnamese', 'Chữ cái e, ê, i',      'Letters e, ê, i',      'Học 3 chữ cái tiếp theo.', 'Learn the next 3 letters.', 2, 1),
('vn_l03', 'vietnamese', 'Chữ cái o, ô, ơ',     'Letters o, ô, ơ',      'Học 3 chữ cái tiếp theo.', 'Learn the next 3 letters.', 3, 1),
('vn_l04', 'vietnamese', 'Chữ cái u, ư, y',     'Letters u, ư, y',      'Học 3 chữ cái tiếp theo.', 'Learn the next 3 letters.', 4, 1),
('vn_l05', 'vietnamese', 'Chữ cái b, c, d',     'Letters b, c, d',      'Học các phụ âm đầu.', 'Learn first consonants.', 5, 1),
('vn_l06', 'vietnamese', 'Chữ cái đ, g, h',     'Letters đ, g, h',      'Học các phụ âm tiếp.', 'Learn more consonants.', 6, 1),
('vn_l07', 'vietnamese', 'Chữ cái k, l, m',     'Letters k, l, m',      'Học các phụ âm tiếp.', 'Learn more consonants.', 7, 1),
('vn_l08', 'vietnamese', 'Chữ cái n, p, q',     'Letters n, p, q',      'Học các phụ âm tiếp.', 'Learn more consonants.', 8, 1),
('vn_l09', 'vietnamese', 'Chữ cái r, s, t',     'Letters r, s, t',      'Học các phụ âm tiếp.', 'Learn more consonants.', 9, 1),
('vn_l10', 'vietnamese', 'Chữ cái v, x',        'Letters v, x',         'Học các phụ âm cuối.', 'Learn last consonants.', 10, 1);

-- U1 exercises: mostly typing (type the letter shown) + audio_mcq (listen and pick)
INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn01_t1', 'vn_l01', 'typing', 'Chữ gì đây? 🔤', 'What letter is this?', ARRAY[]::TEXT[], 0, 'a', 'exact', false, true, '🔤', 'Nhập chữ cái bạn nhìn thấy.', 'Type the letter you see.', 1),
('ex_vn01_t2', 'vn_l01', 'typing', 'Chữ gì đây? 🔤', 'What letter is this?', ARRAY[]::TEXT[], 0, 'ă', 'exact', false, true, '🔤', 'Nhập chữ cái có dấu mũ.', 'Type the letter with a hat.', 2),
('ex_vn01_t3', 'vn_l01', 'typing', 'Chữ gì đây? 🔤', 'What letter is this?', ARRAY[]::TEXT[], 0, 'â', 'exact', false, true, '🔤', 'Nhập chữ cái có dấu mũ.', 'Type the letter with a hat.', 3),
('ex_vn01_m1', 'vn_l01', 'audio_mcq', 'Chọn chữ cái "a"', 'Choose the letter "a"', ARRAY['ă', 'a', 'â', 'e'], 1, NULL, 'exact', false, true, '', 'Chữ "a" không có dấu.', 'The letter "a" has no mark.', 4),
('ex_vn01_m2', 'vn_l01', 'audio_mcq', 'Chọn chữ cái "ă"', 'Choose the letter "ă"', ARRAY['a', 'ă', 'â', 'e'], 1, NULL, 'exact', false, true, '', 'Chữ "ă" có dấu mũ ngắn.', 'The letter "ă" has a short hat.', 5);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn02_t1', 'vn_l02', 'typing', 'Chữ gì đây? 🔤', 'What letter is this?', ARRAY[]::TEXT[], 0, 'e', 'exact', false, true, '🔤', 'Nhập chữ cái bạn nhìn thấy.', 'Type the letter you see.', 1),
('ex_vn02_t2', 'vn_l02', 'typing', 'Chữ gì đây? 🔤', 'What letter is this?', ARRAY[]::TEXT[], 0, 'ê', 'exact', false, true, '🔤', 'Chữ có dấu mũ dài.', 'Letter with a long hat.', 2),
('ex_vn02_t3', 'vn_l02', 'typing', 'Chữ gì đây? 🔤', 'What letter is this?', ARRAY[]::TEXT[], 0, 'i', 'exact', false, true, '🔤', 'Chữ có chấm trên.', 'Letter with a dot above.', 3),
('ex_vn02_m1', 'vn_l02', 'audio_mcq', 'Chọn chữ cái "ê"', 'Choose the letter "ê"', ARRAY['e', 'ê', 'i', 'o'], 1, NULL, 'exact', false, true, '', 'Chữ "ê" có dấu mũ dài.', 'The letter "ê" has a long hat.', 4),
('ex_vn02_m2', 'vn_l02', 'audio_mcq', 'Chọn chữ cái "i"', 'Choose the letter "i"', ARRAY['e', 'ê', 'i', 'y'], 2, NULL, 'exact', false, true, '', 'Chữ "i" có chấm trên.', 'The letter "i" has a dot above.', 5);

-- ... continue U1-U5 ...

-- ===== U2: Ghép vần (Syllables 11-20) =====
INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('vn_l11', 'vietnamese', 'Vần ba, be, bi',      'Syllables ba, be, bi',     'Ghép phụ âm b với nguyên âm.', 'Consonant b + vowels.', 11, 1),
('vn_l12', 'vietnamese', 'Vần bo, bô, bơ',      'Syllables bo, bô, bơ',     'Ghép phụ âm b với nguyên âm.', 'Consonant b + vowels.', 12, 1),
('vn_l13', 'vietnamese', 'Vần ca, ce, ci',      'Syllables ca, ce, ci',     'Ghép phụ âm c.', 'Consonant c + vowels.', 13, 1),
('vn_l14', 'vietnamese', 'Vần co, cô, cơ',      'Syllables co, cô, cơ',     'Ghép phụ âm c.', 'Consonant c + vowels.', 14, 1),
('vn_l15', 'vietnamese', 'Vần da, de, di',      'Syllables da, de, di',     'Ghép phụ âm d.', 'Consonant d + vowels.', 15, 1),
('vn_l16', 'vietnamese', 'Vần do, dô, dơ',      'Syllables do, dô, dơ',     'Ghép phụ âm d.', 'Consonant d + vowels.', 16, 1),
('vn_l17', 'vietnamese', 'Vần đa, đe, đi',      'Syllables đa, đe, đi',     'Ghép phụ âm đ.', 'Consonant đ + vowels.', 17, 1),
('vn_l18', 'vietnamese', 'Vần đo, đô, đơ',      'Syllables đo, đô, đơ',     'Ghép phụ âm đ.', 'Consonant đ + vowels.', 18, 1),
('vn_l19', 'vietnamese', 'Vần ga, ge, gi',      'Syllables ga, ge, gi',     'Ghép phụ âm g.', 'Consonant g + vowels.', 19, 1),
('vn_l20', 'vietnamese', 'Vần go, gô, gơ',      'Syllables go, gô, gơ',     'Ghép phụ âm g.', 'Consonant g + vowels.', 20, 1);

-- U2 exercises: typing syllables + audio_mcq
INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn11_t1', 'vn_l11', 'typing', 'Ghép vần: b + a = ?', 'Syllable: b + a = ?', ARRAY[]::TEXT[], 0, 'ba', 'exact', false, true, '', 'Viết liền hai chữ.', 'Write the two letters together.', 1),
('ex_vn11_t2', 'vn_l11', 'typing', 'Ghép vần: b + e = ?', 'Syllable: b + e = ?', ARRAY[]::TEXT[], 0, 'be', 'exact', false, true, '', 'Viết liền hai chữ.', 'Write the two letters together.', 2),
('ex_vn11_m1', 'vn_l11', 'audio_mcq', 'Chọn vần "bi"', 'Choose syllable "bi"', ARRAY['ba', 'be', 'bi', 'bo'], 2, NULL, 'exact', false, true, '', 'Vần có chữ i.', 'Syllable with letter i.', 3),
('ex_vn11_m2', 'vn_l11', 'audio_mcq', 'Chọn vần "ba"', 'Choose syllable "ba"', ARRAY['be', 'bi', 'ba', 'bô'], 2, NULL, 'exact', false, true, '', 'Vần có chữ a.', 'Syllable with letter a.', 4);

-- ===== U3: Từ đơn giản (Words 21-30) =====
INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('vn_l21', 'vietnamese', 'Từ: mèo, chó, chim', 'Words: cat, dog, bird', 'Học tên con vật.', 'Learn animal names.', 21, 1),
('vn_l22', 'vietnamese', 'Từ: táo, cam, chuối', 'Words: apple, orange, banana', 'Học tên quả.', 'Learn fruit names.', 22, 1),
('vn_l23', 'vietnamese', 'Từ: bố, mẹ, bé', 'Words: dad, mom, baby', 'Học tên gia đình.', 'Learn family names.', 23, 1),
('vn_l24', 'vietnamese', 'Từ: nhà, trường, cây', 'Words: house, school, tree', 'Học tên đồ vật.', 'Learn object names.', 24, 1),
('vn_l25', 'vietnamese', 'Từ: đỏ, xanh, vàng', 'Words: red, blue, yellow', 'Học tên màu.', 'Learn color names.', 25, 1),
('vn_l26', 'vietnamese', 'Từ: một, hai, ba', 'Words: one, two, three', 'Học đếm số.', 'Learn counting words.', 26, 1),
('vn_l27', 'vietnamese', 'Từ: lớn, nhỏ, cao', 'Words: big, small, tall', 'Học tính từ.', 'Learn adjectives.', 27, 2),
('vn_l28', 'vietnamese', 'Từ: chạy, bơi, bay', 'Words: run, swim, fly', 'Học động từ.', 'Learn verbs.', 28, 2),
('vn_l29', 'vietnamese', 'Từ: dưới, trên, trong', 'Words: under, on, in', 'Học giới từ.', 'Learn prepositions.', 29, 2),
('vn_l30', 'vietnamese', 'Từ: vui, buồn, giận', 'Words: happy, sad, angry', 'Học cảm xúc.', 'Learn emotions.', 30, 2);

-- U3 exercises: mcq_image (emoji visual) + typing
INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn21_m1', 'vn_l21', 'audio_mcq', 'Con gì đây?', 'What animal is this?', ARRAY['Chó', 'Mèo', 'Chim', 'Cá'], 1, NULL, 'exact', false, true, '🐱', 'Con vật này kêu meo meo.', 'This animal says meow.', 1),
('ex_vn21_m2', 'vn_l21', 'audio_mcq', 'Con gì đây?', 'What animal is this?', ARRAY['Mèo', 'Chó', 'Chim', 'Cá'], 1, NULL, 'exact', false, true, '🐶', 'Con vật này kêu gâu gâu.', 'This animal says woof woof.', 2),
('ex_vn21_t1', 'vn_l21', 'typing', 'Viết từ: con 🐱', 'Write the word: 🐱', ARRAY[]::TEXT[], 0, 'mèo', 'exact', false, true, '🐱', 'Con vật này kêu meo meo.', 'This animal says meow.', 3),
('ex_vn21_t2', 'vn_l21', 'typing', 'Viết từ: con 🐶', 'Write the word: 🐶', ARRAY[]::TEXT[], 0, 'chó', 'exact', false, true, '🐶', 'Con vật này kêu gâu gâu.', 'This animal says woof woof.', 4);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn22_m1', 'vn_l22', 'audio_mcq', 'Quả gì đây?', 'What fruit is this?', ARRAY['Táo', 'Cam', 'Chuối', 'Nho'], 0, NULL, 'exact', false, true, '🍎', 'Quả này màu đỏ.', 'This fruit is red.', 1),
('ex_vn22_t1', 'vn_l22', 'typing', 'Viết từ: 🍎', 'Write the word: 🍎', ARRAY[]::TEXT[], 0, 'táo', 'exact', false, true, '🍎', 'Quả này màu đỏ.', 'This fruit is red.', 2),
('ex_vn22_t2', 'vn_l22', 'typing', 'Viết từ: 🍌', 'Write the word: 🍌', ARRAY[]::TEXT[], 0, 'chuối', 'exact', false, true, '🍌', 'Quả này màu vàng, dài.', 'This fruit is yellow and long.', 3);

-- ... more U3 exercises would follow same pattern ...

-- ===== U4: Câu đơn giản (Sentences 31-38) =====
INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('vn_l31', 'vietnamese', 'Câu: Con ___ bơi', 'Sentence: The ___ swims', 'Điền từ vào câu.', 'Fill in the blank.', 31, 2),
('vn_l32', 'vietnamese', 'Câu: Bé ___ đến trường', 'Sentence: The child ___ to school', 'Điền động từ.', 'Fill in the verb.', 32, 2),
('vn_l33', 'vietnamese', 'Câu: Quả ___ màu đỏ', 'Sentence: The ___ is red', 'Điền tên quả.', 'Fill in the fruit.', 33, 2),
('vn_l34', 'vietnamese', 'Câu: ___ là bố của bé', 'Sentence: ___ is the father', 'Điền tên người.', 'Fill in the person.', 34, 2),
('vn_l35', 'vietnamese', 'Câu: Con mèo kêu ___', 'Sentence: The cat says ___', 'Điền tiếng kêu.', 'Fill in the sound.', 35, 2),
('vn_l36', 'vietnamese', 'Câu: Trời hôm nay ___', 'Sentence: Today the sky is ___', 'Điền tính từ.', 'Fill in the adjective.', 36, 2),
('vn_l37', 'vietnamese', 'Câu: Bé thích ăn ___', 'Sentence: The child likes to eat ___', 'Điền tên quả.', 'Fill in the fruit.', 37, 2),
('vn_l38', 'vietnamese', 'Câu: Con chó chạy ___', 'Sentence: The dog runs ___', 'Điền tính từ.', 'Fill in the adjective.', 38, 2);

-- U4 exercises: typing sentence completion + audio_mcq with full sentences
INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn31_t1', 'vn_l31', 'typing', 'Con ___ bơi dưới nước.', 'The ___ swims in water.', ARRAY[]::TEXT[], 0, 'cá', 'exact', false, true, '🐟', 'Con vật sống dưới nước.', 'Animal that lives in water.', 1),
('ex_vn31_m1', 'vn_l31', 'audio_mcq', 'Chọn câu đúng:', 'Choose the correct sentence:', ARRAY['Con mèo bơi.', 'Con cá bơi.', 'Con chim bơi.', 'Con chó bơi.'], 1, NULL, 'exact', false, true, '🐟', 'Con nào sống dưới nước?', 'Which animal lives in water?', 2);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn32_t1', 'vn_l32', 'typing', 'Bé ___ đến trường.', 'The child ___ to school.', ARRAY[]::TEXT[], 0, 'đi', 'exact', false, true, '🏫', 'Bé đi bộ đến trường.', 'The child walks to school.', 1),
('ex_vn32_m1', 'vn_l32', 'audio_mcq', 'Chọn câu đúng:', 'Choose the correct sentence:', ARRAY['Bé bay đến trường.', 'Bé bơi đến trường.', 'Bé đi đến trường.', 'Bé chạy đến trường.'], 2, NULL, 'exact', false, true, '🏫', 'Câu thông thường nhất.', 'The most common sentence.', 2);

-- ===== U5: Đọc hiểu mini (Reading 39-40) =====
INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('vn_l39', 'vietnamese', 'Đọc hiểu: Con vật', 'Reading: Animals', 'Đọc và trả lời câu hỏi.', 'Read and answer questions.', 39, 2),
('vn_l40', 'vietnamese', 'Đọc hiểu: Gia đình', 'Reading: Family', 'Đọc và trả lời câu hỏi.', 'Read and answer questions.', 40, 2);

-- U5 exercises: short passage + audio_mcq comprehension
INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_vn39_m1', 'vn_l39', 'audio_mcq', 'Con mèo kêu meo meo. Con mèo thích ăn cá. Con mèo có màu trắng. Câu hỏi: Con mèo thích ăn gì?', 'The cat says meow. The cat likes to eat fish. The cat is white. Question: What does the cat like to eat?', ARRAY['Chó', 'Cá', 'Chim', 'Chuối'], 1, NULL, 'exact', false, true, '📖', 'Đọc câu thứ hai.', 'Read the second sentence.', 1),
('ex_vn39_m2', 'vn_l39', 'audio_mcq', 'Con mèo kêu meo meo. Con mèo thích ăn cá. Con mèo có màu trắng. Câu hỏi: Con mèo có màu gì?', 'The cat says meow. The cat likes to eat fish. The cat is white. Question: What color is the cat?', ARRAY['Đen', 'Trắng', 'Vàng', 'Nâu'], 1, NULL, 'exact', false, true, '📖', 'Đọc câu thứ ba.', 'Read the third sentence.', 2),
('ex_vn39_t1', 'vn_l39', 'typing', 'Viết lại từ: Con mèo kêu ___', 'Write the missing word: The cat says ___', ARRAY[]::TEXT[], 0, 'meo meo', 'exact', false, true, '🐱', 'Tiếng kêu của mèo.', 'The sound a cat makes.', 3);

COMMIT;
