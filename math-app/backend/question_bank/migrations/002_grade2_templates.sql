-- Migration: Grade 2 Question Bank Templates
-- Adds Knowledge Components and Templates for Grade 2 difficulty level

-- Knowledge Components for Grade 2
INSERT INTO kc (name, description, bloom_level, difficulty_min, difficulty_max) VALUES
('g2_addition_carry', '2-digit addition with carrying (e.g., 25 + 38)', 'apply', 2, 2),
('g2_subtraction_borrow', '2-digit subtraction with borrowing (e.g., 53 - 27)', 'apply', 2, 2),
('g2_multiplication_tables', 'Multiplication tables 2x, 5x, 10x', 'apply', 2, 2),
('g2_word_problems', 'Simple word problems (shopping, grouping)', 'understand', 2, 2),
('g2_3d_shapes', 'Identify 3D shapes (cube, sphere, cylinder)', 'remember', 2, 2),
('g2_symmetry', 'Recognize symmetry in shapes', 'understand', 2, 2),
('g2_length_cm', 'Measure and compare length in cm', 'apply', 2, 2),
('g2_time_half_hour', 'Tell time to the half hour', 'apply', 2, 2),
('g2_money_vnd', 'Simple money arithmetic in Vietnamese Dong', 'apply', 2, 2),
('g2_patterns', 'Multi-step number patterns', 'understand', 2, 2),
('g2_venn_sort', 'Sort items using Venn diagram logic', 'analyze', 2, 2),
('g2_vietnamese_compound', 'Vietnamese compound words', 'remember', 2, 2),
('g2_vietnamese_sentences', 'Build simple Vietnamese sentences', 'apply', 2, 2),
('g2_english_vocab', 'English vocabulary expansion', 'remember', 2, 2),
('g2_english_grammar', 'Basic English grammar (he/she, a/an)', 'understand', 2, 2)
ON CONFLICT (name) DO NOTHING;

-- Templates for Grade 2
INSERT INTO template (kc_id, difficulty, bloom_level, stem_template, param_schema, solution_expr, error_taxonomy, active) VALUES
((SELECT id FROM kc WHERE name = 'g2_addition_carry'), 2, 'apply',
 '{{a}} + {{b}} = ?',
 '{"a": {"min": 10, "max": 99, "integer_only": true, "exclude_zero": false}, "b": {"min": 10, "max": 99, "integer_only": true, "exclude_zero": false}}',
 'a + b',
 '[{"type": "carry_error", "desc": "Forgot to carry the 1"}, {"type": "digit_error", "desc": "Added digits separately without place value"}]',
 true),

((SELECT id FROM kc WHERE name = 'g2_subtraction_borrow'), 2, 'apply',
 '{{a}} - {{b}} = ?',
 '{"a": {"min": 20, "max": 99, "integer_only": true, "exclude_zero": false}, "b": {"min": 10, "max": 49, "integer_only": true, "exclude_zero": false}}',
 'a - b',
 '[{"type": "borrow_error", "desc": "Forgot to borrow from tens place"}, {"type": "negative_result", "desc": "Subtracted larger digit from smaller digit"}]',
 true),

((SELECT id FROM kc WHERE name = 'g2_multiplication_tables'), 2, 'apply',
 '{{a}} × {{b}} = ?',
 '{"a": {"min": 2, "max": 10, "integer_only": true, "exclude_zero": false}, "b": {"min": 2, "max": 10, "integer_only": true, "exclude_zero": false}}',
 'a * b',
 '[{"type": "addition_instead", "desc": "Added instead of multiplied"}, {"type": "wrong_table", "desc": "Used wrong multiplication table"}]',
 true),

((SELECT id FROM kc WHERE name = 'g2_word_problems'), 2, 'understand',
 'Bé có {{a}} quả táo, mẹ cho thêm {{b}} quả. Bé có bao nhiêu quả táo? | You have {{a}} apples, mom gives you {{b}} more. How many apples do you have?',
 '{"a": {"min": 10, "max": 50, "integer_only": true, "exclude_zero": false}, "b": {"min": 5, "max": 30, "integer_only": true, "exclude_zero": false}}',
 'a + b',
 '[{"type": "keyword_misread", "desc": "Misread give/take away"}, {"type": "operation_error", "desc": "Chose wrong operation"}]',
 true),

((SELECT id FROM kc WHERE name = 'g2_length_cm'), 2, 'apply',
 'Đoạn thước dài {{a}} cm, đoạn kia dài {{b}} cm. Đoạn nào dài hơn? | One ruler is {{a}} cm, another is {{b}} cm. Which is longer?',
 '{"a": {"min": 5, "max": 100, "integer_only": true, "exclude_zero": false}, "b": {"min": 5, "max": 100, "integer_only": true, "exclude_zero": false}}',
 'if a > b then 0 else 1',
 '[{"type": "comparison_reverse", "desc": "Chose the shorter one"}, {"type": "unit_confusion", "desc": "Ignored cm unit"}]',
 true),

((SELECT id FROM kc WHERE name = 'g2_time_half_hour'), 2, 'apply',
 'Đồng hồ chỉ {{h}}:30. Đó là mấy giờ? | The clock shows {{h}}:30. What time is it?',
 '{"h": {"min": 1, "max": 12, "integer_only": true, "exclude_zero": false}}',
 'h',
 '[{"type": "hour_confusion", "desc": "Read hour hand wrong"}, {"type": "half_past", "desc": "Said exact hour instead of half past"}]',
 true),

((SELECT id FROM kc WHERE name = 'g2_money_vnd'), 2, 'apply',
 'Mua 1 cái bút {{a}}đ và 1 quyển vở {{b}}đ. Hết bao nhiêu tiền? | Buy a pen for {{a}} VND and a notebook for {{b}} VND. How much total?',
 '{"a": {"min": 1000, "max": 10000, "integer_only": true, "exclude_zero": false}, "b": {"min": 2000, "max": 15000, "integer_only": true, "exclude_zero": false}}',
 'a + b',
 '[{"type": "missing_item", "desc": "Only added one item"}, {"type": "decimal_error", "desc": "Misplaced comma in thousands"}]',
 true),

((SELECT id FROM kc WHERE name = 'g2_patterns'), 2, 'understand',
 'Số tiếp theo: {{a}}, {{b}}, {{c}}, __? | Next number: {{a}}, {{b}}, {{c}}, __?',
 '{"a": {"min": 1, "max": 20, "integer_only": true, "exclude_zero": false}, "d": {"min": 2, "max": 5, "integer_only": true, "exclude_zero": false}}',
 'a + 3*d',
 '[{"type": "wrong_pattern", "desc": "Identified wrong pattern rule"}, {"type": "off_by_one", "desc": "Correct rule but wrong position"}]',
 true)
ON CONFLICT DO NOTHING;
