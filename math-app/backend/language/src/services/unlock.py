"""Pure functions for computing per-sub-subject unlock status.

Extracted from `router/progress.py::get_detailed_progress` so the unlock
arithmetic can be unit-tested without a database session.
"""


def compute_unlocks(sub_stats: list[dict], *, threshold: float = 0.80) -> list[dict]:
    """Add `is_unlocked` to each sub-subject row in-place and return the list.

    The first sub-subject in each subject is always unlocked. Subsequent
    sub-subjects unlock when the previous one's `completion_pct` is at or
    above `threshold`. Sub-subjects are grouped by `subject_id` in the order
    they appear in `sub_stats`; rows are not reordered.

    The input dicts must contain `subject_id` and `completion_pct` (a float in
    [0, 1]). All other fields are preserved unchanged.
    """
    if not sub_stats:
        return sub_stats

    last_seen_subject: str | None = None
    last_pct: float = 0.0
    for row in sub_stats:
        if row.get("subject_id") != last_seen_subject:
            # New subject — first sub-subject is always unlocked
            row["is_unlocked"] = True
            last_seen_subject = row.get("subject_id")
            last_pct = float(row.get("completion_pct") or 0.0)
        else:
            # Same subject — unlock iff previous completed at/above threshold
            row["is_unlocked"] = last_pct >= threshold
            last_pct = float(row.get("completion_pct") or 0.0)
    return sub_stats
