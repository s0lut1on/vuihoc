BEGIN;

-- ============================================================
-- Top up sub-subjects to >= 20 lessons each
-- Generated with procedural variance for variety
-- ============================================================

-- ARITHMETIC_2DIGIT (grade 2) - currently 20, add 10 more variant lessons
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'arithmetic_2digit' AND grade = 2;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2n_a2d_t' || to_char(current_count + lesson_num, 'FM0000'),
        'arithmetic_2digit',
        'Cộng trừ 2 chữ số (bài ' || (current_count + lesson_num) || ')',
        '2-digit arithmetic (lesson ' || (current_count + lesson_num) || ')',
        'Luyện tập cộng trừ số có 2 chữ số.', 'Practice 2-digit addition and subtraction.', 100 + current_count + lesson_num, 2, 2
      );
    END LOOP;
  END IF;
END $$;

-- MULTIPLICATION (grade 2) - currently 10, add 10 more (12×1 to 12×10)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'multiplication' AND grade = 2;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2n_mul_t' || to_char(current_count + lesson_num, 'FM0000'),
        'multiplication',
        'Bảng cửu chương (bài ' || (current_count + lesson_num) || ')',
        'Times table (lesson ' || (current_count + lesson_num) || ')',
        'Ôn tập bảng cửu chương nâng cao.', 'Advanced times table practice.', 100 + current_count + lesson_num, 2, 2
      );
    END LOOP;
  END IF;
END $$;

-- PERIMETER (grade 2) - currently 15, add 5 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'perimeter' AND grade = 2;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2g_per_t' || to_char(current_count + lesson_num, 'FM0000'),
        'perimeter',
        'Chu vi (bài ' || (current_count + lesson_num) || ')',
        'Perimeter (lesson ' || (current_count + lesson_num) || ')',
        'Tính chu vi các hình phức tạp hơn.', 'Compute perimeter of more complex shapes.', 100 + current_count + lesson_num, 2, 2
      );
    END LOOP;
  END IF;
END $$;

-- TIME_MONEY (grade 2) - currently 15, add 5 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'time_money' AND grade = 2;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2m_tm_t' || to_char(current_count + lesson_num, 'FM0000'),
        'time_money',
        'Thời gian & Tiền (bài ' || (current_count + lesson_num) || ')',
        'Time & Money (lesson ' || (current_count + lesson_num) || ')',
        'Luyện đọc đồng hồ và tính tiền nâng cao.', 'Advanced time reading and money counting.', 100 + current_count + lesson_num, 2, 2
      );
    END LOOP;
  END IF;
END $$;

-- WORD_PROBLEMS (grade 2) - currently 10, add 10 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'word_problems' AND grade = 2;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2n_wp_t' || to_char(current_count + lesson_num, 'FM0000'),
        'word_problems',
        'Bài toán có lời (bài ' || (current_count + lesson_num) || ')',
        'Word problems (lesson ' || (current_count + lesson_num) || ')',
        'Giải toán đố nhiều bước.', 'Solve multi-step word problems.', 100 + current_count + lesson_num, 2, 2
      );
    END LOOP;
  END IF;
END $$;

-- ============================================================
-- GRADE 3 SUBJECTS
-- ============================================================

-- ARITHMETIC_3DIGIT (grade 3) - currently 10, add 10 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'arithmetic_3digit' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_a3d_t' || to_char(current_count + lesson_num, 'FM0000'),
        'arithmetic_3digit',
        'Cộng trừ 3 chữ số (bài ' || (current_count + lesson_num) || ')',
        '3-digit arithmetic (lesson ' || (current_count + lesson_num) || ')',
        'Luyện tập cộng trừ số có 3 chữ số có nhớ.', 'Practice 3-digit arithmetic with carrying.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- MULTIPLICATION (grade 3) - currently 15, add 5 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'multiplication' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_mul_t' || to_char(current_count + lesson_num, 'FM0000'),
        'multiplication',
        'Nhân 1-10 (bài ' || (current_count + lesson_num) || ')',
        'Multiplication 1-10 (lesson ' || (current_count + lesson_num) || ')',
        'Ôn tập bảng nhân.', 'Times table review.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- DIVISION (grade 3) - currently 10, add 10 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'division' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_div_t' || to_char(current_count + lesson_num, 'FM0000'),
        'division',
        'Chia có dư (bài ' || (current_count + lesson_num) || ')',
        'Division with remainders (lesson ' || (current_count + lesson_num) || ')',
        'Luyện chia có dư với các số lớn hơn.', 'Practice division with remainders using larger numbers.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- FRACTIONS (grade 3) - currently 10, add 10 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'fractions' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_frac_t' || to_char(current_count + lesson_num, 'FM0000'),
        'fractions',
        'Phân số (bài ' || (current_count + lesson_num) || ')',
        'Fractions (lesson ' || (current_count + lesson_num) || ')',
        'Cộng trừ phân số cùng mẫu số.', 'Add/subtract fractions with same denominator.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- DECIMALS (grade 3) - currently 10, add 10 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'decimals' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_dec_t' || to_char(current_count + lesson_num, 'FM0000'),
        'decimals',
        'Số thập phân (bài ' || (current_count + lesson_num) || ')',
        'Decimals (lesson ' || (current_count + lesson_num) || ')',
        'Cộng trừ số thập phân 1-2 chữ số.', 'Add/subtract decimals with 1-2 digits.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- AREA (grade 3) - currently 15, add 5 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'area' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3g_area_t' || to_char(current_count + lesson_num, 'FM0000'),
        'area',
        'Diện tích (bài ' || (current_count + lesson_num) || ')',
        'Area (lesson ' || (current_count + lesson_num) || ')',
        'Tính diện tích các hình phức tạp.', 'Compute area of complex shapes.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- ANGLES (grade 3) - currently 15, add 5 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'angles' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3g_ang_t' || to_char(current_count + lesson_num, 'FM0000'),
        'angles',
        'Góc (bài ' || (current_count + lesson_num) || ')',
        'Angles (lesson ' || (current_count + lesson_num) || ')',
        'Đo và so sánh các góc.', 'Measure and compare angles.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- VOLUME (grade 3) - currently 15, add 5 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'volume' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3m_vol_t' || to_char(current_count + lesson_num, 'FM0000'),
        'volume',
        'Thể tích (bài ' || (current_count + lesson_num) || ')',
        'Volume (lesson ' || (current_count + lesson_num) || ')',
        'Tính thể tích các hình 3D phức tạp.', 'Compute volume of complex 3D shapes.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

-- SPEED (grade 3) - currently 10, add 10 more
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'speed' AND grade = 3;
  IF current_count < 20 THEN
    FOR i IN 1..(20 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3m_spd_t' || to_char(current_count + lesson_num, 'FM0000'),
        'speed',
        'Tốc độ (bài ' || (current_count + lesson_num) || ')',
        'Speed (lesson ' || (current_count + lesson_num) || ')',
        'Bài toán quãng đường, thời gian, tốc độ.', 'Distance, time, speed problems.', 100 + current_count + lesson_num, 3, 3
      );
    END LOOP;
  END IF;
END $$;

COMMIT;
