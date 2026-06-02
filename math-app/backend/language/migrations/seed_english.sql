BEGIN;

DELETE FROM language_exercises WHERE lesson_id LIKE 'en_%';
DELETE FROM language_lessons WHERE subject_id = 'english';
DELETE FROM language_subjects WHERE id = 'english';

INSERT INTO language_subjects (id, name_vi, name_en, icon, color, display_order, target_language)
VALUES ('english', 'Tiếng Anh', 'English', '🇬🇧', '#E8EAF6', 2, 'en');

INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('en_l01', 'english', 'A, B, C',                  'A, B, C',                  'Learn the first 3 letters.', 'Learn the first 3 letters.', 1, 1),
('en_l02', 'english', 'D, E, F',                  'D, E, F',                  'Learn the next 3 letters.', 'Learn the next 3 letters.', 2, 1),
('en_l03', 'english', 'G, H, I',                  'G, H, I',                  'Learn the next 3 letters.', 'Learn the next 3 letters.', 3, 1),
('en_l04', 'english', 'J, K, L',                  'J, K, L',                  'Learn the next 3 letters.', 'Learn the next 3 letters.', 4, 1),
('en_l05', 'english', 'M, N, O',                  'M, N, O',                  'Learn the next 3 letters.', 'Learn the next 3 letters.', 5, 1),
('en_l06', 'english', 'P, Q, R',                  'P, Q, R',                  'Learn the next 3 letters.', 'Learn the next 3 letters.', 6, 1),
('en_l07', 'english', 'S, T, U',                  'S, T, U',                  'Learn the next 3 letters.', 'Learn the next 3 letters.', 7, 1),
('en_l08', 'english', 'V, W, X',                  'V, W, X',                  'Learn the next 3 letters.', 'Learn the next 3 letters.', 8, 1),
('en_l09', 'english', 'Y, Z',                     'Y, Z',                     'Learn the last 2 letters.', 'Learn the last 2 letters.', 9, 1),
('en_l10', 'english', 'Chữ hoa và chữ thường',     'Uppercase and lowercase',   'Phân biệt chữ hoa, chữ thường.', 'Tell uppercase from lowercase.', 10, 1);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_en01_t1', 'en_l01', 'typing', 'What letter is this? 🔤', 'What letter is this? 🔤', ARRAY[]::TEXT[], 0, 'A', 'exact', true, true, '🔤', 'Type the uppercase letter.', 'Type the uppercase letter.', 1),
('ex_en01_t2', 'en_l01', 'typing', 'What letter is this? 🔤', 'What letter is this? 🔤', ARRAY[]::TEXT[], 0, 'B', 'exact', true, true, '🔤', 'Type the uppercase letter.', 'Type the uppercase letter.', 2),
('ex_en01_t3', 'en_l01', 'typing', 'What letter is this? 🔤', 'What letter is this? 🔤', ARRAY[]::TEXT[], 0, 'C', 'exact', true, true, '🔤', 'Type the uppercase letter.', 'Type the uppercase letter.', 3),
('ex_en01_m1', 'en_l01', 'audio_mcq', 'Choose the letter "A"', 'Choose the letter "A"', ARRAY['B', 'A', 'C', 'D'], 1, NULL, 'exact', false, true, '', 'The first letter of the alphabet.', 'The first letter of the alphabet.', 4),
('ex_en01_m2', 'en_l01', 'audio_mcq', 'Choose the letter "B"', 'Choose the letter "B"', ARRAY['A', 'C', 'B', 'D'], 2, NULL, 'exact', false, true, '', 'The letter that sounds like "bee".', 'The letter that sounds like "bee".', 5);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_en10_t1', 'en_l10', 'typing', '"a" viết hoa là?', '"a" uppercase is?', ARRAY[]::TEXT[], 0, 'A', 'exact', true, true, '', 'Chữ lớn hơn.', 'The bigger letter.', 1),
('ex_en10_t2', 'en_l10', 'typing', '"b" viết hoa là?', '"b" uppercase is?', ARRAY[]::TEXT[], 0, 'B', 'exact', true, true, '', 'Chữ lớn hơn.', 'The bigger letter.', 2),
('ex_en10_m1', 'en_l10', 'audio_mcq', 'Match: chữ thường "m" → chữ hoa?', 'Match: lowercase "m" → uppercase?', ARRAY['M', 'N', 'W', 'V'], 0, NULL, 'exact', false, true, '', 'Chữ hoa giống hình chữ thường.', 'Uppercase looks like lowercase.', 3);

INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('en_l11', 'english', 'Âm /a/', 'Sound /a/', 'Short vowel a.', 'Short vowel a.', 11, 1),
('en_l12', 'english', 'Âm /e/', 'Sound /e/', 'Short vowel e.', 'Short vowel e.', 12, 1),
('en_l13', 'english', 'Âm /i/', 'Sound /i/', 'Short vowel i.', 'Short vowel i.', 13, 1),
('en_l14', 'english', 'Âm /o/', 'Sound /o/', 'Short vowel o.', 'Short vowel o.', 14, 1),
('en_l15', 'english', 'Âm /u/', 'Sound /u/', 'Short vowel u.', 'Short vowel u.', 15, 1),
('en_l16', 'english', 'Từ CVC: cat, bat', 'CVC words: cat, bat', 'Consonant-vowel-consonant.', 'Consonant-vowel-consonant.', 16, 1),
('en_l17', 'english', 'Từ CVC: dog, log', 'CVC words: dog, log', 'Consonant-vowel-consonant.', 'Consonant-vowel-consonant.', 17, 1),
('en_l18', 'english', 'Từ CVC: sun, run', 'CVC words: sun, run', 'Consonant-vowel-consonant.', 'Consonant-vowel-consonant.', 18, 1);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_en11_m1', 'en_l11', 'audio_mcq', 'Which word has sound /a/?', 'Which word has sound /a/?', ARRAY['cat', 'bed', 'pig', 'dog'], 0, NULL, 'exact', false, true, '', 'cat has /a/.', 'cat has /a/.', 1),
('ex_en11_t1', 'en_l11', 'typing', 'Type the word: 🐱', 'Type the word: 🐱', ARRAY[]::TEXT[], 0, 'cat', 'exact', false, true, '🐱', 'Animal that says meow.', 'Animal that says meow.', 2),
('ex_en16_t1', 'en_l16', 'typing', 'Type the word: 🦇', 'Type the word: 🦇', ARRAY[]::TEXT[], 0, 'bat', 'exact', false, true, '🦇', 'Animal that flies at night.', 'Animal that flies at night.', 1),
('ex_en16_m1', 'en_l16', 'audio_mcq', 'Choose the word "bat"', 'Choose the word "bat"', ARRAY['cat', 'bat', 'rat', 'hat'], 1, NULL, 'exact', false, true, '', 'Animal that flies.', 'Animal that flies.', 2);

INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('en_l19', 'english', 'Sight words: the, is', 'Sight words: the, is', 'High-frequency words.', 'High-frequency words.', 19, 1),
('en_l20', 'english', 'Sight words: a, I', 'Sight words: a, I', 'High-frequency words.', 'High-frequency words.', 20, 1),
('en_l21', 'english', 'Sight words: you, my', 'Sight words: you, my', 'High-frequency words.', 'High-frequency words.', 21, 1),
('en_l22', 'english', 'Sight words: and, to', 'Sight words: and, to', 'High-frequency words.', 'High-frequency words.', 22, 1),
('en_l23', 'english', 'Sight words: it, in', 'Sight words: it, in', 'High-frequency words.', 'High-frequency words.', 23, 1),
('en_l24', 'english', 'Sight words: on, at', 'Sight words: on, at', 'High-frequency words.', 'High-frequency words.', 24, 1),
('en_l25', 'english', 'Sight words: we, he', 'Sight words: we, he', 'High-frequency words.', 'High-frequency words.', 25, 1),
('en_l26', 'english', 'Sight words: she, they', 'Sight words: she, they', 'High-frequency words.', 'High-frequency words.', 26, 1);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_en19_t1', 'en_l19', 'typing', 'Type the word: "___ cat" (con mèo)', 'Type the word: "___ cat" (the cat)', ARRAY[]::TEXT[], 0, 'the', 'exact', false, true, '', 'Word used before a noun.', 'Word used before a noun.', 1),
('ex_en19_m1', 'en_l19', 'audio_mcq', 'Choose the word "the"', 'Choose the word "the"', ARRAY['a', 'is', 'the', 'I'], 2, NULL, 'exact', false, true, '', 'Used before cat, dog, sun.', 'Used before cat, dog, sun.', 2),
('ex_en20_t1', 'en_l20', 'typing', 'Type the word: "___ am a student"', 'Type the word: "___ am a student"', ARRAY[]::TEXT[], 0, 'I', 'exact', true, true, '', 'Word for yourself.', 'Word for yourself.', 1);

INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('en_l27', 'english', 'Câu: I am a ___', 'Sentence: I am a ___', 'Fill in the noun.', 'Fill in the noun.', 27, 2),
('en_l28', 'english', 'Câu: The ___ is red', 'Sentence: The ___ is red', 'Fill in the noun.', 'Fill in the noun.', 28, 2),
('en_l29', 'english', 'Câu: I like ___', 'Sentence: I like ___', 'Fill in the object.', 'Fill in the object.', 29, 2),
('en_l30', 'english', 'Câu: ___ is big', 'Sentence: ___ is big', 'Fill in the subject.', 'Fill in the subject.', 30, 2),
('en_l31', 'english', 'Câu: I can ___', 'Sentence: I can ___', 'Fill in the verb.', 'Fill in the verb.', 31, 2),
('en_l32', 'english', 'Câu: The cat ___', 'Sentence: The cat ___', 'Fill in the verb.', 'Fill in the verb.', 32, 2),
('en_l33', 'english', 'Câu: ___ run fast', 'Sentence: ___ run fast', 'Fill in the subject.', 'Fill in the subject.', 33, 2),
('en_l34', 'english', 'Câu: I see a ___', 'Sentence: I see a ___', 'Fill in the noun.', 'Fill in the noun.', 34, 2);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_en27_t1', 'en_l27', 'typing', 'I am a ___ 🐱', 'I am a ___ 🐱', ARRAY[]::TEXT[], 0, 'cat', 'exact', false, true, '🐱', 'Animal that says meow.', 'Animal that says meow.', 1),
('ex_en27_m1', 'en_l27', 'audio_mcq', 'Choose the correct sentence:', 'Choose the correct sentence:', ARRAY['I am a dog.', 'I am a cat.', 'I am a fish.', 'I am a bird.'], 1, NULL, 'exact', false, true, '🐱', 'Sentence with cat.', 'Sentence with cat.', 2),
('ex_en28_t1', 'en_l28', 'typing', 'The 🍎 is red', 'The 🍎 is red', ARRAY[]::TEXT[], 0, 'apple', 'exact', false, true, '🍎', 'Red fruit.', 'Red fruit.', 1);

INSERT INTO language_lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty) VALUES
('en_l35', 'english', 'Đọc hiểu: My Pet', 'Reading: My Pet', 'Read and answer.', 'Read and answer.', 35, 2),
('en_l36', 'english', 'Đọc hiểu: My Family', 'Reading: My Family', 'Read and answer.', 'Read and answer.', 36, 2),
('en_l37', 'english', 'Đọc hiểu: At School', 'Reading: At School', 'Read and answer.', 'Read and answer.', 37, 2),
('en_l38', 'english', 'Đọc hiểu: Colors', 'Reading: Colors', 'Read and answer.', 'Read and answer.', 38, 2),
('en_l39', 'english', 'Đọc hiểu: Animals', 'Reading: Animals', 'Read and answer.', 'Read and answer.', 39, 2),
('en_l40', 'english', 'Đọc hiểu: Food', 'Reading: Food', 'Read and answer.', 'Read and answer.', 40, 2);

INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, expected_text, validation_mode, case_sensitive, diacritic_sensitive, visual_asset, hint_vi, hint_en, exercise_order) VALUES
('ex_en35_m1', 'en_l35', 'audio_mcq', 'I have a dog. My dog is brown. My dog likes to run. What color is the dog?', 'I have a dog. My dog is brown. My dog likes to run. What color is the dog?', ARRAY['black', 'brown', 'white', 'red'], 1, NULL, 'exact', false, true, '📖', 'Read the second sentence.', 'Read the second sentence.', 1),
('ex_en35_t1', 'en_l35', 'typing', 'I have a ___ 🐶', 'I have a ___ 🐶', ARRAY[]::TEXT[], 0, 'dog', 'exact', false, true, '🐶', 'Animal that says woof.', 'Animal that says woof.', 2),
('ex_en36_m1', 'en_l36', 'audio_mcq', 'My mom is tall. My dad is tall too. I am small. Who is tall?', 'My mom is tall. My dad is tall too. I am small. Who is tall?', ARRAY['Mom', 'Dad', 'Mom and Dad', 'Me'], 2, NULL, 'exact', false, true, '📖', 'Two people are tall.', 'Two people are tall.', 1),
('ex_en37_m1', 'en_l37', 'audio_mcq', 'I go to school. I see a teacher. I see books. What do I see at school?', 'I go to school. I see a teacher. I see books. What do I see at school?', ARRAY['A cat', 'A teacher', 'A dog', 'A bird'], 1, NULL, 'exact', false, true, '📖', 'Read the second sentence.', 'Read the second sentence.', 1);

COMMIT;
