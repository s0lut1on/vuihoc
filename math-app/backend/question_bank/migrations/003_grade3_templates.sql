-- Migration: Grade 3 Question Bank Templates
-- Adds Knowledge Components and Templates for Grade 3 difficulty level

-- Knowledge Components for Grade 3
INSERT INTO kc (name, description, bloom_level, difficulty_min, difficulty_max) VALUES
('g3_multiplication_full', 'Full multiplication tables 1-10', 'apply', 3, 3),
('g3_division_intro', 'Division with remainders', 'apply', 3, 3),
('g3_fraction_visual', 'Fraction basics (1/2, 1/4, 3/4)', 'understand', 3, 3),
('g3_decimal_intro', 'Decimal basics (0.1, 0.5, 1.25)', 'understand', 3, 3),
('g3_3digit_arithmetic', '3-digit addition and subtraction', 'apply', 3, 3),
('g3_area_rectangle', 'Area of rectangle basics', 'apply', 3, 3),
('g3_angles', 'Identify angles (acute, obtuse, right)', 'understand', 3, 3),
('g3_volume_liter', 'Volume comparison in liters', 'apply', 3, 3),
('g3_elapsed_time', 'Calculate elapsed time', 'apply', 3, 3),
('g3_logic_and_or', 'Logical operators AND/OR', 'understand', 3, 3),
('g3_set_theory', 'Basic set theory (union, intersection)', 'understand', 3, 3),
('g3_vietnamese_reading', 'Vietnamese paragraph reading comprehension', 'understand', 3, 3),
('g3_vietnamese_grammar', 'Vietnamese grammar rules', 'understand', 3, 3),
('g3_english_past_tense', 'English past tense verbs', 'apply', 3, 3),
('g3_english_reading', 'English reading comprehension', 'understand', 3, 3)
ON CONFLICT (name) DO NOTHING;

-- Templates for Grade 3
INSERT INTO template (kc_id, difficulty, bloom_level, stem_template, param_schema, solution_expr, error_taxonomy, active) VALUES
((SELECT id FROM kc WHERE name = 'g3_multiplication_full'), 3, 'apply',
 '{{a}} × {{b}} = ?',
 '{"a": {"min": 1, "max": 10, "integer_only": true, "exclude_zero": false}, "b": {"min": 1, "max": 10, "integer_only": true, "exclude_zero": false}}',
 'a * b',
 '[{"type": "wrong_table", "desc": "Used wrong multiplication table"}, {"type": "addition_instead", "desc": "Added instead of multiplying"}]',
 true),

((SELECT id FROM kc WHERE name = 'g3_division_intro'), 3, 'apply',
 '{{a}} ÷ {{b}} = ? (dư bao nhiêu?) | {{a}} ÷ {{b}} = ? (remainder?)',
 '{"a": {"min": 10, "max": 99, "integer_only": true, "exclude_zero": false}, "b": {"min": 2, "max": 9, "integer_only": true, "exclude_zero": false}}',
 'a % b',
 '[{"type": "quotient_only", "desc": "Gave only quotient, forgot remainder"}, {"type": "division_error", "desc": "Divided incorrectly"}]',
 true),

((SELECT id FROM kc WHERE name = 'g3_fraction_visual'), 3, 'understand',
 'Hình tròn chia {{total}} phần, tô {{shaded}} phần. Phần này là bao nhiêu? | A circle divided into {{total}} parts, {{shaded}} shaded. What fraction?',
 '{"total": {"min": 2, "max": 8, "integer_only": true, "exclude_zero": false}, "shaded": {"min": 1, "max": 7, "integer_only": true, "exclude_zero": false}}',
 'shaded / total',
 '[{"type": "total_as_numerator", "desc": "Put total in numerator"}, {"type": "simplify_error", "desc": "Failed to simplify fraction"}]',
 true),

((SELECT id FROM kc WHERE name = 'g3_decimal_intro'), 3, 'understand',
 '0.{{a}} + 0.{{b}} = ?',
 '{"a": {"min": 1, "max": 9, "integer_only": true, "exclude_zero": false}, "b": {"min": 1, "max": 9, "integer_only": true, "exclude_zero": false}}',
 '(a + b) / 10',
 '[{"type": "decimal_point_error", "desc": "Misplaced decimal point"}, {"type": "whole_number", "desc": "Wrote whole number answer"}]',
 true),

((SELECT id FROM kc WHERE name = 'g3_3digit_arithmetic'), 3, 'apply',
 '{{a}} + {{b}} = ?',
 '{"a": {"min": 100, "max": 999, "integer_only": true, "exclude_zero": false}, "b": {"min": 100, "max": 999, "integer_only": true, "exclude_zero": false}}',
 'a + b',
 '[{"type": "carry_error", "desc": "Forgot to carry across hundreds"}, {"type": "alignment_error", "desc": "Misaligned digits"}]',
 true),

((SELECT id FROM kc WHERE name = 'g3_area_rectangle'), 3, 'apply',
 'Hình chữ nhật dài {{length}} cm, rộng {{width}} cm. Diện tích = ? | Rectangle length {{length}} cm, width {{width}} cm. Area = ?',
 '{"length": {"min": 2, "max": 20, "integer_only": true, "exclude_zero": false}, "width": {"min": 2, "max": 20, "integer_only": true, "exclude_zero": false}}',
 'length * width',
 '[{"type": "perimeter_instead", "desc": "Calculated perimeter instead of area"}, {"type": "unit_missing", "desc": "Forgot cm² unit"}]',
 true),

((SELECT id FROM kc WHERE name = 'g3_angles'), 3, 'understand',
 'Góc này là góc nhọn, vuông, hay tù? | Is this angle acute, right, or obtuse?',
 '{"angle": {"min": 30, "max": 150, "integer_only": true, "exclude_zero": false}}',
 'if angle < 90 then 0 else (if angle == 90 then 1 else 2)',
 '[{"type": "acute_obtuse_confusion", "desc": "Confused acute and obtuse"}, {"type": "right_angle_miss", "desc": "Did not recognize right angle"}]',
 true),

((SELECT id FROM kc WHERE name = 'g3_elapsed_time'), 3, 'apply',
 'Lớp bắt đầu lúc {{start_h}}:{{start_m}}, kết thúc lúc {{end_h}}:{{end_m}}. Học bao lâu? | Class starts at {{start_h}}:{{start_m}}, ends at {{end_h}}:{{end_m}}. How long?',
 '{"start_h": {"min": 7, "max": 14, "integer_only": true, "exclude_zero": false}, "start_m": {"min": 0, "max": 45, "integer_only": true, "exclude_zero": false}, "duration": {"min": 30, "max": 120, "integer_only": true, "exclude_zero": false}}',
 'duration',
 '[{"type": "hour_minute_confusion", "desc": "Confused hours and minutes"}, {"type": "subtraction_error", "desc": "Subtraction error in time calc"}]',
 true)
ON CONFLICT DO NOTHING;
