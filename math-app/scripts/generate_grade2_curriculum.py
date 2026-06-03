#!/usr/bin/env python3
"""
Generate Grade 2 curriculum SQL for content-service and language-service.

Usage:
    python generate_grade2_curriculum.py > ../backend/content/migrations/005_grade2_curriculum.sql
    python generate_grade2_curriculum.py --language > ../backend/language/migrations/004_grade2_curriculum.sql

Output: SQL INSERT statements for lessons and exercises.
"""

import sys
import random

random.seed(42)  # Reproducible

def gen_id(prefix, num):
    return f"{prefix}{num:04d}"

def gen_ex_id(lesson_id, ex_num):
    return f"ex_{lesson_id}_{ex_num}"

def escape_sql(s):
    return s.replace("'", "''")

# ============================================================
# GRADE 2 MATH CURRICULUM
# ============================================================

def generate_g2_numbers():
    """Grade 2 Numbers: 50 lessons
    L1-10: 2-digit addition with carrying
    L11-20: 2-digit subtraction with borrowing
    L21-30: Times tables (2x, 5x, 10x)
    L31-40: Word problems
    L41-50: Mixed practice
    """
    lessons = []
    exercises = []

    # L1-10: Addition with carrying
    for i in range(1, 11):
        lid = gen_id("g2_n", i)
        lessons.append((lid, "numbers",
            f"Cộng 2 chữ số (bài {i})",
            f"2-digit addition (lesson {i})",
            i, 2))
        a = random.randint(10, 89)
        b = random.randint(10, 99 - a)
        # Ensure carrying occurs (sum of units >= 10)
        a_units = a % 10
        if a_units == 0:
            a_units = random.randint(2, 9)
            a = (a // 10) * 10 + a_units
        b_units = random.randint(10 - a_units, 9)
        b = (b // 10) * 10 + b_units
        ans = a + b
        wrong1 = ans + random.randint(1, 5)
        wrong2 = ans - random.randint(1, 5)
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"{a} + {b} = ?",
            f"{a} + {b} = ?",
            [str(ans), str(wrong1), str(wrong2)], 0,
            "🔢",
            "Cộng hàng đơn vị trước, nhớ 1 sang hàng chục.",
            "Add units first, carry 1 to tens.", 1))

    # L11-20: Subtraction with borrowing
    for i in range(11, 21):
        lid = gen_id("g2_n", i)
        lessons.append((lid, "numbers",
            f"Trừ 2 chữ số (bài {i-10})",
            f"2-digit subtraction (lesson {i-10})",
            i, 2))
        a_tens = random.randint(3, 9)
        a_units = random.randint(0, 7)
        a = a_tens * 10 + a_units
        b_units = random.randint(a_units + 1, 9)
        b_tens = random.randint(1, a_tens - 1) if a_tens > 1 else 1
        b = b_tens * 10 + b_units
        ans = a - b
        wrong1 = ans + random.randint(1, 3)
        wrong2 = ans - random.randint(1, 3) if ans > 3 else ans + 5
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"{a} - {b} = ?",
            f"{a} - {b} = ?",
            [str(ans), str(wrong1), str(wrong2)], 0,
            "🔢",
            "Mượn 1 hàng chục sang hàng đơn vị rồi trừ.",
            "Borrow 1 ten to units, then subtract.", 1))

    # L21-30: Times tables (2x, 5x, 10x)
    tables = [2, 5, 10]
    for i in range(21, 31):
        lid = gen_id("g2_n", i)
        t = tables[min((i - 21) // 3, 2)]
        lessons.append((lid, "numbers",
            f"Bảng cửu chương {t} (bài {i-20})",
            f"Times table {t} (lesson {i-20})",
            i, 2))
        n = random.randint(2, 10)
        ans = t * n
        wrong1 = ans + t
        wrong2 = ans - t
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"{t} × {n} = ?",
            f"{t} × {n} = ?",
            [str(ans), str(wrong1), str(wrong2)], 0,
            "🔢",
            f"{t} cộng {n} lần, hoặc nhớ bảng cửu chương.",
            f"Add {t} {n} times, or recall times table.", 1))

    # L31-40: Word problems
    for i in range(31, 41):
        lid = gen_id("g2_n", i)
        lessons.append((lid, "numbers",
            f"Bài toán có lời (bài {i-30})",
            f"Word problems (lesson {i-30})",
            i, 2))
        a = random.randint(10, 50)
        b = random.randint(5, 30)
        ans = a + b
        wrong1 = a - b
        wrong2 = a + b + 5
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"Bé có {a} quả táo, mẹ cho thêm {b} quả. Bé có bao nhiêu quả?",
            f"You have {a} apples, mom gives you {b} more. How many?",
            [str(ans), str(wrong1), str(wrong2)], 0,
            "🍎",
            "Tìm từ khóa 'cho thêm' → dùng phép cộng.",
            "Keyword 'gives you more' → use addition.", 1))

    # L41-50: Mixed practice
    for i in range(41, 51):
        lid = gen_id("g2_n", i)
        lessons.append((lid, "numbers",
            f"Ôn tập số học (bài {i-40})",
            f"Mixed review (lesson {i-40})",
            i, 2))
        a = random.randint(10, 50)
        b = random.randint(5, 20)
        ans = a + b
        wrong1 = a - b
        wrong2 = a + b + 3
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"{a} + {b} = ?",
            f"{a} + {b} = ?",
            [str(ans), str(wrong1), str(wrong2)], 0,
            "🔢",
            "Đọc kỹ đề, xác định phép tính.",
            "Read carefully, identify the operation.", 1))

    return lessons, exercises


def generate_g2_geometry():
    """Grade 2 Geometry: 45 lessons
    L1-15: 3D shapes
    L16-30: Symmetry
    L31-45: Perimeter basics
    """
    lessons = []
    exercises = []

    shapes_3d_vi = ["hình lập phương", "hình cầu", "hình trụ", "hình chóp"]
    shapes_3d_en = ["cube", "sphere", "cylinder", "pyramid"]

    # L1-15: 3D shapes
    for i in range(1, 16):
        lid = gen_id("g2_g", i)
        sidx = (i - 1) % 4
        lessons.append((lid, "geometry",
            f"{shapes_3d_vi[sidx].capitalize()} (bài {i})",
            f"{shapes_3d_en[sidx].capitalize()} (lesson {i})",
            i, 2))
        correct = shapes_3d_vi[sidx]
        wrong = [shapes_3d_vi[j] for j in range(4) if j != sidx][:2]
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"Đây là hình gì? 🎲 → {correct}",
            f"What shape is this? 🎲 → {shapes_3d_en[sidx]}",
            [correct, wrong[0], wrong[1]], 0,
            "🎲",
            "Nhìn các mặt và cạnh để nhận dạng.",
            "Look at faces and edges to identify.", 1))

    # L16-30: Symmetry
    for i in range(16, 31):
        lid = gen_id("g2_g", i)
        lessons.append((lid, "geometry",
            f"Đối xứng (bài {i-15})",
            f"Symmetry (lesson {i-15})",
            i, 2))
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            "Hình này có đối xứng không? 🦋",
            "Is this shape symmetrical? 🦋",
            ["Có / Yes", "Không / No", "Không chắc / Not sure"], 0,
            "🦋",
            "Gấp hình theo đường giữa xem hai bên có khớp không.",
            "Fold along the middle to see if sides match.", 1))

    # L31-45: Perimeter
    for i in range(31, 46):
        lid = gen_id("g2_g", i)
        lessons.append((lid, "geometry",
            f"Chu vi (bài {i-30})",
            f"Perimeter (lesson {i-30})",
            i, 2))
        a = random.randint(3, 10)
        b = random.randint(3, 10)
        ans = 2 * (a + b)
        wrong1 = a * b  # area
        wrong2 = a + b
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"Chu vi hình chữ nhật dài {a}cm, rộng {b}cm = ?",
            f"Perimeter of rectangle {a}cm × {b}cm = ?",
            [f"{ans}cm", f"{wrong1}cm", f"{wrong2}cm"], 0,
            "📐",
            "Chu vi = (dài + rộng) × 2.",
            "Perimeter = (length + width) × 2.", 1))

    return lessons, exercises


def generate_g2_measurement():
    """Grade 2 Measurement: 45 lessons
    L1-15: Length (cm/m)
    L16-30: Weight (kg/g)
    L31-45: Time (minutes, half-hour) + Money (VND)
    """
    lessons = []
    exercises = []

    # L1-15: Length
    for i in range(1, 16):
        lid = gen_id("g2_m", i)
        lessons.append((lid, "measurement",
            f"Đo chiều dài (bài {i})",
            f"Measuring length (lesson {i})",
            i, 2))
        a = random.randint(5, 100)
        b = random.randint(5, 100)
        correct = "A" if a > b else "B"
        wrong = "B" if a > b else "A"
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"Đoạn A dài {a}cm, đoạn B dài {b}cm. Đoạn nào dài hơn?",
            f"Ruler A is {a}cm, ruler B is {b}cm. Which is longer?",
            [f"Đoạn {correct} / Ruler {correct}",
             f"Đoạn {wrong} / Ruler {wrong}",
             "Bằng nhau / Same"], 0,
            "📏",
            "So sánh số đo, số lớn hơn là dài hơn.",
            "Compare the numbers, larger = longer.", 1))

    # L16-30: Weight
    for i in range(16, 31):
        lid = gen_id("g2_m", i)
        lessons.append((lid, "measurement",
            f"Cân nặng (bài {i-15})",
            f"Weight (lesson {i-15})",
            i, 2))
        a = random.randint(1, 10)
        b = random.randint(1, 10)
        correct = "A" if a > b else "B"
        wrong = "B" if a > b else "A"
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"Vật A nặng {a}kg, vật B nặng {b}kg. Vật nào nặng hơn?",
            f"Object A is {a}kg, object B is {b}kg. Which is heavier?",
            [f"Vật {correct} / Object {correct}",
             f"Vật {wrong} / Object {wrong}",
             "Bằng nhau / Same"], 0,
            "⚖️",
            "So sánh số kg, số lớn hơn là nặng hơn.",
            "Compare kg, larger number = heavier.", 1))

    # L31-45: Time + Money
    for i in range(31, 46):
        lid = gen_id("g2_m", i)
        if i <= 37:
            lessons.append((lid, "measurement",
                f"Đọc đồng hồ (bài {i-30})",
                f"Telling time (lesson {i-30})",
                i, 2))
            h = random.randint(1, 12)
            ex_id = gen_ex_id(lid, 1)
            exercises.append((ex_id, lid,
                f"Đồng hồ chỉ {h}:30. Mấy giờ?",
                f"The clock shows {h}:30. What time?",
                [f"{h} giờ rưỡi / {h}:30",
                 f"{h} giờ / {h}:00",
                 f"{h+1} giờ / {h+1}:00"], 0,
                "🕐",
                "Kim phút chỉ số 6 là rưỡi.",
                "Minute hand at 6 means half past.", 1))
        else:
            lessons.append((lid, "measurement",
                f"Tiền (bài {i-37})",
                f"Money (lesson {i-37})",
                i, 2))
            a = random.randint(1, 10) * 1000
            b = random.randint(1, 10) * 2000
            ans = a + b
            wrong1 = abs(a - b)
            wrong2 = ans + 5000
            ex_id = gen_ex_id(lid, 1)
            exercises.append((ex_id, lid,
                f"Bút {a}đ + vở {b}đ = ?",
                f"Pen {a} VND + notebook {b} VND = ?",
                [f"{ans}đ", f"{wrong1}đ", f"{wrong2}đ"], 0,
                "💵",
                "Cộng hai số tiền lại.",
                "Add both amounts together.", 1))

    return lessons, exercises


def generate_g2_logic():
    """Grade 2 Logic: 45 lessons
    L1-15: Multi-step patterns
    L16-30: Sorting by multiple criteria
    L31-45: Basic Sudoku / Venn
    """
    lessons = []
    exercises = []

    # L1-15: Patterns
    for i in range(1, 16):
        lid = gen_id("g2_l", i)
        lessons.append((lid, "logic",
            f"Dãy số (bài {i})",
            f"Number patterns (lesson {i})",
            i, 2))
        d = random.randint(2, 5)
        a = random.randint(1, 20)
        seq = [a, a + d, a + 2*d]
        ans = a + 3*d
        wrong1 = a + 2*d
        wrong2 = a + 4*d
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            f"Số tiếp theo: {seq[0]}, {seq[1]}, {seq[2]}, __?",
            f"Next number: {seq[0]}, {seq[1]}, {seq[2]}, __?",
            [str(ans), str(wrong1), str(wrong2)], 0,
            "🔢",
            f"Cộng thêm {d} mỗi lần.",
            f"Add {d} each time.", 1))

    # L16-30: Sorting
    for i in range(16, 31):
        lid = gen_id("g2_l", i)
        lessons.append((lid, "logic",
            f"Phân loại (bài {i-15})",
            f"Sorting (lesson {i-15})",
            i, 2))
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            "Con nào có 4 chân: 🐕 🐦 🐟?",
            "Which has 4 legs: 🐕 🐦 🐟?",
            ["🐕 Dog", "🐦 Bird", "🐟 Fish"], 0,
            "🐾",
            "Đếm số chân của mỗi con.",
            "Count legs of each animal.", 1))

    # L31-45: Venn / Sudoku
    for i in range(31, 46):
        lid = gen_id("g2_l", i)
        lessons.append((lid, "logic",
            f"Suy luận (bài {i-30})",
            f"Reasoning (lesson {i-30})",
            i, 2))
        ex_id = gen_ex_id(lid, 1)
        exercises.append((ex_id, lid,
            "A có 2 quả bóng, B có 3 quả. Ai có nhiều hơn?",
            "A has 2 balls, B has 3. Who has more?",
            ["A", "B", "Bằng nhau / Same"], 1,
            "⚽",
            "So sánh số lượng.",
            "Compare the amounts.", 1))

    return lessons, exercises


def generate_g2_vietnamese():
    """Grade 2 Vietnamese: 50 lessons"""
    lessons = []
    exercises = []

    topics = [
        ("Từ ghép", "Compound words"),
        ("Câu đơn", "Simple sentences"),
        ("Đọc hiểu", "Reading comprehension"),
        ("Thanh điệu", "Tone practice"),
        ("Chính tả", "Spelling"),
    ]

    for i in range(1, 51):
        lid = gen_id("g2_v", i)
        tidx = (i - 1) // 10
        topic_vi, topic_en = topics[tidx]
        lessons.append((lid, "vietnamese",
            f"{topic_vi} (bài {i})",
            f"{topic_en} (lesson {i})",
            i, 2))
        ex_id = gen_ex_id(lid, 1)
        if tidx == 0:
            exercises.append((ex_id, lid,
                "Từ ghép của 'trường' là gì?",
                "What compound word goes with 'school'?",
                ["trường học", "trường nhà", "trường cây"], 0,
                "📚",
                "Nối hai từ có nghĩa.",
                "Combine two words that make sense.", 1))
        elif tidx == 1:
            exercises.append((ex_id, lid,
                "Câu nào đúng: 'Bé đi học.' / 'Học đi bé.' / 'Đi bé học.'",
                "Which sentence is correct?",
                ["Bé đi học. / Child goes to school.",
                 "Học đi bé. / School goes child.",
                 "Đi bé học. / Goes child school."], 0,
                "✍️",
                "Chủ ngữ đứng trước, động từ đứng sau.",
                "Subject first, verb after.", 1))
        elif tidx == 2:
            exercises.append((ex_id, lid,
                "Bé An đi học. Bé An làm gì?",
                "An goes to school. What does An do?",
                ["Đi học / Go to school", "Đi chơi / Play", "Đi ngủ / Sleep"], 0,
                "📖",
                "Đọc kỹ câu chuyện rồi chọn đáp án.",
                "Read carefully then choose.", 1))
        elif tidx == 3:
            exercises.append((ex_id, lid,
                "Từ 'mã' có thanh gì?",
                "What tone does 'mã' have?",
                ["Hỏi / Hoi", "Ngã / Nga", "Sắc / Sac"], 1,
                "🎵",
                "Nghe và phân biệt thanh hỏi/ngã.",
                "Listen and distinguish hoi/nga tones.", 1))
        else:
            exercises.append((ex_id, lid,
                "Chọn từ viết đúng: 'trường học' / 'trườn học' / 'trường họk'",
                "Which spelling is correct?",
                ["trường học", "trườn học", "trường họk"], 0,
                "✏️",
                "Nhìn kỹ chữ cái và thanh điệu.",
                "Check letters and tones carefully.", 1))

    return lessons, exercises


def generate_g2_english():
    """Grade 2 English: 50 lessons"""
    lessons = []
    exercises = []

    topics = [
        ("Từ vựng", "Vocabulary"),
        ("Ngữ pháp", "Grammar"),
        ("Đọc hiểu", "Reading"),
        ("Nghe", "Listening"),
        ("Viết", "Writing"),
    ]

    vocab_items = [
        ("apple", "🍎"), ("book", "📚"), ("cat", "🐱"), ("dog", "🐕"),
        ("elephant", "🐘"), ("fish", "🐟"), ("grapes", "🍇"), ("house", "🏠"),
        ("ice cream", "🍦"), ("jump", "🦘"),
    ]

    for i in range(1, 51):
        lid = gen_id("g2_e", i)
        tidx = (i - 1) // 10
        topic_vi, topic_en = topics[tidx]
        lessons.append((lid, "english",
            f"{topic_vi} (bài {i})",
            f"{topic_en} (lesson {i})",
            i, 2))
        ex_id = gen_ex_id(lid, 1)
        if tidx == 0:
            w, icon = vocab_items[(i - 1) % 10]
            wrong = [vocab_items[j][0] for j in range(10) if j != (i - 1) % 10][:2]
            exercises.append((ex_id, lid,
                f"Từ tiếng Anh cho {icon}?",
                f"English word for {icon}?",
                [w, wrong[0], wrong[1]], 0,
                icon,
                "Nhớ từ vựng đã học.",
                "Remember the vocabulary.", 1))
        elif tidx == 1:
            exercises.append((ex_id, lid,
                "Chọn đúng: 'He ___ a student.'",
                "Choose correct: 'He ___ a student.'",
                ["is", "are", "am"], 0,
                "✍️",
                "He/She + is, They + are.",
                "He/She uses 'is'.", 1))
        elif tidx == 2:
            exercises.append((ex_id, lid,
                "'The cat sleeps.' What does the cat do?",
                "'The cat sleeps.' What does the cat do?",
                ["Sleeps", "Runs", "Eats"], 0,
                "📖",
                "Read the sentence and find the verb.",
                "Read the sentence and find the verb.", 1))
        elif tidx == 3:
            exercises.append((ex_id, lid,
                "Nghe và chọn: 🍎 / 🍌 / 🍇",
                "Listen and choose: 🍎 / 🍌 / 🍇",
                ["Apple", "Banana", "Grapes"], 0,
                "🎧",
                "Nghe kỹ từ được đọc.",
                "Listen carefully to the word.", 1))
        else:
            exercises.append((ex_id, lid,
                "Viết câu: 'I like ___' (chọn từ)",
                "Write the sentence: 'I like ___'",
                ["apples", "apple", "an apples"], 0,
                "✏️",
                "Danh từ số nhiều sau 'like'.",
                "Use plural noun after 'like'.", 1))

    return lessons, exercises


def output_sql(lessons, exercises, service="content"):
    print("-- Auto-generated Grade 2 Curriculum")
    print("-- Service:", service)
    print("-- Total lessons:", len(lessons))
    print("-- Total exercises:", len(exercises))
    print()

    if service == "content":
        print("BEGIN;")
        print()

    print("-- Lessons")
    for l in lessons:
        lid, sid, tvi, ten, order, diff = l
        if service == "content":
            print(f"INSERT INTO lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('{lid}', '{sid}', '{escape_sql(tvi)}', '{escape_sql(ten)}', {order}, {diff}, 2, FALSE) ON CONFLICT (id) DO NOTHING;")
        else:
            print(f"INSERT INTO language_lessons (id, subject_id, title_vi, title_en, lesson_order, difficulty, grade, is_premium) VALUES ('{lid}', '{sid}', '{escape_sql(tvi)}', '{escape_sql(ten)}', {order}, {diff}, 2, FALSE) ON CONFLICT (id) DO NOTHING;")

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
    service = "content"
    if "--language" in sys.argv:
        service = "language"

    all_lessons = []
    all_exercises = []

    if service == "content":
        for gen in [generate_g2_numbers, generate_g2_geometry, generate_g2_measurement, generate_g2_logic]:
            l, e = gen()
            all_lessons.extend(l)
            all_exercises.extend(e)
    else:
        for gen in [generate_g2_vietnamese, generate_g2_english]:
            l, e = gen()
            all_lessons.extend(l)
            all_exercises.extend(e)

    output_sql(all_lessons, all_exercises, service)


if __name__ == "__main__":
    main()
