-- New subject seeders: Algebra (grade 2+) and Trigonometry (grade 3+)
--
-- Algebra extends Numbers (grade 2+): variables, equations, expressions.
-- Trigonometry extends Geometry (grade 3+): right triangles, sin/cos/tan basics.
--
-- These subjects are visible on the home screen (added in commit 279b6a6) but
-- had 0 lessons because no seeder existed. This migration populates them.
--
-- Pattern follows migration 005/006: INSERT INTO lessons with grade column.
-- INSERT subject rows are handled by migration 007_split_grade_subjects.sql.
-- The grade_min/grade_max columns on subjects already filter visibility per grade.

BEGIN;

-- =====================================================================
-- ALGEBRA (grade 2-3)
-- =====================================================================

-- Grade 2: basics — variables, simple equations
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0001', 'algebra', 'Biến số là gì?', 'What is a variable?', 1, 1, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0002', 'algebra', 'Viết biểu thức đơn giản', 'Write simple expressions', 2, 1, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0003', 'algebra', 'Tính giá trị biểu thức', 'Evaluate expressions', 3, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0004', 'algebra', 'Phép cộng có biến', 'Addition with variables', 4, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0005', 'algebra', 'Phép trừ có biến', 'Subtraction with variables', 5, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0006', 'algebra', 'Phép nhân có biến', 'Multiplication with variables', 6, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0007', 'algebra', 'Phương trình cộng: x + 3 = 7', 'Addition equations: x + 3 = 7', 7, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0008', 'algebra', 'Phương trình trừ: x - 5 = 2', 'Subtraction equations: x - 5 = 2', 8, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0009', 'algebra', 'Phương trình nhân: 3x = 12', 'Multiplication equations: 3x = 12', 9, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0010', 'algebra', 'Phương trình chia: x/4 = 5', 'Division equations: x/4 = 5', 10, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0011', 'algebra', 'Phương trình 2 bước: 2x + 3 = 11', 'Two-step equations: 2x + 3 = 11', 11, 3, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0012', 'algebra', 'Bài toán tuổi', 'Age word problems', 12, 3, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0013', 'algebra', 'Tính chất giao hoán', 'Commutative property', 13, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0014', 'algebra', 'Tính chất kết hợp', 'Associative property', 14, 2, 2, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g2_0015', 'algebra', 'Bài toán thực tế với biến', 'Real-world variable problems', 15, 3, 2, FALSE) ON CONFLICT (id) DO NOTHING;

-- Grade 3: more advanced algebra
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0001', 'algebra', 'Phương trình 2 bước nâng cao', 'Advanced two-step equations', 1, 2, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0002', 'algebra', 'Phương trình có dấu ngoặc', 'Equations with parentheses', 2, 2, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0003', 'algebra', 'Phân phối: a(b + c)', 'Distributive: a(b + c)', 3, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0004', 'algebra', 'Hệ số chung: 2x + 4 = 10', 'Common factor: 2x + 4 = 10', 4, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0005', 'algebra', 'Phân tích thừa số cơ bản', 'Basic factoring', 5, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0006', 'algebra', 'Biểu thức đa thức', 'Polynomial expressions', 6, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0007', 'algebra', 'Đẳng thức và bất đẳng thức', 'Equalities and inequalities', 7, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0008', 'algebra', 'Hàm số đơn giản', 'Simple functions', 8, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0009', 'algebra', 'Đồ thị đường thẳng', 'Linear graphs', 9, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('alg_g3_0010', 'algebra', 'Phương trình hai ẩn', 'Two-variable equations', 10, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;

-- Insert subject rows (in case they don't exist yet)
INSERT INTO subjects (id, name_vi, name_en, icon, color, grade_min, grade_max, display_order) VALUES ('algebra', 'Đại số', 'Algebra', '🅰️', '#FFB3D9', 2, 3, 5) ON CONFLICT (id) DO NOTHING;

-- =====================================================================
-- TRIGONOMETRY (grade 3)
-- =====================================================================

INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0001', 'trigonometry', 'Tam giác vuông cơ bản', 'Right triangle basics', 1, 1, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0002', 'trigonometry', 'Định lý Pythagoras', 'Pythagorean theorem', 2, 2, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0003', 'trigonometry', 'Cạnh huyền', 'Hypotenuse', 3, 1, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0004', 'trigonometry', 'sin là gì?', 'What is sine?', 4, 2, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0005', 'trigonometry', 'cos là gì?', 'What is cosine?', 5, 2, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0006', 'trigonometry', 'tan là gì?', 'What is tangent?', 6, 2, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0007', 'trigonometry', 'Tam giác 30-60-90', '30-60-90 triangles', 7, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0008', 'trigonometry', 'Tam giác 45-45-90', '45-45-90 triangles', 8, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0009', 'trigonometry', 'Tính cạnh tam giác vuông', 'Find the side of a right triangle', 9, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;
INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('trig_g3_0010', 'trigonometry', 'Bài toán thực tế', 'Real-world problems', 10, 3, 3, FALSE) ON CONFLICT (id) DO NOTHING;

INSERT INTO subjects (id, name_vi, name_en, icon, color, grade_min, grade_max, display_order) VALUES ('trigonometry', 'Lượng giác', 'Trigonometry', '📐', '#D9C7FF', 3, 3, 6) ON CONFLICT (id) DO NOTHING;

COMMIT;
