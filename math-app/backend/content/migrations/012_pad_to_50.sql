BEGIN;

-- ============================================================
-- Top up every (subject, grade) cell with lessons > 0 to >= 50
-- Generated 2026-07-10. 86 cells short -> 1935 new lessons.
-- Mirrors 008_topup_lessons.sql pattern: lessons only, no exercises.
-- ID prefix: g{grade}{abbr}_{sub_short}_top{NNNN} (avoids 008's _t*).
-- Re-runnable: each DO block re-counts before insert; ON CONFLICT (id) skip.
-- ============================================================

-- algebra grade 2: 15 -> 50 (add 35)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 3: 10 -> 50 (add 40)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 4: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 4;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g4a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 4)),
        4
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 5: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 5;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g5a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 5)),
        5
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 6: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 6;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g6a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 6)),
        6
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 7: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 7;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g7a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 7)),
        7
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 8: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 8;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g8a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 8)),
        8
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 9: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 9;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g9a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 9)),
        9
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 10: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 10;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g10a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 10)),
        10
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 11: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 11;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g11a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 11)),
        11
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- algebra grade 12: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'algebra' AND grade = 12;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g12a_algebr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'algebra',
        'Đại số (bài ' || (current_count + lesson_num) || ')',
        'Algebra (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đại số - biến thể nâng cao.', 'Supplementary Algebra practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 12)),
        12
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- angles grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'angles' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3g_angles_top' || to_char(current_count + lesson_num, 'FM0000'),
        'angles',
        'Góc (bài ' || (current_count + lesson_num) || ')',
        'Angles (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung góc - biến thể nâng cao.', 'Supplementary Angles practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- area grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'area' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3g_area_top' || to_char(current_count + lesson_num, 'FM0000'),
        'area',
        'Diện tích (bài ' || (current_count + lesson_num) || ')',
        'Area (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung diện tích - biến thể nâng cao.', 'Supplementary Area practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- arithmetic_2digit grade 2: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'arithmetic_2digit' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2n_arithm_top' || to_char(current_count + lesson_num, 'FM0000'),
        'arithmetic_2digit',
        'Cộng trừ 2 chữ số (bài ' || (current_count + lesson_num) || ')',
        '2-digit arithmetic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung cộng trừ 2 chữ số - biến thể nâng cao.', 'Supplementary 2-digit arithmetic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- arithmetic_3digit grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'arithmetic_3digit' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_arithm_top' || to_char(current_count + lesson_num, 'FM0000'),
        'arithmetic_3digit',
        'Cộng trừ 3 chữ số (bài ' || (current_count + lesson_num) || ')',
        '3-digit arithmetic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung cộng trừ 3 chữ số - biến thể nâng cao.', 'Supplementary 3-digit arithmetic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- decimals grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'decimals' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_decima_top' || to_char(current_count + lesson_num, 'FM0000'),
        'decimals',
        'Số thập phân (bài ' || (current_count + lesson_num) || ')',
        'Decimals (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số thập phân - biến thể nâng cao.', 'Supplementary Decimals practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- division grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'division' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_divisi_top' || to_char(current_count + lesson_num, 'FM0000'),
        'division',
        'Phép chia (bài ' || (current_count + lesson_num) || ')',
        'Division (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung phép chia - biến thể nâng cao.', 'Supplementary Division practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- fractions grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'fractions' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_fracti_top' || to_char(current_count + lesson_num, 'FM0000'),
        'fractions',
        'Phân số (bài ' || (current_count + lesson_num) || ')',
        'Fractions (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung phân số - biến thể nâng cao.', 'Supplementary Fractions practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 2: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 4: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 4;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g4g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 4)),
        4
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 5: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 5;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g5g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 5)),
        5
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 6: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 6;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g6g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 6)),
        6
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 7: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 7;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g7g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 7)),
        7
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 8: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 8;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g8g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 8)),
        8
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 9: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 9;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g9g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 9)),
        9
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 10: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 10;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g10g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 10)),
        10
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 11: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 11;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g11g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 11)),
        11
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- geometry grade 12: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'geometry' AND grade = 12;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g12g_geomet_top' || to_char(current_count + lesson_num, 'FM0000'),
        'geometry',
        'Hình học (bài ' || (current_count + lesson_num) || ')',
        'Geometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung hình học - biến thể nâng cao.', 'Supplementary Geometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 12)),
        12
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 2: 45 -> 50 (add 5)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 4: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 4;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g4l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 4)),
        4
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 5: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 5;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g5l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 5)),
        5
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 6: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 6;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g6l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 6)),
        6
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 7: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 7;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g7l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 7)),
        7
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 8: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 8;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g8l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 8)),
        8
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 9: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 9;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g9l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 9)),
        9
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 10: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 10;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g10l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 10)),
        10
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 11: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 11;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g11l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 11)),
        11
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- logic grade 12: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'logic' AND grade = 12;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g12l_logic_top' || to_char(current_count + lesson_num, 'FM0000'),
        'logic',
        'Tư duy (bài ' || (current_count + lesson_num) || ')',
        'Logic (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tư duy - biến thể nâng cao.', 'Supplementary Logic practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 12)),
        12
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 2: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 3: 25 -> 50 (add 25)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 4: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 4;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g4m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 4)),
        4
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 5: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 5;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g5m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 5)),
        5
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 6: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 6;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g6m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 6)),
        6
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 7: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 7;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g7m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 7)),
        7
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 8: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 8;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g8m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 8)),
        8
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 9: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 9;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g9m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 9)),
        9
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 10: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 10;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g10m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 10)),
        10
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 11: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 11;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g11m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 11)),
        11
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- measurement grade 12: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'measurement' AND grade = 12;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g12m_measur_top' || to_char(current_count + lesson_num, 'FM0000'),
        'measurement',
        'Đo lường (bài ' || (current_count + lesson_num) || ')',
        'Measurement (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung đo lường - biến thể nâng cao.', 'Supplementary Measurement practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 12)),
        12
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- multiplication grade 2: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'multiplication' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2n_multip_top' || to_char(current_count + lesson_num, 'FM0000'),
        'multiplication',
        'Bảng cửu chương (bài ' || (current_count + lesson_num) || ')',
        'Times table (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung bảng cửu chương - biến thể nâng cao.', 'Supplementary Times table practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- multiplication grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'multiplication' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3n_multip_top' || to_char(current_count + lesson_num, 'FM0000'),
        'multiplication',
        'Bảng cửu chương (bài ' || (current_count + lesson_num) || ')',
        'Times table (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung bảng cửu chương - biến thể nâng cao.', 'Supplementary Times table practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 2: 10 -> 50 (add 40)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 4: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 4;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g4n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 4)),
        4
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 5: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 5;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g5n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 5)),
        5
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 6: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 6;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g6n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 6)),
        6
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 7: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 7;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g7n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 7)),
        7
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 8: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 8;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g8n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 8)),
        8
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 9: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 9;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g9n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 9)),
        9
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 10: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 10;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g10n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 10)),
        10
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 11: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 11;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g11n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 11)),
        11
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- numbers grade 12: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'numbers' AND grade = 12;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g12n_number_top' || to_char(current_count + lesson_num, 'FM0000'),
        'numbers',
        'Số học (bài ' || (current_count + lesson_num) || ')',
        'Numbers (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung số học - biến thể nâng cao.', 'Supplementary Numbers practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 12)),
        12
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- perimeter grade 2: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'perimeter' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2g_perime_top' || to_char(current_count + lesson_num, 'FM0000'),
        'perimeter',
        'Chu vi (bài ' || (current_count + lesson_num) || ')',
        'Perimeter (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung chu vi - biến thể nâng cao.', 'Supplementary Perimeter practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- speed grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'speed' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3m_speed_top' || to_char(current_count + lesson_num, 'FM0000'),
        'speed',
        'Tốc độ (bài ' || (current_count + lesson_num) || ')',
        'Speed (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung tốc độ - biến thể nâng cao.', 'Supplementary Speed practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 4: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 4;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g4s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 4)),
        4
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 5: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 5;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g5s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 5)),
        5
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 6: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 6;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g6s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 6)),
        6
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 7: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 7;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g7s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 7)),
        7
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 8: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 8;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g8s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 8)),
        8
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 9: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 9;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g9s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 9)),
        9
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 10: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 10;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g10s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 10)),
        10
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 11: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 11;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g11s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 11)),
        11
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- statistics grade 12: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'statistics' AND grade = 12;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g12s_statis_top' || to_char(current_count + lesson_num, 'FM0000'),
        'statistics',
        'Thống kê (bài ' || (current_count + lesson_num) || ')',
        'Statistics (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thống kê - biến thể nâng cao.', 'Supplementary Statistics practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 12)),
        12
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- time_money grade 2: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'time_money' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2m_timemo_top' || to_char(current_count + lesson_num, 'FM0000'),
        'time_money',
        'Thời gian & Tiền (bài ' || (current_count + lesson_num) || ')',
        'Time & Money (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thời gian & tiền - biến thể nâng cao.', 'Supplementary Time & Money practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 3: 10 -> 50 (add 40)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 4: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 4;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g4t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 4)),
        4
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 5: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 5;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g5t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 5)),
        5
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 6: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 6;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g6t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 6)),
        6
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 7: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 7;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g7t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 7)),
        7
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 8: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 8;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g8t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 8)),
        8
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 9: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 9;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g9t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 9)),
        9
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 10: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 10;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g10t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 10)),
        10
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 11: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 11;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g11t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 11)),
        11
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- trigonometry grade 12: 30 -> 50 (add 20)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'trigonometry' AND grade = 12;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g12t_trigon_top' || to_char(current_count + lesson_num, 'FM0000'),
        'trigonometry',
        'Lượng giác (bài ' || (current_count + lesson_num) || ')',
        'Trigonometry (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung lượng giác - biến thể nâng cao.', 'Supplementary Trigonometry practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 12)),
        12
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- volume grade 3: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'volume' AND grade = 3;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g3m_volume_top' || to_char(current_count + lesson_num, 'FM0000'),
        'volume',
        'Thể tích (bài ' || (current_count + lesson_num) || ')',
        'Volume (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung thể tích - biến thể nâng cao.', 'Supplementary Volume practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 3)),
        3
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;

-- word_problems grade 2: 20 -> 50 (add 30)
DO $$
DECLARE
  current_count INT;
  lesson_num INT := 0;
BEGIN
  SELECT COUNT(*) INTO current_count FROM lessons WHERE subject_id = 'word_problems' AND grade = 2;
  IF current_count < 50 THEN
    FOR i IN 1..(50 - current_count) LOOP
      lesson_num := lesson_num + 1;
      INSERT INTO lessons (id, subject_id, title_vi, title_en, description_vi, description_en, lesson_order, difficulty, grade)
      VALUES (
        'g2n_wordpr_top' || to_char(current_count + lesson_num, 'FM0000'),
        'word_problems',
        'Bài toán có lời văn (bài ' || (current_count + lesson_num) || ')',
        'Word problems (lesson ' || (current_count + lesson_num) || ')',
        'Bài tập bổ sung bài toán có lời văn - biến thể nâng cao.', 'Supplementary Word problems practice - advanced variant.',
        200 + current_count + lesson_num,
        LEAST(3, GREATEST(1, 2)),
        2
      )
      ON CONFLICT (id) DO NOTHING;
    END LOOP;
  END IF;
END $$;


COMMIT;
