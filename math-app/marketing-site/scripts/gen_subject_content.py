#!/usr/bin/env python3
"""Generate per-subject outcomes + exercise-types JSON files for the
HocVui marketing site. Each subject gets 2 files:
  - src/data/outcomes/{subject}.json — what kids learn + parent tips
  - src/data/exercise-types/{subject}.json — types of exercises

Output is checked into the repo. Re-run only when content changes.
"""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
OUTCOMES = ROOT / "src" / "data" / "outcomes"
TYPES = ROOT / "src" / "data" / "exercise-types"
OUTCOMES.mkdir(parents=True, exist_ok=True)
TYPES.mkdir(parents=True, exist_ok=True)

# (subject_id, name_vi, name_en, outcomes_vi, exercise_types_vi, parent_tip_vi)
DATA = [
    (
        "numbers",
        "Số học",
        "Numbers",
        [
            "Đếm, đọc, viết các số tự nhiên trong phạm vi 100",
            "So sánh hai số (lớn hơn, nhỏ hơn, bằng) và sắp xếp theo thứ tự",
            "Cộng trừ trong phạm vi 10 (không nhớ)",
            "Cộng trừ trong phạm vi 100 (có nhớ và không nhớ)",
            "Giải bài toán có lời văn đơn giản (1 bước)",
            "Nhận biết số chẵn, số lẻ",
            "Làm quen với phép nhân, phép chia cơ bản",
        ],
        [
            "Đếm số lượng đồ vật (kéo thả, tô màu)",
            "Điền số còn thiếu trong dãy số",
            "Tính nhẩm nhanh (cộng trừ)",
            "Bài toán có lời văn ngắn",
            "Sắp xếp số theo thứ tự tăng/giảm dần",
            "Tìm số lớn nhất / nhỏ nhất trong nhóm",
        ],
        "Bé mới làm quen với số nên dùng que tính, viên bi, hoặc ngón tay để đếm. Khuyến khích bé tự nghĩ trước khi xem đáp án. Sai không sao — quan trọng là bé hiểu bản chất.",
    ),
    (
        "geometry",
        "Hình học",
        "Geometry",
        [
            "Nhận biết các hình phẳng: tròn, vuông, tam giác, chữ nhật, lục giác",
            "Nhận biết khối 3D: cầu, lập phương, hộp chữ nhật, trụ, nón",
            "Đếm số cạnh, số đỉnh, số mặt của các hình",
            "So sánh độ dài, chiều cao, chiều rộng giữa các đối tượng",
            "Xác định vị trí: trên/dưới, trái/phải, trong/ngoài",
            "Tìm hình trong tự nhiên và đồ vật xung quanh",
        ],
        [
            "Kéo thả hình vào đúng vị trí",
            "Đếm cạnh và đỉnh của hình",
            "Tìm hình ẩn trong bức tranh lớn",
            "Vẽ hình theo yêu cầu",
            "Ghép hình từ nhiều mảnh nhỏ",
        ],
        "Cho bé chơi với khối gỗ, lego, hộp các tông — vừa vui vừa học hình. Đi dạo ngoài trời, hỏi bé 'chiếc lá này hình gì?' là cách học tự nhiên nhất.",
    ),
    (
        "measurement",
        "Đo lường",
        "Measurement",
        [
            "Đo độ dài bằng thước (cm, m)",
            "So sánh khối lượng nặng/nhẹ giữa các vật",
            "Đo dung tích bằng cốc đong (ml, l)",
            "Xem đồng hồ (giờ, phút)",
            "Nhận biết các loại tiền Việt Nam (đồng) và quy đổi đơn giản",
            "Đọc nhiệt kế (độ C)",
        ],
        [
            "Đo chiều dài bàn tay, bước chân bằng thước",
            "Cân các đồ vật trong nhà (trái cây, sách, đồ chơi)",
            "Xem giờ trên đồng hồ thật — hỏi bé 'bây giờ là mấy giờ?'",
            "Mua sắm giả lập — dùng tiền để tính tổng, trả lại tiền thừa",
            "Đong nước bằng các cốc khác nhau",
        ],
        "Đo lường là kỹ năng sống quan trọng. Cho bé tập đo mọi thứ trong nhà: bàn, sách, đồ chơi. Đi chợ cùng bé, để bé tự tính tiền.",
    ),
    (
        "logic",
        "Tư duy",
        "Logic",
        [
            "Nhận biết quy luật đơn giản (màu sắc, hình dạng, số)",
            "Tìm điểm khác biệt giữa hai hình",
            "Phân loại đồ vật theo nhóm",
            "Giải câu đố logic (vd: ai cao nhất?)",
            "Sắp xếp theo thứ tự (tăng dần, giảm dần)",
            "Tìm quy luật và điền vào chỗ trống",
            "Tư duy phản biện (đúng/sai, tại sao)",
        ],
        [
            "Puzzle ghép hình theo mẫu",
            "Tìm hình khác biệt trong nhóm",
            "Sắp xếp thẻ số/thẻ màu theo quy luật",
            "Câu đố Sudoku mini cho bé",
            "Trò chơi 'tìm quy luật' với đồ vật thật",
        ],
        "Tư duy logic phát triển qua chơi. Cho bé chơi puzzle, xếp hình, sudoku mini. Hỏi 'tại sao' nhiều hơn 'là gì' — đó là cách rèn tư duy.",
    ),
    (
        "algebra",
        "Đại số",
        "Algebra",
        [
            "Tìm quy luật trong dãy số",
            "Điền số còn thiếu trong dãy số có quy luật",
            "Phép tính với số chưa biết (tìm x)",
            "Cộng trừ số âm (giới thiệu)",
            "Biểu thức đơn giản (a + b, a - b)",
        ],
        [
            "Tìm số tiếp theo trong dãy số",
            "Tìm x trong phép tính (x + 5 = 12)",
            "Điền vào bảng số theo quy luật",
            "Cân bằng phương trình đơn giản bằng hình ảnh",
        ],
        "Đại số không khó như tên gọi. Bắt đầu bằng các bài toán tìm quy luật trong dãy số, sau đó dần dần tới tìm x. Dùng đồ vật thật (kẹo, viên bi) để minh hoạ.",
    ),
    (
        "trigonometry",
        "Lượng giác",
        "Trigonometry",
        [
            "Hiểu khái niệm góc (góc nhọn, góc vuông, góc tù)",
            "Làm quen với hàm sin, cos, tan cơ bản",
            "Tính cạnh và góc trong tam giác vuông",
            "Áp dụng vào bài toán thực tế (chiều cao, khoảng cách)",
        ],
        [
            "Vẽ và đo góc bằng thước đo góc",
            "Tính sin/cos/tan cho góc đặc biệt (30°, 45°, 60°)",
            "Giải tam giác vuông",
            "Bài toán thực tế: chiều cao toà nhà, độ dốc cầu",
        ],
        "Lượng giác trừu tượng — đợi bé 12+ tuổi. Dùng hình ảnh trực quan: vẽ tam giác, đo cạnh, tính tỉ số. App có hình minh hoạ tương tác cho mỗi bài.",
    ),
    (
        "statistics",
        "Thống kê",
        "Statistics",
        [
            "Đếm và phân loại dữ liệu",
            "Đọc bảng số liệu đơn giản",
            "Vẽ biểu đồ cột, biểu đồ tròn cơ bản",
            "Tính trung bình cộng của 2-3 số",
            "So sánh các nhóm số liệu",
            "Hiểu khái niệm 'nhiều nhất', 'ít nhất', 'bằng nhau'",
        ],
        [
            "Đếm số lượng trái cây trong giỏ, vẽ biểu đồ cột",
            "Khảo sát lớp: 'ai thích màu gì?' rồi vẽ biểu đồ",
            "Tính điểm trung bình của các môn",
            "So sánh chiều cao các bạn trong lớp",
        ],
        "Thống kê xung quanh ta. Cho bé đếm đồ vật, khảo sát gia đình 'ai thích ăn gì?', rồi cùng vẽ biểu đồ. Bé sẽ thấy Toán hữu ích trong đời sống.",
    ),
    (
        "arithmetic_2digit",
        "Cộng trừ 2 chữ số",
        "2-digit arithmetic",
        [
            "Cộng hai số có 2 chữ số (không nhớ)",
            "Cộng hai số có 2 chữ số (có nhớ)",
            "Trừ hai số có 2 chữ số (không nhớ)",
            "Trừ hai số có 2 chữ số (có nhớ)",
            "Giải bài toán có lời văn với phép cộng trừ 2 chữ số",
        ],
        [
            "Tính cột dọc (đặt tính theo hàng dọc)",
            "Tính nhẩm nhanh",
            "Bài toán có lời văn",
            "Sắp xếp phép tính theo thứ tự",
            "Tìm lỗi sai trong phép tính",
        ],
        "Luyện tập cộng trừ 2 chữ số mỗi ngày 15 phút. Dùng que tính hoặc bút vẽ hàng dọc để bé thấy rõ quy trình nhớ.",
    ),
    (
        "arithmetic_3digit",
        "Cộng trừ 3 chữ số",
        "3-digit arithmetic",
        [
            "Cộng hai số có 3 chữ số (không nhớ, có nhớ)",
            "Trừ hai số có 3 chữ số (không nhớ, có nhớ)",
            "Tính nhẩm nhanh với số tròn trăm",
            "Giải bài toán có lời văn nhiều bước",
        ],
        [
            "Đặt tính theo cột dọc với số 3 chữ số",
            "Bài toán có lời văn 2 bước",
            "So sánh kết quả (lớn hơn / nhỏ hơn)",
            "Tính chu vi, diện tích đơn giản",
        ],
        "Bé đã vững 2 chữ số mới nên lên 3 chữ số. Luyện bằng cách cộng trừ tiền mua sắm: 'Mẹ mua 250K đồng rau, 350K đồng thịt, tổng bao nhiêu?'",
    ),
    (
        "multiplication",
        "Bảng cửu chương",
        "Multiplication tables",
        [
            "Hiểu phép nhân là phép cộng lặp lại (3 x 4 = 3+3+3+3)",
            "Học thuộc bảng cửu chương từ 2 đến 9",
            "Nhân số có 1 chữ số với số có 2 chữ số (không nhớ, có nhớ)",
            "Giải bài toán có lời văn về phép nhân",
            "Mẹo học bảng cửu chương nhanh",
        ],
        [
            "Bảng cửu chương tương tác (xoay, lật thẻ)",
            "Bài toán đếm nhóm (có 4 nhóm, mỗi nhóm 5 quả, tổng?)",
            "Bài toán có lời văn về tiền, đồ vật",
            "Trò chơi ghép cặp (phép tính ↔ kết quả)",
        ],
        "Đừng ép bé học thuộc lòng — hãy cho bé hiểu bản chất phép nhân là gì. Dùng đồ vật thật (kẹo, viên bi) để xếp nhóm. Sau khi hiểu, học thuộc sẽ dễ hơn nhiều.",
    ),
    (
        "division",
        "Phép chia",
        "Division",
        [
            "Hiểu phép chia là phép chia thành các nhóm bằng nhau",
            "Chia có dư (12 chia 5 = 2 dư 2)",
            "Quan hệ ngược của phép nhân (12 ÷ 3 = 4 vì 3 × 4 = 12)",
            "Giải bài toán có lời văn về phép chia",
            "Chia số có 2 chữ số cho số có 1 chữ số",
        ],
        [
            "Chia đồ vật thành các nhóm bằng nhau (kẹo, viên bi)",
            "Bài toán chia có dư",
            "Bài toán tìm thừa số (12 ÷ ? = 3)",
            "Bài toán có lời văn",
        ],
        "Phép chia khó hơn phép nhân. Dùng đồ vật thật: 'Mẹ có 12 cái kẹo, muốn chia đều cho 3 bạn, mỗi bạn được mấy cái?' Bé thấy trực quan sẽ hiểu nhanh hơn.",
    ),
    (
        "fractions",
        "Phân số",
        "Fractions",
        [
            "Hiểu khái niệm phân số (1/2 = một nửa)",
            "Đọc và viết phân số cơ bản",
            "So sánh phân số cùng mẫu số",
            "Cộng trừ phân số cùng mẫu số",
            "Phân số trong đời sống (1/2 cái bánh, 1/4 giờ)",
        ],
        [
            "Cắt bánh, pizza thành các phần bằng nhau",
            "Tô màu 1/2, 1/3, 1/4 hình",
            "So sánh hai phân số",
            "Cộng trừ phân số cùng mẫu",
        ],
        "Phân số trừu tượng — dùng đồ ăn thật: cắt bánh mì, bổ cam. Bé thấy '1/2 quả cam' thật sự là nửa quả cam sẽ hiểu ngay. Bắt đầu bằng 1/2, 1/4 trước khi tới phân số phức tạp.",
    ),
    (
        "decimals",
        "Số thập phân",
        "Decimals",
        [
            "Hiểu số thập phân (0.5 = 1/2 = nửa)",
            "Đọc và viết số thập phân có 1-2 chữ số sau dấu phẩy",
            "So sánh số thập phân",
            "Cộng trừ số thập phân",
            "Liên hệ số thập phân với tiền tệ (1.5K = 1K500)",
        ],
        [
            "Đổi phân số đơn giản sang số thập phân",
            "Cộng trừ số thập phân theo cột dọc",
            "Tính tiền mua sắm (3.5K + 2.5K)",
            "So sánh số thập phân (0.7 vs 0.65)",
        ],
        "Dùng tiền Việt Nam để dạy số thập phân: 1500đ = 1.5K, 2500đ = 2.5K. Bé tự tính tiền mua sắm sẽ hiểu rất nhanh.",
    ),
    (
        "perimeter",
        "Chu vi",
        "Perimeter",
        [
            "Hiểu chu vi là tổng độ dài các cạnh của hình",
            "Tính chu vi hình vuông, hình chữ nhật",
            "Tính chu vi hình tam giác",
            "Áp dụng vào bài toán thực tế (rào sân, viền khung tranh)",
        ],
        [
            "Đo cạnh rồi cộng",
            "Bài toán tính chu vi sân, phòng",
            "Vẽ hình có chu vi cho trước",
        ],
        "Cho bé đo cạnh bàn, sách, cửa sổ rồi tính chu vi. Bé thấy chu vi ứng dụng thực tế sẽ học tốt hơn là chỉ làm bài tập trên giấy.",
    ),
    (
        "area",
        "Diện tích",
        "Area",
        [
            "Hiểu diện tích là phần bề mặt của hình",
            "Tính diện tích hình chữ nhật (dài × rộng)",
            "Tính diện tích hình vuông (cạnh × cạnh)",
            "Đổi đơn vị (cm², m²)",
            "So sánh diện tích hai hình",
        ],
        [
            "Tính diện tích phòng, sân, bàn",
            "Bài toán lát gạch, sơn tường",
            "So sánh diện tích hai hình chữ nhật",
        ],
        "Bé hiểu chu vi rồi mới tới diện tích. Dùng giấy ô vuông (1cm × 1cm) để bé đếm số ô = diện tích. Trực quan, dễ hiểu.",
    ),
    (
        "angles",
        "Góc",
        "Angles",
        [
            "Nhận biết góc nhọn, góc vuông, góc tù, góc bẹt",
            "Đo góc bằng thước đo góc (độ)",
            "So sánh hai góc",
            "Tính tổng các góc trong tam giác (= 180°)",
            "Tính tổng các góc trong tứ giác (= 360°)",
        ],
        [
            "Dùng thước đo góc thật để đo các góc trong nhà",
            "Xác định góc vuông trong phòng",
            "Bài toán tìm góc còn thiếu",
            "Vẽ góc theo độ cho trước",
        ],
        "Bé thích góc vì nó có hình ảnh rõ ràng. Cho bé tìm góc vuông trong phòng (góc tường, góc bàn, góc sách). Trực quan sẽ giúp bé nhớ lâu.",
    ),
    (
        "time_money",
        "Thời gian & Tiền",
        "Time & Money",
        [
            "Đọc giờ trên đồng hồ kim (giờ, phút, giờ rưỡi)",
            "Tính khoảng thời gian (1 tiếng rưỡi = 1h30)",
            "Đọc lịch (ngày, tháng, năm)",
            "Nhận biết các mệnh giá tiền Việt Nam (100đ, 200đ, 500đ, 1K, 2K, 5K, 10K, 20K, 50K, 100K, 200K, 500K)",
            "Quy đổi tiền (1K = 1000đ, 10K = 10000đ)",
            "Tính tổng tiền khi mua nhiều món",
            "Trả lại tiền thừa",
        ],
        [
            "Xem giờ trên đồng hồ thật (hỏi bé 'bây giờ mấy giờ?')",
            "Đếm tiền trong ví mẹ",
            "Mua sắm giả lập — bé làm người bán hàng",
            "Tính tổng tiền khi đi chợ cùng mẹ",
        ],
        "Đồng hồ tương tác CustomPaint trong app rất hiệu quả — bé kéo kim đồng hồ đến giờ bạn nói. Với tiền, cho bé đi chợ cùng và tự tính tiền.",
    ),
    (
        "volume",
        "Thể tích",
        "Volume",
        [
            "Hiểu thể tích là dung tích chứa đựng",
            "Đo thể tích bằng đơn vị (ml, l, cm³, m³)",
            "Tính thể tích hình hộp chữ nhật (dài × rộng × cao)",
            "Tính thể tích hình lập phương",
            "So sánh thể tích hai vật",
        ],
        [
            "Đong nước bằng các cốc khác nhau",
            "Bài toán tính thể tích bể nước, bể cá",
            "So sánh thể tích hộp các kích cỡ",
        ],
        "Bé hiểu diện tích rồi mới tới thể tích. Dùng hộp các kích cỡ, đổ nước vào để so sánh. Trực quan sẽ giúp bé hiểu 'thể tích' là gì.",
    ),
    (
        "speed",
        "Tốc độ",
        "Speed",
        [
            "Hiểu khái niệm tốc độ (quãng đường / thời gian)",
            "Tính tốc độ khi biết quãng đường và thời gian",
            "Đổi đơn vị tốc độ (km/h, m/s)",
            "Bài toán thực tế: xe đi từ A đến B mất bao lâu?",
        ],
        [
            "Bài toán tính thời gian đi học (nhà đến trường)",
            "So sánh tốc độ các phương tiện (xe đạp, ô tô, máy bay)",
            "Bài toán quãng đường / thời gian / tốc độ",
        ],
        "Tốc độ là khái niệm đời sống — bé quen từ nhỏ. Hỏi bé: 'mẹ lái xe 50km/h, đi 100km mất mấy tiếng?' Bé sẽ thấy Toán ứng dụng rất thực tế.",
    ),
    (
        "word_problems",
        "Bài toán có lời văn",
        "Word problems",
        [
            "Đọc hiểu đề bài (tìm thông tin quan trọng)",
            "Xác định phép tính cần dùng (cộng, trừ, nhân, chia)",
            "Giải bài toán 1 bước",
            "Giải bài toán 2 bước",
            "Trình bày bài giải rõ ràng",
        ],
        [
            "Bài toán về tiền, đồ vật, thời gian",
            "Bài toán nhiều bước (mua 3 cái kẹo, 2 cái bánh, tổng bao nhiêu?)",
            "Bài toán ngược (cho kết quả, tìm phép tính)",
        ],
        "Bài toán có lời văn là nơi bé dễ mất điểm nhất. Dạy bé kỹ năng 'đọc 3 lần, tóm tắt đề, vẽ sơ đồ, rồi mới tính'. Luyện tập mỗi ngày 2-3 bài là đủ.",
    ),
]


def main() -> None:
    for subject, name_vi, name_en, outcomes, ex_types, parent_tip in DATA:
        # Outcomes
        outcomes_data = {
            "name_vi": name_vi,
            "name_en": name_en,
            "outcomes": outcomes,
            "parent_tip": parent_tip,
        }
        (OUTCOMES / f"{subject}.json").write_text(
            json.dumps(outcomes_data, ensure_ascii=False, indent=2)
        )
        # Exercise types
        types_data = {
            "name_vi": name_vi,
            "name_en": name_en,
            "types": ex_types,
        }
        (TYPES / f"{subject}.json").write_text(
            json.dumps(types_data, ensure_ascii=False, indent=2)
        )
    print(f"Wrote {len(DATA)} outcome + {len(DATA)} exercise-type files to {OUTCOMES.parent.relative_to(ROOT)}/")


if __name__ == "__main__":
    main()
