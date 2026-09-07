"""Unit tests for the text-check service.

Covers remove_vietnamese_tones, levenshtein_distance, and validate_text.
Import pattern matches test_unlock.py (run with PYTHONPATH=src).
"""

import unicodedata

import pytest

from services.text_check import (
    levenshtein_distance,
    remove_vietnamese_tones,
    validate_text,
)


# ── remove_vietnamese_tones ───────────────────────────────────────────


def test_basic_vietnamese_tones_removed():
    assert remove_vietnamese_tones("chào") == "chao"
    assert remove_vietnamese_tones("xin chào") == "xin chao"


def test_all_a_variants():
    assert remove_vietnamese_tones("àáảãạăằắẳẵặâầấẩẫậ") == "a" * 17


def test_all_e_variants():
    assert remove_vietnamese_tones("èéẻẽẹêềếểễệ") == "e" * 11


def test_all_o_variants():
    assert remove_vietnamese_tones("òóỏõọôồốổỗộơờớởỡợ") == "o" * 17


def test_all_u_variants():
    assert remove_vietnamese_tones("ùúủũụưừứửữự") == "u" * 11


def test_all_i_variants():
    assert remove_vietnamese_tones("ìíỉĩị") == "i" * 5


def test_all_y_variants():
    assert remove_vietnamese_tones("ỳýỷỹỵ") == "y" * 5


def test_d_becomes_d():
    assert remove_vietnamese_tones("đ") == "d"


def test_uppercase_variants():
    assert remove_vietnamese_tones("Đ") == "D"
    assert remove_vietnamese_tones("À") == "A"


def test_mixed_text():
    assert remove_vietnamese_tones("Xin chào, tôi là học sinh") == "Xin chao, toi la hoc sinh"


def test_no_tones_unchanged():
    assert remove_vietnamese_tones("hello world") == "hello world"


def test_empty_string():
    assert remove_vietnamese_tones("") == ""


# ── levenshtein_distance ───────────────────────────────────────────────


def test_identical_strings():
    assert levenshtein_distance("hello", "hello") == 0


def test_one_insertion():
    assert levenshtein_distance("hello", "helloo") == 1


def test_one_deletion():
    assert levenshtein_distance("hello", "helo") == 1


def test_one_substitution():
    assert levenshtein_distance("hello", "hallo") == 1


def test_completely_different():
    assert levenshtein_distance("abc", "xyz") == 3


def test_empty_s1():
    assert levenshtein_distance("", "hello") == 5


def test_empty_s2():
    assert levenshtein_distance("hello", "") == 5


def test_both_empty():
    assert levenshtein_distance("", "") == 0


def test_vietnamese_text():
    # "chào" (4 chars, à is one char) vs "chao" (4 chars) → 1 substitution
    assert levenshtein_distance("chào", "chao") == 1


def test_case_difference():
    assert levenshtein_distance("Hello", "hello") == 1


# ── validate_text ─────────────────────────────────────────────────────


def test_exact_match():
    result = validate_text("hello", "hello", mode="exact")
    assert result["is_correct"] is True


def test_exact_mismatch():
    result = validate_text("hello", "world", mode="exact")
    assert result["is_correct"] is False


def test_exact_case_insensitive():
    result = validate_text("Hello", "hello", mode="exact", case_sensitive=False)
    assert result["is_correct"] is True


def test_exact_case_sensitive():
    result = validate_text("Hello", "hello", mode="exact", case_sensitive=True)
    assert result["is_correct"] is False


def test_contains_match():
    result = validate_text("the quick brown fox", "quick", mode="contains")
    assert result["is_correct"] is True


def test_contains_no_match():
    result = validate_text("hello world", "xyz", mode="contains")
    assert result["is_correct"] is False


def test_levenshtein_exact():
    result = validate_text("hello", "hello", mode="levenshtein", max_distance=0)
    assert result["is_correct"] is True


def test_levenshtein_within_distance():
    result = validate_text("hallo", "hello", mode="levenshtein", max_distance=1)
    assert result["is_correct"] is True


def test_levenshtein_beyond_distance():
    result = validate_text("hallo", "hello", mode="levenshtein", max_distance=0)
    assert result["is_correct"] is False


def test_diacritic_insensitive():
    result = validate_text("chao", "chào", mode="exact", diacritic_sensitive=False)
    assert result["is_correct"] is True


def test_diacritic_sensitive():
    result = validate_text("chao", "chào", mode="exact", diacritic_sensitive=True)
    assert result["is_correct"] is False


def test_nfc_normalization():
    nfc_e = "\xe9"                     # NFC: single codepoint U+00E9
    nfd_e = "e\u0301"                  # NFD: e + combining acute (U+0030 0301)
    assert unicodedata.normalize("NFC", nfc_e) != nfd_e  # raw strings differ
    result = validate_text(nfc_e, nfd_e, mode="exact")
    assert result["is_correct"] is True


def test_strip_whitespace():
    result = validate_text("  hello  ", "hello", mode="exact")
    assert result["is_correct"] is True


def test_feedback_vi_correct():
    result = validate_text("hello", "hello", mode="exact")
    assert result["feedback_vi"] == "Chính xác!"


def test_feedback_vi_incorrect():
    result = validate_text("hello", "world", mode="exact")
    assert "world" in result["feedback_vi"]
    assert result["feedback_vi"] == "Đáp án đúng là: world"


def test_feedback_en_correct():
    result = validate_text("hello", "hello", mode="exact")
    assert result["feedback_en"] == "Correct!"


def test_unknown_mode_defaults_to_exact():
    result = validate_text("hello", "hello", mode="unknown")
    assert result["is_correct"] is True


def test_distance_is_none_for_exact():
    result = validate_text("hello", "hello", mode="exact")
    assert result["distance"] is None


def test_distance_is_set_for_levenshtein():
    result = validate_text("hello", "hello", mode="levenshtein")
    assert isinstance(result["distance"], int)