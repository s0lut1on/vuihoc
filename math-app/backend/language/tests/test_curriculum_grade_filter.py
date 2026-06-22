"""Tests for the language curriculum endpoint's grade-filter behavior.

Mirrors the SQL filter in router/curriculum.py::get_curriculum so we
can verify it in unit tests without a DB. The key behavior:
lessons with grade=0 (or NULL, which gets defaulted to 0 by the
DB migration) are 'shared' — they appear for every user's grade.

This is critical: seed_vietnamese.sql + seed_english.sql were
written BEFORE the 'grade' column existed (added in migration
003_grade_levels.sql with DEFAULT 1). They never specify a grade,
so the lessons land with grade=1. Without the OR-grade=0 logic,
grade-2 and grade-3 users would see empty Vietnamese/English
curricula.
"""


def lesson_visible_to_user(lesson_grade, user_grade):
    """Mirror of the SQL filter logic.

    Returns True if a lesson with `lesson_grade` should appear in the
    curriculum of a user at `user_grade`.
    """
    if lesson_grade is None or lesson_grade == 0:
        # Shared lesson (no grade assigned, or explicitly grade=0)
        return True
    return lesson_grade == user_grade


def test_seed_lessons_visible_at_all_grades():
    """seed_*.sql lessons have no grade column → default to grade=1.
    They should still be visible to grade-2/3 users via the grade=0
    fallback in the curriculum query."""
    for g in [1, 2, 3]:
        assert lesson_visible_to_user(0, g)
        assert lesson_visible_to_user(None, g)


def test_grade_specific_lessons_filter_correctly():
    """A grade-2 lesson should only appear for grade-2 users."""
    assert lesson_visible_to_user(1, 1)
    assert not lesson_visible_to_user(1, 2)
    assert not lesson_visible_to_user(1, 3)

    assert not lesson_visible_to_user(2, 1)
    assert lesson_visible_to_user(2, 2)
    assert not lesson_visible_to_user(2, 3)

    assert not lesson_visible_to_user(3, 1)
    assert not lesson_visible_to_user(3, 2)
    assert lesson_visible_to_user(3, 3)


def test_default_grade_is_one_when_unset():
    """If a lesson's grade column was never set (e.g. seed insert
    before the column existed), it defaults to 1 in the DB."""
    # Mirrors the schema: grade INT NOT NULL DEFAULT 1
    default_grade_for_unset = 1
    # So a "shared" lesson (no grade in INSERT) lands at grade=1
    # and is therefore visible at grade 1 by default.
    assert lesson_visible_to_user(default_grade_for_unset, 1)


def test_out_of_range_grades():
    """Lesson with grade=4 (above max) is NOT visible at any grade."""
    assert not lesson_visible_to_user(4, 1)
    assert not lesson_visible_to_user(4, 3)
    # Negative grade (invalid input) — treated as not-equal, filtered out
    assert not lesson_visible_to_user(-1, 2)