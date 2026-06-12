BEGIN;

-- ============================================================
-- Insert new sub-subjects into subjects table (required by FK)
-- ============================================================
INSERT INTO subjects (id, name_vi, name_en, description_vi, description_en, icon, color, display_order, grade_min, grade_max) VALUES
  ('arithmetic_2digit', 'Cộng trừ 2 chữ số', '2-digit arithmetic', 'Cộng trừ với số có 2 chữ số, có nhớ.', 'Addition/subtraction with 2-digit numbers, carrying.', '➕', '#E8F5E9', 10, 2, 2),
  ('arithmetic_3digit', 'Cộng trừ 3 chữ số', '3-digit arithmetic', 'Cộng trừ với số có 3 chữ số.', 'Addition/subtraction with 3-digit numbers.', '➕', '#E8F5E9', 11, 3, 3),
  ('multiplication', 'Bảng cửu chương', 'Multiplication tables', 'Học thuộc và áp dụng bảng cửu chương.', 'Learn and apply multiplication tables.', '✖️', '#FFF3E0', 12, 2, 3),
  ('division', 'Phép chia', 'Division', 'Phép chia có dư, chia hết.', 'Division with and without remainders.', '➗', '#FFF3E0', 13, 3, 3),
  ('fractions', 'Phân số', 'Fractions', 'Đọc, viết và tính toán với phân số.', 'Read, write and compute fractions.', '½', '#F3E5F5', 14, 3, 3),
  ('decimals', 'Số thập phân', 'Decimals', 'Đọc, viết và tính toán với số thập phân.', 'Read, write and compute decimals.', '0.1', '#F3E5F5', 15, 3, 3),
  ('perimeter', 'Chu vi', 'Perimeter', 'Tính chu vi các hình cơ bản.', 'Compute perimeter of basic shapes.', '📏', '#E1F5FE', 16, 2, 3),
  ('area', 'Diện tích', 'Area', 'Tính diện tích các hình phẳng.', 'Compute area of flat shapes.', '⬛', '#E1F5FE', 17, 3, 3),
  ('angles', 'Góc', 'Angles', 'Nhận biết và đo góc.', 'Identify and measure angles.', '📐', '#FCE4EC', 18, 3, 3),
  ('time_money', 'Thời gian & Tiền', 'Time & Money', 'Đọc đồng hồ và tính tiền VND.', 'Tell time and count VND.', '⏰', '#FFF8E1', 19, 2, 3),
  ('word_problems', 'Bài toán có lời', 'Word problems', 'Giải toán có lời văn nhiều bước.', 'Solve multi-step word problems.', '📝', '#F1F8E9', 22, 2, 3),
  ('volume', 'Thể tích', 'Volume', 'Tính thể tích các hình 3D.', 'Compute volume of 3D shapes.', '🧊', '#E0F7FA', 20, 3, 3),
  ('speed', 'Tốc độ', 'Speed', 'Tính tốc độ, quãng đường, thời gian.', 'Compute speed, distance, time.', '🚀', '#F1F8E9', 21, 3, 3)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- GRADE 2: split 'numbers' into topic-specific sub-subjects
-- ============================================================
UPDATE lessons SET subject_id = 'arithmetic_2digit'
  WHERE subject_id = 'numbers' AND grade = 2
    AND (title_vi LIKE 'Cộng 2 chữ số%' OR title_vi LIKE 'Trừ 2 chữ số%');

UPDATE lessons SET subject_id = 'multiplication'
  WHERE subject_id = 'numbers' AND grade = 2
    AND title_vi LIKE 'Bảng cửu chương%';

UPDATE lessons SET subject_id = 'word_problems'
  WHERE subject_id = 'numbers' AND grade = 2
    AND title_vi LIKE 'Bài toán có lời%';

-- ============================================================
-- GRADE 3: split 'numbers' into topic-specific sub-subjects
-- ============================================================
UPDATE lessons SET subject_id = 'arithmetic_3digit'
  WHERE subject_id = 'numbers' AND grade = 3
    AND title_vi LIKE 'Cộng trừ 3 chữ số%';

UPDATE lessons SET subject_id = 'multiplication'
  WHERE subject_id = 'numbers' AND grade = 3
    AND title_vi LIKE 'Nhân 1-10%';

UPDATE lessons SET subject_id = 'division'
  WHERE subject_id = 'numbers' AND grade = 3
    AND title_vi LIKE 'Chia có dư%';

UPDATE lessons SET subject_id = 'fractions'
  WHERE subject_id = 'numbers' AND grade = 3
    AND title_vi LIKE 'Phân số%';

UPDATE lessons SET subject_id = 'decimals'
  WHERE subject_id = 'numbers' AND grade = 3
    AND title_vi LIKE 'Số thập phân%';

-- ============================================================
-- GRADE 2/3: split 'geometry'
-- ============================================================
UPDATE lessons SET subject_id = 'perimeter'
  WHERE subject_id = 'geometry' AND grade IN (2, 3)
    AND title_vi LIKE 'Chu vi%';

UPDATE lessons SET subject_id = 'area'
  WHERE subject_id = 'geometry' AND grade = 3
    AND title_vi LIKE 'Diện tích%';

UPDATE lessons SET subject_id = 'angles'
  WHERE subject_id = 'geometry' AND grade = 3
    AND title_vi LIKE 'Góc%';

-- ============================================================
-- GRADE 2/3: split 'measurement'
-- ============================================================
UPDATE lessons SET subject_id = 'time_money'
  WHERE subject_id = 'measurement' AND grade IN (2, 3)
    AND (title_vi LIKE 'Đọc đồng hồ%' OR title_vi LIKE 'Tiền%');

UPDATE lessons SET subject_id = 'volume'
  WHERE subject_id = 'measurement' AND grade = 3
    AND title_vi LIKE 'Thể tích%';

UPDATE lessons SET subject_id = 'speed'
  WHERE subject_id = 'measurement' AND grade = 3
    AND title_vi LIKE 'Tốc độ%';

COMMIT;
