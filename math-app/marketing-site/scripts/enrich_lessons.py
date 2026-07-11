#!/usr/bin/env python3
"""Augment lessons.json with sample lesson titles + descriptions
for SEO purposes. Reads the live API and falls back to deterministic
sample titles for each (subject, grade) cell.
"""
from __future__ import annotations

import json
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LESSONS_JSON = ROOT / "src" / "data" / "lessons.json"

# Per-subject templates for generating sample lesson titles.
# (subject, grade_start, grade_end, [title_vi templates])
SAMPLE_TEMPLATES: dict[str, list[str]] = {
    "numbers": [
        "Đếm số từ 0–{n}",
        "Cộng trong phạm vi {n}",
        "Trừ trong phạm vi {n}",
        "So sánh {a} và {b}",
        "Điền số còn thiếu: {a}, ?, {b}",
        "Tìm số lớn nhất trong nhóm",
        "Bài toán có lời văn: mua {a} quả, cho {b} quả",
        "Sắp xếp thứ tự: {a}, {b}, {c}",
        "Cộng nhẩm nhanh",
        "Trừ nhẩm nhanh",
    ],
    "geometry": [
        "Nhận biết hình {shape}",
        "Đếm số cạnh của hình {shape}",
        "Tìm hình ẩn trong tranh",
        "Vẽ hình {shape} theo mẫu",
        "Ghép hình từ mảnh nhỏ",
        "Tìm hình trong đồ vật xung quanh",
        "So sánh độ dài hai đoạn thẳng",
        "Xác định vị trí: trên/dưới, trái/phải",
        "Đo chiều dài bằng thước",
    ],
    "measurement": [
        "Đo độ dài bằng thước (cm)",
        "So sánh nặng/nhẹ",
        "Đong nước bằng cốc (ml)",
        "Xem giờ trên đồng hồ",
        "Đếm tiền Việt Nam",
        "Đo nhiệt độ (độ C)",
        "Tính chu vi hình chữ nhật",
        "Tính diện tích phòng",
    ],
    "logic": [
        "Tìm quy luật: {a}, {b}, ?, {c}",
        "Tìm hình khác biệt",
        "Sắp xếp theo thứ tự",
        "Phân loại đồ vật",
        "Câu đố logic",
        "Puzzle ghép hình",
        "Tìm điểm chung",
        "Tìm điểm khác biệt",
    ],
    "algebra": [
        "Tìm quy luật dãy số",
        "Tìm x: x + {a} = {b}",
        "Tìm x: x − {a} = {b}",
        "Cân bằng phương trình đơn giản",
        "Tính giá trị biểu thức",
        "Điền số vào bảng số",
    ],
    "trigonometry": [
        "Vẽ và đo góc {n}°",
        "Tính sin({n}°)",
        "Tính cos({n}°)",
        "Tính tan({n}°)",
        "Giải tam giác vuông",
        "Bài toán chiều cao toà nhà",
    ],
    "statistics": [
        "Đếm và phân loại dữ liệu",
        "Vẽ biểu đồ cột",
        "Vẽ biểu đồ tròn",
        "Tính trung bình cộng",
        "Khảo sát và ghi chép",
        "So sánh nhóm số liệu",
    ],
    "arithmetic_2digit": [
        "{a} + {b} = ? (không nhớ)",
        "{a} + {b} = ? (có nhớ)",
        "{a} − {b} = ? (không nhớ)",
        "{a} − {b} = ? (có nhớ)",
        "Đặt tính rồi tính: {a} + {b}",
        "Đặt tính rồi tính: {a} − {b}",
        "Bài toán: có {a} quả, ăn {b} quả, còn ?",
    ],
    "arithmetic_3digit": [
        "{a} + {b} (có nhớ)",
        "{a} − {b} (có nhớ)",
        "Tính nhanh số tròn trăm",
        "Bài toán: cửa hàng có {a}K, bán {b}K, còn ?",
    ],
    "multiplication": [
        "Bảng cửu chương {n}",
        "{a} × {b} = ?",
        "Đếm nhóm: {a} nhóm × {b} cái",
        "Bài toán: {a} hộp, mỗi hộp {b} cái, tổng ?",
        "Tìm thừa số: {c} ÷ ? = {b}",
        "So sánh: {a} × {b} và {c} × {d}",
    ],
    "division": [
        "{a} ÷ {b} (chia hết)",
        "{a} ÷ {b} (có dư)",
        "Chia đồ vật thành {b} nhóm",
        "Bài toán: {a} cái kẹo chia cho {b} bạn",
        "Tìm thương và số dư",
    ],
    "fractions": [
        "Tô màu 1/{n} hình",
        "So sánh 1/{a} và 1/{b}",
        "1/{a} + 1/{b} (cùng mẫu)",
        "1/{a} − 1/{b} (cùng mẫu)",
        "Đổi phân số: 1/{a} = ?/{b}",
        "Bài toán: cắt bánh thành {n} phần bằng nhau",
    ],
    "decimals": [
        "Đổi: 1/{n} = 0.{nn}",
        "So sánh 0.{a} và 0.{b}",
        "{a}.{b} + {c}.{d} (cộng số thập phân)",
        "{a}.{b} − {c}.{d} (trừ số thập phân)",
        "Tính tiền: {a}K{n} + {b}K{m}",
    ],
    "perimeter": [
        "Chu vi hình vuông cạnh {n}cm",
        "Chu vi hình chữ nhật {a}cm × {b}cm",
        "Chu vi hình tam giác cân",
        "Bài toán: rào sân {a}m × {b}m",
    ],
    "area": [
        "Diện tích hình vuông cạnh {n}cm",
        "Diện tích hình chữ nhật {a}cm × {b}cm",
        "So sánh diện tích hai hình",
        "Bài toán: lát gạch phòng {a}m × {b}m",
    ],
    "angles": [
        "Đo góc {n}° bằng thước",
        "Phân biệt góc nhọn, vuông, tù",
        "Tìm góc vuông trong phòng",
        "Tổng 3 góc trong tam giác (= 180°)",
        "Bài toán: góc còn thiếu trong tam giác",
    ],
    "time_money": [
        "Xem giờ: {h}:{m}",
        "Bài toán: bây giờ {h}:{m}, sau 30 phút là mấy giờ?",
        "Đếm tiền: {a}K + {b}K = ?",
        "Mua {a} cái kẹo, mỗi cái {b}K, trả {c}K, được thối ?",
        "Quy đổi: {a}K = ? đồng",
    ],
    "volume": [
        "Đong nước: cốc {a}ml × {b} cốc = ?ml",
        "Thể tích hộp {a}cm × {b}cm × {c}cm",
        "Bài toán: bể nước {a}m × {b}m × {c}m chứa bao nhiêu lít?",
        "So sánh thể tích hai hộp",
    ],
    "speed": [
        "Tính tốc độ: đi {a}km trong {b} giờ",
        "Đổi: {a}km/h = ? m/s",
        "Bài toán: xe đi {a}km/h, trong {b} giờ đi được bao nhiêu km?",
        "So sánh tốc độ: xe đạp {a}km/h vs ô tô {b}km/h",
    ],
    "word_problems": [
        "Bài toán mua bán: mua {a} cái, mỗi cái {b}K, trả {c}K",
        "Bài toán thời gian: từ {h1}:{m1} đến {h2}:{m2} là bao lâu?",
        "Bài toán 2 bước: gấp {a} lần rồi trừ {b}",
        "Bài toán ngược: kết quả là {c}, tìm phép tính",
    ],
}

# For subjects not in the templates, use a generic placeholder
GENERIC_TEMPLATES = [
    "Bài tập cơ bản về {subject} lớp {grade}",
    "Luyện tập {subject} nâng cao",
    "Ôn tập {subject} lớp {grade}",
    "Bài tập {subject} có lời văn",
    "Trắc nghiệm {subject}",
]

SUBJECT_NAMES_VI = {
    "numbers": "Số học", "geometry": "Hình học", "measurement": "Đo lường",
    "logic": "Tư duy", "algebra": "Đại số", "trigonometry": "Lượng giác",
    "statistics": "Thống kê", "arithmetic_2digit": "Cộng trừ 2 chữ số",
    "arithmetic_3digit": "Cộng trừ 3 chữ số", "multiplication": "Bảng cửu chương",
    "division": "Phép chia", "fractions": "Phân số", "decimals": "Số thập phân",
    "perimeter": "Chu vi", "area": "Diện tích", "angles": "Góc",
    "time_money": "Thời gian & Tiền", "volume": "Thể tích", "speed": "Tốc độ",
    "word_problems": "Bài toán có lời văn",
}


def fill_template(template: str, grade: int) -> str:
    """Fill {n}, {a}, {b} etc placeholders with grade-appropriate numbers."""
    out = template
    # Common replacements
    base = max(2, grade)  # never less than 2 for kids
    out = out.replace("{n}", str(base * 5 + 3))
    out = out.replace("{a}", str(base * 2 + 1))
    out = out.replace("{b}", str(base + 2))
    out = out.replace("{c}", str(base * 3))
    out = out.replace("{d}", str(base * 4 + 1))
    out = out.replace("{h}", str((grade + 7) % 12 + 1))
    out = out.replace("{m}", str((grade * 7) % 60).zfill(2))
    out = out.replace("{h1}", str((grade + 6) % 12 + 1))
    out = out.replace("{h2}", str((grade + 7) % 12 + 1))
    out = out.replace("{m1}", "30")
    out = out.replace("{m2}", "45")
    out = out.replace("{nn}", str((grade * 3) % 9 + 1))
    out = out.replace("{subject}", "toán")
    out = out.replace("{shape}", "vuông" if grade <= 2 else "tam giác")
    return out


def main() -> None:
    data = json.loads(LESSONS_JSON.read_text())
    enriched = 0
    for key, cell in data.items():
        if cell.get("sample_titles_vi"):
            continue
        subject_id, grade_str = key.split("|")
        grade = int(grade_str)
        templates = SAMPLE_TEMPLATES.get(subject_id, GENERIC_TEMPLATES)
        # 5-7 sample titles per cell
        cell["sample_titles_vi"] = [
            fill_template(t, grade) for t in templates[:6]
        ]
        cell["sample_titles_en"] = [
            f"{t} (Grade {grade})" for t in cell["sample_titles_vi"]
        ]
        enriched += 1
    LESSONS_JSON.write_text(json.dumps(data, ensure_ascii=False, indent=2))
    print(f"Enriched {enriched} cells with sample titles")


if __name__ == "__main__":
    main()
