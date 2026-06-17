"""Unit tests for the sub-subject unlock computation.

Tests the pure function `compute_unlocks` extracted from
`router/progress.py::get_detailed_progress`. The router wires DB rows
through this function; the function itself only does the unlock
arithmetic.
"""
from services.unlock import compute_unlocks


def _sub(id, subject_id="math", total=10, completed=0, display_order=0,
        name_vi="", name_en="", icon="📚", color="#fff"):
    return {
        "id": id,
        "subject_id": subject_id,
        "name_vi": name_vi,
        "name_en": name_en,
        "icon": icon,
        "color": color,
        "display_order": display_order,
        "total_lessons": total,
        "completed_lessons": completed,
        "stars_earned": completed * 3,
        "max_stars": total * 3,
        "completion_pct": round(completed / total, 2) if total else 0.0,
    }


def test_empty_list_returns_empty():
    assert compute_unlocks([]) == []


def test_single_subject_single_sub_is_unlocked():
    s = [_sub("a1", total=10, completed=0)]
    out = compute_unlocks(s)
    assert len(out) == 1
    assert out[0]["is_unlocked"] is True


def test_two_subs_first_zero_completion_locks_second():
    s = [
        _sub("a1", total=10, completed=0, display_order=0),
        _sub("a2", total=10, completed=0, display_order=1),
    ]
    out = compute_unlocks(s)
    assert out[0]["is_unlocked"] is True
    assert out[1]["is_unlocked"] is False


def test_two_subs_first_at_79_locks_second():
    s = [
        _sub("a1", total=100, completed=79, display_order=0),
        _sub("a2", total=10, completed=10, display_order=1),
    ]
    out = compute_unlocks(s)
    assert out[1]["is_unlocked"] is False, "79% < 80% threshold"


def test_two_subs_first_exactly_80_unlocks_second():
    s = [
        _sub("a1", total=10, completed=8, display_order=0),  # 0.8
        _sub("a2", total=10, completed=0, display_order=1),
    ]
    out = compute_unlocks(s)
    assert out[1]["is_unlocked"] is True, "80% == threshold"


def test_two_subs_first_100_unlocks_second():
    s = [
        _sub("a1", total=10, completed=10, display_order=0),
        _sub("a2", total=10, completed=0, display_order=1),
    ]
    out = compute_unlocks(s)
    assert out[1]["is_unlocked"] is True


def test_three_subs_only_chain_of_two_passes_80_unlocks_third():
    s = [
        _sub("a1", total=10, completed=10, display_order=0),  # 100%
        _sub("a2", total=10, completed=8, display_order=1),   # 80%
        _sub("a3", total=10, completed=0, display_order=2),
    ]
    out = compute_unlocks(s)
    assert [x["is_unlocked"] for x in out] == [True, True, True]


def test_three_subs_second_below_threshold_locks_third():
    s = [
        _sub("a1", total=10, completed=10, display_order=0),
        _sub("a2", total=10, completed=7, display_order=1),  # 70%
        _sub("a3", total=10, completed=0, display_order=2),
    ]
    out = compute_unlocks(s)
    assert [x["is_unlocked"] for x in out] == [True, True, False]


def test_two_independent_subjects_each_unlock_first():
    s = [
        _sub("math_n1", subject_id="math", total=10, completed=0),
        _sub("math_n2", subject_id="math", total=10, completed=0),
        _sub("vi_l1", subject_id="vietnamese", total=10, completed=0),
        _sub("vi_l2", subject_id="vietnamese", total=10, completed=0),
    ]
    out = compute_unlocks(s)
    ids_unlocked = [(x["id"], x["is_unlocked"]) for x in out]
    assert ids_unlocked == [
        ("math_n1", True),
        ("math_n2", False),
        ("vi_l1", True),
        ("vi_l2", False),
    ]


def test_unlock_respects_input_order():
    s = [
        _sub("z", display_order=3),
        _sub("a", display_order=1),
        _sub("m", display_order=2),
    ]
    out = compute_unlocks(s)
    assert [x["id"] for x in out] == ["z", "a", "m"]


def test_sub_with_zero_total_does_not_unlock_next_via_its_pct():
    # total=0 → pct=0.0, so prev "unlocked" would actually lock the next
    s = [
        _sub("a1", total=0, completed=0, display_order=0),
        _sub("a2", total=10, completed=10, display_order=1),
    ]
    out = compute_unlocks(s)
    # First is always unlocked regardless of pct
    assert out[0]["is_unlocked"] is True
    # Second depends on prev pct=0.0 < 0.80 → locked
    assert out[1]["is_unlocked"] is False


def test_custom_threshold_respected():
    s = [
        _sub("a1", total=100, completed=50, display_order=0),  # 50%
        _sub("a2", total=10, completed=0, display_order=1),
    ]
    out_default = compute_unlocks(s)
    assert out_default[1]["is_unlocked"] is False

    out_low = compute_unlocks(s, threshold=0.50)
    assert out_low[1]["is_unlocked"] is True, "50% should unlock at threshold=0.50"

    out_high = compute_unlocks(s, threshold=0.90)
    assert out_high[1]["is_unlocked"] is False


def test_all_other_fields_preserved():
    s = [_sub("a1", total=10, completed=5, name_vi="Phép cộng",
              name_en="Addition", icon="➕", color="#FF6B9D", display_order=7)]
    out = compute_unlocks(s)
    assert out[0]["name_vi"] == "Phép cộng"
    assert out[0]["name_en"] == "Addition"
    assert out[0]["icon"] == "➕"
    assert out[0]["color"] == "#FF6B9D"
    assert out[0]["display_order"] == 7
    assert out[0]["completion_pct"] == 0.5


def test_many_subs_in_one_subject_walks_entire_chain():
    # 5 subs, all at 100% — all unlock
    s = [_sub(f"a{i}", total=10, completed=10, display_order=i) for i in range(5)]
    out = compute_unlocks(s)
    assert all(x["is_unlocked"] for x in out)


def test_first_sub_with_zero_total_still_unlocked():
    # Edge: empty sub is still the "first" sub so always unlocked
    s = [_sub("a1", total=0, completed=0)]
    out = compute_unlocks(s)
    assert out[0]["is_unlocked"] is True
