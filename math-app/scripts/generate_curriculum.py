#!/usr/bin/env python3
"""
Generate curriculum SQL for content-service and language-service.
Supports Grade 2 and Grade 3 with configurable exercises per lesson.

Usage:
    python generate_curriculum.py --grade 2 --service content > ../backend/content/migrations/005_grade2_curriculum.sql
    python generate_curriculum.py --grade 2 --service language > ../backend/language/migrations/004_grade2_curriculum.sql
    python generate_curriculum.py --grade 3 --service content > ../backend/content/migrations/006_grade3_curriculum.sql
    python generate_curriculum.py --grade 3 --service language > ../backend/language/migrations/005_grade3_curriculum.sql

Output: SQL INSERT statements for lessons and exercises.
"""

import argparse
import random
import sys

random.seed(42)


def gen_id(prefix, num):
    return f"{prefix}{num:04d}"


def gen_ex_id(lesson_id, ex_num):
    return f"ex_{lesson_id}_{ex_num}"


def escape_sql(s):
    return s.replace("'", "''")


def make_options(answer, wrong_pool, count=3):
    ans_str = str(answer)
    wrong = random.sample([str(w) for w in wrong_pool if str(w) != ans_str], count - 1)
    opts = [ans_str] + wrong
    random.shuffle(opts)
    return opts, opts.index(ans_str)


def generate_numbers(grade, prefix, diff):
    lessons, exercises = [], []

    if grade == 2:
        configs = [
            (10, "Cộng 2 chữ số", "2-digit addition", "add", "arithmetic_2digit"),
            (10, "Trừ 2 chữ số", "2-digit subtraction", "sub", "arithmetic_2digit"),
            (10, "Bảng cửu chương", "Times table", "mul", "multiplication"),
            (10, "Bài toán có lời", "Word problems", "word", "word_problems"),
            (10, "Ôn tập số học", "Mixed review", "mixed", "arithmetic_2digit"),
        ]
    else:  # grade 3
        configs = [
            (15, "Nhân 1-10", "Multiplication 1-10", "mul", "multiplication"),
            (10, "Chia có dư", "Division with remainders", "div", "division"),
            (10, "Phân số", "Fractions", "frac", "fractions"),
            (10, "Số thập phân", "Decimals", "dec", "decimals"),
            (10, "Cộng trừ 3 chữ số", "3-digit arithmetic", "3dig", "arithmetic_3digit"),
        ]

    op_to_subject = {
        "add": "arithmetic_2digit", "sub": "arithmetic_2digit",
        "3dig": "arithmetic_3digit", "mixed": "arithmetic_2digit",
    }

    idx = 0
    for count, title_vi_base, title_en_base, op, sub_subject in configs:
        for i in range(1, count + 1):
            idx += 1
            lid = gen_id(f"{prefix}n", idx)
            subject_id = op_to_subject.get(op, sub_subject)
            lessons.append((lid, subject_id, f"{title_vi_base} (bài {i})", f"{title_en_base} (lesson {i})", idx, diff))

            ex_count = random.randint(2, 3)
            for ex_i in range(1, ex_count + 1):
                if op == "add":
                    a = random.randint(10, 89)
                    a_u = a % 10 or random.randint(2, 9)
                    a = (a // 10) * 10 + a_u
                    b_u = random.randint(10 - a_u, 9)
                    b = random.randint(1, 9) * 10 + b_u
                    ans = a + b
                    qvi = f"{a} + {b} = ?"
                    qen = f"{a} + {b} = ?"
                    opts, correct = make_options(ans, [ans + 1, ans - 1, ans + 10, ans - 10])
                elif op == "sub":
                    a_t = random.randint(3, 9)
                    a_u = random.randint(0, 7)
                    a = a_t * 10 + a_u
                    b_u = random.randint(a_u + 1, 9)
                    b_t = random.randint(1, a_t - 1)
                    b = b_t * 10 + b_u
                    ans = a - b
                    qvi = f"{a} - {b} = ?"
                    qen = f"{a} - {b} = ?"
                    opts, correct = make_options(ans, [ans + 1, ans - 1, a_u + b_u, a - b_t * 10])
                elif op == "mul":
                    a = random.randint(2, 10)
                    b = random.randint(2, 10)
                    ans = a * b
                    qvi = f"{a} × {b} = ?"
                    qen = f"{a} × {b} = ?"
                    opts, correct = make_options(ans, [a + b, a * b + a, a * b - a])
                elif op == "div":
                    b = random.randint(2, 9)
                    ans = random.randint(2, 12)
                    rem = random.randint(1, b - 1)
                    a = b * ans + rem
                    qvi = f"{a} ÷ {b} = ? (dư {rem})"
                    qen = f"{a} ÷ {b} = ? (remainder {rem})"
                    opts, correct = make_options(ans, [ans + 1, ans - 1, a // b + 1 if rem == 0 else ans + 2])
                elif op == "frac":
                    num = random.randint(1, 3)
                    den = random.randint(2, 4)
                    qvi = f"Phân số: {num}/{den} = ?"
                    qen = f"Fraction: {num}/{den} = ?"
                    opts = [f"{num}/{den}", f"{den}/{num}", f"{num + 1}/{den}"]
                    correct = 0
                elif op == "dec":
                    a = random.randint(1, 9)
                    b = random.randint(1, 9)
                    ans = (a + b) / 10
                    qvi = f"0.{a} + 0.{b} = ?"
                    qen = f"0.{a} + 0.{b} = ?"
                    opts = [f"{ans:.1f}", f"{a + b}", f"0.{a + b}"]
                    correct = 0
                elif op == "3dig":
                    a = random.randint(100, 999)
                    b = random.randint(100, 999)
                    ans = a + b
                    qvi = f"{a} + {b} = ?"
                    qen = f"{a} + {b} = ?"
                    opts, correct = make_options(ans, [ans + 100, ans - 100, a + b + 1])
                elif op == "word":
                    a = random.randint(10, 50)
                    b = random.randint(5, 30)
                    ans = a + b
                    qvi = f"Bé có {a} quả táo, mẹ cho thêm {b} quả. Có bao nhiêu?"
                    qen = f"You have {a} apples, mom gives {b} more. How many?"
                    opts, correct = make_options(ans, [a - b, a + b + 5, a])
                else:  # mixed
                    a = random.randint(10, 50)
                    b = random.randint(5, 20)
                    ans = a + b
                    qvi = f"{a} + {b} = ?"
                    qen = f"{a} + {b} = ?"
                    opts, correct = make_options(ans, [a - b, a + b + 3, a * 2])

                exercises.append((gen_ex_id(lid, ex_i), lid, qvi, qen, opts, correct, "🔢",
                    "Đọc kỹ đề và tính chậm rãi.", "Read carefully and calculate slowly.", ex_i))

    return lessons, exercises


def generate_geometry(grade, prefix, diff):
    lessons, exercises = [], []

    if grade == 2:
        configs = [
            (15, "Hình 3D", "3D shapes", "3d", "geometry"),
            (15, "Đối xứng", "Symmetry", "sym", "geometry"),
            (15, "Chu vi", "Perimeter", "per", "perimeter"),
        ]
    else:
        configs = [
            (15, "Diện tích", "Area", "area", "area"),
            (15, "Góc", "Angles", "ang", "angles"),
            (15, "Tọa độ", "Coordinates", "coord", "geometry"),
            (5, "Đối xứng gương", "Mirror symmetry", "mir", "geometry"),
        ]

    idx = 0
    for count, title_vi_base, title_en_base, op, sub_subject in configs:
        for i in range(1, count + 1):
            idx += 1
            lid = gen_id(f"{prefix}g", idx)
            lessons.append((lid, sub_subject, f"{title_vi_base} (bài {i})", f"{title_en_base} (lesson {i})", idx, diff))

            ex_count = random.randint(2, 3)
            for ex_i in range(1, ex_count + 1):
                if op == "3d":
                    shapes = [("hình lập phương", "cube"), ("hình cầu", "sphere"), ("hình trụ", "cylinder"), ("hình chóp", "pyramid")]
                    s = shapes[(idx - 1) % 4]
                    opts = [s[0], shapes[(idx) % 4][0], shapes[(idx + 1) % 4][0]]
                    correct = 0
                    qvi = f"Đây là {s[0]}?"
                    qen = f"Is this a {s[1]}?"
                elif op == "sym":
                    qvi = "Hình này có đối xứng không? 🦋"
                    qen = "Is this shape symmetrical? 🦋"
                    opts = ["Có / Yes", "Không / No", "Không chắc / Not sure"]
                    correct = 0
                elif op == "per":
                    a = random.randint(3, 10)
                    b = random.randint(3, 10)
                    ans = 2 * (a + b)
                    opts, correct = make_options(ans, [a * b, a + b, ans + 2])
                    qvi = f"Chu vi hình chữ nhật {a}cm × {b}cm = ?"
                    qen = f"Perimeter of rectangle {a}cm × {b}cm = ?"
                elif op == "area":
                    a = random.randint(2, 20)
                    b = random.randint(2, 20)
                    ans = a * b
                    opts, correct = make_options(ans, [2 * (a + b), a + b, ans + 10])
                    qvi = f"Diện tích hình chữ nhật {a}cm × {b}cm = ?"
                    qen = f"Area of rectangle {a}cm × {b}cm = ?"
                elif op == "ang":
                    ang = random.choice([30, 45, 90, 120, 150])
                    names = {30: "nhọn / acute", 45: "nhọn / acute", 90: "vuông / right", 120: "tù / obtuse", 150: "tù / obtuse"}
                    qvi = f"Góc {ang}° là góc gì?"
                    qen = f"A {ang}° angle is?"
                    opts = ["nhọn / acute", "vuông / right", "tù / obtuse"]
                    correct = 0 if ang <= 45 else (1 if ang == 90 else 2)
                elif op == "coord":
                    x, y = random.randint(1, 5), random.randint(1, 5)
                    qvi = f"Điểm ở tọa độ ({x}, {y})?"
                    qen = f"Point at coordinate ({x}, {y})?"
                    opts = [f"({x}, {y})", f"({y}, {x})", f"({x + 1}, {y})"]
                    correct = 0
                else:  # mirror
                    qvi = "Hình này có đối xứng qua gương không?"
                    qen = "Does this have mirror symmetry?"
                    opts = ["Có / Yes", "Không / No", "Không chắc / Not sure"]
                    correct = 0

                exercises.append((gen_ex_id(lid, ex_i), lid, qvi, qen, opts, correct, "📐",
                    "Quan sát kỹ hình và tính toán.", "Observe the shape carefully.", ex_i))

    return lessons, exercises


def generate_measurement(grade, prefix, diff):
    lessons, exercises = [], []

    if grade == 2:
        configs = [
            (15, "Đo chiều dài", "Measuring length", "len", "measurement"),
            (15, "Cân nặng", "Weight", "wgt", "measurement"),
            (7, "Đọc đồng hồ", "Telling time", "time", "time_money"),
            (8, "Tiền", "Money", "money", "time_money"),
        ]
    else:
        configs = [
            (15, "Thể tích", "Volume", "vol", "volume"),
            (15, "Diện tích cm²", "Area cm²", "area", "measurement"),
            (10, "Thời gian", "Time", "time", "time_money"),
            (10, "Tốc độ", "Speed", "spd", "speed"),
        ]

    idx = 0
    for count, title_vi_base, title_en_base, op, sub_subject in configs:
        for i in range(1, count + 1):
            idx += 1
            lid = gen_id(f"{prefix}m", idx)
            lessons.append((lid, sub_subject, f"{title_vi_base} (bài {i})", f"{title_en_base} (lesson {i})", idx, diff))

            ex_count = random.randint(2, 3)
            for ex_i in range(1, ex_count + 1):
                if op == "len":
                    a, b = random.randint(5, 100), random.randint(5, 100)
                    ans = "A" if a > b else "B"
                    opts = [f"Đoạn A / Ruler A", f"Đoạn B / Ruler B", "Bằng nhau / Same"]
                    correct = 0 if a > b else (1 if b > a else 2)
                    qvi = f"Đoạn A dài {a}cm, đoạn B dài {b}cm. Đoạn nào dài hơn?"
                    qen = f"Ruler A is {a}cm, B is {b}cm. Which is longer?"
                elif op == "wgt":
                    a, b = random.randint(1, 10), random.randint(1, 10)
                    opts = [f"Vật A / Object A", f"Vật B / Object B", "Bằng nhau / Same"]
                    correct = 0 if a > b else (1 if b > a else 2)
                    qvi = f"Vật A {a}kg, vật B {b}kg. Vật nào nặng hơn?"
                    qen = f"Object A is {a}kg, B is {b}kg. Which is heavier?"
                elif op == "time":
                    if grade == 2:
                        h = random.randint(1, 12)
                        opts = [f"{h} giờ rưỡi / {h}:30", f"{h} giờ / {h}:00", f"{h + 1} giờ / {h + 1}:00"]
                        correct = 0
                        qvi = f"Đồng hồ chỉ {h}:30. Mấy giờ?"
                        qen = f"The clock shows {h}:30. What time?"
                    else:
                        start = random.randint(7, 14)
                        dur = random.randint(30, 120)
                        end_h = start + dur // 60
                        end_m = dur % 60
                        opts, correct = make_options(dur, [dur + 15, dur - 15, dur + 30])
                        qvi = f"Lớp bắt đầu {start}:00, kết thúc {end_h}:{end_m:02d}. Học bao lâu?"
                        qen = f"Class starts at {start}:00, ends at {end_h}:{end_m:02d}. How long?"
                elif op == "money":
                    a = random.randint(1, 10) * 1000
                    b = random.randint(1, 10) * 2000
                    ans = a + b
                    opts, correct = make_options(ans, [abs(a - b), ans + 5000, a])
                    qvi = f"Bút {a}đ + vở {b}đ = ?"
                    qen = f"Pen {a} VND + notebook {b} VND = ?"
                elif op == "vol":
                    a, b = random.randint(1, 5), random.randint(1, 5)
                    opts = [f"{a}L / {a}L", f"{b}L / {b}L", "Bằng nhau / Same"]
                    correct = 0 if a > b else (1 if b > a else 2)
                    qvi = f"Bình A chứa {a}L, bình B chứa {b}L. Bình nào nhiều hơn?"
                    qen = f"Bottle A holds {a}L, B holds {b}L. Which holds more?"
                elif op == "area":
                    a, b = random.randint(2, 20), random.randint(2, 20)
                    ans = a * b
                    opts, correct = make_options(ans, [a + b, 2 * (a + b), ans + 10])
                    qvi = f"Hình chữ nhật {a}cm × {b}cm. Diện tích = ? cm²"
                    qen = f"Rectangle {a}cm × {b}cm. Area = ? cm²"
                elif op == "spd":
                    d = random.randint(10, 100)
                    t = random.randint(1, 5)
                    ans = d // t
                    opts, correct = make_options(ans, [d * t, d + t, ans + 5])
                    qvi = f"Đi {d}km trong {t} giờ. Tốc độ = ? km/h"
                    qen = f"Travel {d}km in {t} hours. Speed = ? km/h"
                else:
                    a, b = random.randint(2, 10), random.randint(2, 10)
                    ans = a * b
                    opts, correct = make_options(ans, [a + b, a - b, a * 2])
                    qvi = f"{a} × {b} = ?"
                    qen = f"{a} × {b} = ?"

                exercises.append((gen_ex_id(lid, ex_i), lid, qvi, qen, opts, correct, "📏",
                    "Đọc kỹ đơn vị đo lường.", "Read the measurement unit carefully.", ex_i))

    return lessons, exercises


def generate_logic(grade, prefix, diff):
    lessons, exercises = [], []

    if grade == 2:
        configs = [
            (15, "Dãy số", "Number patterns", "pat"),
            (15, "Phân loại", "Sorting", "sort"),
            (15, "Suy luận", "Reasoning", "reas"),
        ]
    else:
        configs = [
            (15, "Suy luận nhiều bước", "Multi-step reasoning", "reas"),
            (15, "Lý thuyết tập hợp", "Set theory", "set"),
            (10, "AND/OR logic", "Logical operators", "logic"),
            (10, "Cờ vua", "Chess puzzles", "chess"),
        ]

    idx = 0
    for count, title_vi_base, title_en_base, op in configs:
        for i in range(1, count + 1):
            idx += 1
            lid = gen_id(f"{prefix}l", idx)
            lessons.append((lid, "logic", f"{title_vi_base} (bài {i})", f"{title_en_base} (lesson {i})", idx, diff))

            ex_count = random.randint(2, 3)
            for ex_i in range(1, ex_count + 1):
                if op == "pat":
                    d = random.randint(2, 5)
                    a = random.randint(1, 20)
                    seq = [a, a + d, a + 2 * d]
                    ans = a + 3 * d
                    opts, correct = make_options(ans, [a + 2 * d, a + 4 * d, a + d])
                    qvi = f"Số tiếp theo: {seq[0]}, {seq[1]}, {seq[2]}, __?"
                    qen = f"Next number: {seq[0]}, {seq[1]}, {seq[2]}, __?"
                elif op == "sort":
                    opts = ["🐕 Dog", "🐦 Bird", "🐟 Fish"]
                    correct = 0
                    qvi = "Con nào có 4 chân: 🐕 🐦 🐟?"
                    qen = "Which has 4 legs: 🐕 🐦 🐟?"
                elif op == "reas":
                    if grade == 2:
                        a, b = random.randint(2, 5), random.randint(3, 6)
                        opts, correct = make_options(b, [a, a + b, b + 1])
                        qvi = f"A có {a} quả bóng, B có {b} quả. Ai có nhiều hơn?"
                        qen = f"A has {a} balls, B has {b}. Who has more?"
                    else:
                        a, b, c = random.randint(2, 5), random.randint(3, 6), random.randint(4, 8)
                        ans = a + b + c
                        opts, correct = make_options(ans, [a + b, b + c, a + c])
                        qvi = f"A={a}, B={b}, C={c}. Tổng = ?"
                        qen = f"A={a}, B={b}, C={c}. Total = ?"
                elif op == "set":
                    opts = ["Giao / Intersection", "Hợp / Union", "Bù / Complement"]
                    correct = 0
                    qvi = "Phần chung của 2 tập hợp gọi là gì?"
                    qen = "What is the common part of 2 sets called?"
                elif op == "logic":
                    opts = ["AND / Và", "OR / Hoặc", "NOT / Không"]
                    correct = random.randint(0, 1)
                    qvi = "'Mèo đen AND mèo trắng' có đúng không?"
                    qen = "'Black cat AND white cat' — is this true?"
                else:  # chess
                    opts = ["Xe / Rook", "Mã / Knight", "Tượng / Bishop"]
                    correct = 1
                    qvi = "Quân nào đi chữ L?"
                    qen = "Which piece moves in an L-shape?"

                exercises.append((gen_ex_id(lid, ex_i), lid, qvi, qen, opts, correct, "🧩",
                    "Suy nghĩ từng bước một.", "Think step by step.", ex_i))

    return lessons, exercises


def generate_vietnamese(grade, prefix, diff):
    lessons, exercises = [], []

    if grade == 2:
        topics = [("Từ ghép", "Compound words"), ("Câu đơn", "Simple sentences"),
                  ("Đọc hiểu", "Reading"), ("Thanh điệu", "Tones"), ("Chính tả", "Spelling")]
        count = 50
    else:
        topics = [("Đọc đoạn văn", "Paragraph reading"), ("Ngữ pháp", "Grammar"),
                  ("Viết văn", "Writing"), ("Đồng nghĩa/trái nghĩa", "Synonyms/Antonyms"), ("Chính tả", "Dictation")]
        count = 55

    for i in range(1, count + 1):
        lid = gen_id(f"{prefix}v", i)
        tidx = (i - 1) // (count // len(topics))
        if tidx >= len(topics):
            tidx = len(topics) - 1
        topic_vi, topic_en = topics[tidx]
        lessons.append((lid, "vietnamese", f"{topic_vi} (bài {i})", f"{topic_en} (lesson {i})", i, diff))

        ex_count = random.randint(2, 3)
        for ex_i in range(1, ex_count + 1):
            if tidx == 0:
                opts = ["trường học", "trường nhà", "trường cây"]
                correct = 0
                qvi = "Từ ghép của 'trường' là gì?"
                qen = "What compound word goes with 'school'?"
            elif tidx == 1:
                opts = ["Bé đi học.", "Học đi bé.", "Đi bé học."]
                correct = 0
                qvi = "Câu nào đúng?"
                qen = "Which sentence is correct?"
            elif tidx == 2:
                opts = ["Đi học", "Đi chơi", "Đi ngủ"]
                correct = 0
                qvi = "Bé An đi học. Bé An làm gì?"
                qen = "An goes to school. What does An do?"
            elif tidx == 3:
                opts = ["Hỏi", "Ngã", "Sắc"]
                correct = random.randint(0, 1)
                qvi = "Từ 'mã' có thanh gì?"
                qen = "What tone does 'mã' have?"
            else:
                opts = ["trường học", "trườn học", "trường họk"]
                correct = 0
                qvi = "Chọn từ viết đúng:"
                qen = "Which spelling is correct?"

            exercises.append((gen_ex_id(lid, ex_i), lid, qvi, qen, opts, correct, "📚",
                "Đọc kỹ và chọn đáp án đúng.", "Read carefully and choose correctly.", ex_i))

    return lessons, exercises


def generate_english(grade, prefix, diff):
    lessons, exercises = [], []

    if grade == 2:
        topics = [("Từ vựng", "Vocabulary"), ("Ngữ pháp", "Grammar"),
                  ("Đọc hiểu", "Reading"), ("Nghe", "Listening"), ("Viết", "Writing")]
        count = 50
    else:
        topics = [("Quá khứ", "Past tense"), ("Số nhiều", "Plural forms"),
                  ("Đọc hiểu", "Reading"), ("Hội thoại", "Conversation"), ("Nghe", "Listening")]
        count = 55

    vocab_items = [("apple", "🍎"), ("book", "📚"), ("cat", "🐱"), ("dog", "🐕"),
                   ("elephant", "🐘"), ("fish", "🐟"), ("grapes", "🍇"), ("house", "🏠"),
                   ("ice cream", "🍦"), ("jump", "🦘")]

    for i in range(1, count + 1):
        lid = gen_id(f"{prefix}e", i)
        tidx = (i - 1) // (count // len(topics))
        if tidx >= len(topics):
            tidx = len(topics) - 1
        topic_vi, topic_en = topics[tidx]
        lessons.append((lid, "english", f"{topic_vi} (bài {i})", f"{topic_en} (lesson {i})", i, diff))

        ex_count = random.randint(2, 3)
        for ex_i in range(1, ex_count + 1):
            if tidx == 0:
                if grade == 2:
                    w, icon = vocab_items[(i - 1) % 10]
                    wrong = [vocab_items[j][0] for j in range(10) if j != (i - 1) % 10][:2]
                    opts = [w, wrong[0], wrong[1]]
                    correct = 0
                    qvi = f"Từ tiếng Anh cho {icon}?"
                    qen = f"English word for {icon}?"
                else:
                    verb = random.choice(["play", "eat", "run", "sleep"])
                    opts = [f"{verb}ed", f"{verb}s", f"{verb}ing"]
                    correct = 0
                    qvi = f"Quá khứ của '{verb}'?"
                    qen = f"Past tense of '{verb}'?"
            elif tidx == 1:
                if grade == 2:
                    opts = ["is", "are", "am"]
                    correct = 0
                    qvi = "Chọn đúng: 'He ___ a student.'"
                    qen = "Choose correct: 'He ___ a student.'"
                else:
                    noun = random.choice(["cat", "dog", "book", "apple"])
                    opts = [f"{noun}s", f"{noun}es", f"{noun}"]
                    correct = 0
                    qvi = f"Số nhiều của '{noun}'?"
                    qen = f"Plural of '{noun}'?"
            elif tidx == 2:
                opts = ["Sleeps", "Runs", "Eats"]
                correct = 0
                qvi = "'The cat sleeps.' What does the cat do?"
                qen = "'The cat sleeps.' What does the cat do?"
            elif tidx == 3:
                opts = ["Apple", "Banana", "Grapes"]
                correct = random.randint(0, 2)
                qvi = "Nghe và chọn: 🍎 / 🍌 / 🍇"
                qen = "Listen and choose: 🍎 / 🍌 / 🍇"
            else:
                opts = ["apples", "apple", "an apples"]
                correct = 0
                qvi = "Viết câu: 'I like ___'"
                qen = "Write the sentence: 'I like ___'"

            exercises.append((gen_ex_id(lid, ex_i), lid, qvi, qen, opts, correct, "🇬🇧",
                "Đọc kỹ và chọn đáp án đúng.", "Read carefully and choose correctly.", ex_i))

    return lessons, exercises


def output_sql(lessons, exercises, service, grade):
    print(f"-- Auto-generated Grade {grade} Curriculum")
    print(f"-- Service: {service}")
    print(f"-- Total lessons: {len(lessons)}")
    print(f"-- Total exercises: {len(exercises)}")
    print()

    if service == "content":
        print("BEGIN;")
        print()

    print("-- Lessons")
    for l in lessons:
        lid, sid, tvi, ten, order, diff = l
        if service == "content":
            print(f"INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('{lid}', '{sid}', '{escape_sql(tvi)}', '{escape_sql(ten)}', {order}, {diff}, {grade}, FALSE) ON CONFLICT (id) DO NOTHING;")
        else:
            print(f"INSERT INTO language_lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('{lid}', '{sid}', '{escape_sql(tvi)}', '{escape_sql(ten)}', {order}, {diff}, {grade}, FALSE) ON CONFLICT (id) DO NOTHING;")

    print()
    print("-- Exercises")
    for e in exercises:
        eid, lid, qvi, qen, opts, correct, visual, hvi, hen, ex_order = e
        opts_sql = ", ".join([f"'{escape_sql(o)}'" for o in opts])
        if service == "content":
            print(f"INSERT INTO exercises (id, lesson_id, question_vi, question_en, options, correct_index, visual_asset, hint_vi, hint_en, exercise_order) VALUES ('{eid}', '{lid}', '{escape_sql(qvi)}', '{escape_sql(qen)}', ARRAY[{opts_sql}], {correct}, '{visual}', '{escape_sql(hvi)}', '{escape_sql(hen)}', {ex_order}) ON CONFLICT (id) DO NOTHING;")
        else:
            print(f"INSERT INTO language_exercises (id, lesson_id, exercise_type, question_vi, question_en, options, correct_index, visual_asset, hint_vi, hint_en, exercise_order, validation_mode, case_sensitive, diacritic_sensitive) VALUES ('{eid}', '{lid}', 'audio_mcq', '{escape_sql(qvi)}', '{escape_sql(qen)}', ARRAY[{opts_sql}], {correct}, '{visual}', '{escape_sql(hvi)}', '{escape_sql(hen)}', {ex_order}, 'exact', false, true) ON CONFLICT (id) DO NOTHING;")

    if service == "content":
        print()
        print("COMMIT;")


def main():
    parser = argparse.ArgumentParser(description="Generate curriculum SQL")
    parser.add_argument("--grade", type=int, required=True, choices=[2, 3])
    parser.add_argument("--service", type=str, required=True, choices=["content", "language"])
    args = parser.parse_args()

    prefix = f"g{args.grade}_"
    diff = args.grade

    all_lessons = []
    all_exercises = []

    if args.service == "content":
        for gen in [generate_numbers, generate_geometry, generate_measurement, generate_logic]:
            l, e = gen(args.grade, prefix, diff)
            all_lessons.extend(l)
            all_exercises.extend(e)
    else:
        for gen in [generate_vietnamese, generate_english]:
            l, e = gen(args.grade, prefix, diff)
            all_lessons.extend(l)
            all_exercises.extend(e)

    output_sql(all_lessons, all_exercises, args.service, args.grade)


if __name__ == "__main__":
    main()
