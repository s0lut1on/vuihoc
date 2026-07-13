use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::PgPool;
use utoipa::ToSchema;

// ============================================================================
// DATABASE MODELS (sqlx::FromRow)
// ============================================================================

#[allow(dead_code)]
#[derive(Serialize, sqlx::FromRow, Clone, ToSchema)]
pub struct Subject {
    pub id: String,
    pub name_vi: String,
    pub name_en: String,
    pub description_vi: Option<String>,
    pub description_en: Option<String>,
    pub icon: String,
    pub color: String,
    pub display_order: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize, sqlx::FromRow, Clone, ToSchema)]
pub struct Lesson {
    pub id: String,
    pub subject_id: String,
    pub title_vi: String,
    pub title_en: String,
    pub description_vi: Option<String>,
    pub description_en: Option<String>,
    pub lesson_order: i32,
    pub difficulty: i32,
    pub is_premium: bool,
    pub grade: i32,
    pub created_at: DateTime<Utc>,
}

#[derive(Serialize, sqlx::FromRow, Clone, ToSchema)]
pub struct Exercise {
    pub id: String,
    pub lesson_id: String,
    pub question_vi: String,
    pub question_en: String,
    pub options: Vec<String>,
    pub correct_index: i32,
    pub visual_asset: String,
    pub hint_vi: Option<String>,
    pub hint_en: Option<String>,
    pub exercise_order: i32,
    pub created_at: DateTime<Utc>,
}

// ============================================================================
// CURRICULUM JOIN ROW (for single-query curriculum fetch)
// ============================================================================

#[derive(sqlx::FromRow, Clone)]
pub struct CurriculumRow {
    pub subject_id: String,
    pub subject_vi: String,
    pub subject_en: String,
    pub subject_icon: String,
    pub subject_color: String,
    pub lesson_id: Option<String>,
    pub title_vi: Option<String>,
    pub title_en: Option<String>,
    pub lesson_order: Option<i32>,
    pub difficulty: Option<i32>,
    pub is_premium: Option<bool>,
    pub ex_id: Option<String>,
    pub ex_question_vi: Option<String>,
    pub ex_question_en: Option<String>,
    pub ex_options: Option<Vec<String>>,
    pub ex_correct_index: Option<i32>,
    pub ex_visual_asset: Option<String>,
    pub ex_hint_vi: Option<String>,
    pub ex_hint_en: Option<String>,
    pub ex_exercise_order: Option<i32>,
}

// ============================================================================
// API RESPONSE MODELS (with nested exercises)
// ============================================================================

#[derive(Serialize, Clone, ToSchema)]
pub struct ApiLesson {
    pub id: String,
    pub title_vi: String,
    pub title_en: String,
    pub description_vi: Option<String>,
    pub description_en: Option<String>,
    pub lesson_order: i32,
    pub difficulty: i32,
    pub is_premium: bool,
    pub exercises: Vec<ApiExercise>,
}

#[derive(Serialize, Clone, ToSchema)]
pub struct ApiExercise {
    pub id: String,
    pub question_vi: String,
    pub question_en: String,
    pub options: Vec<String>,
    pub correct: i32,
    pub visual: String,
    pub hint_vi: Option<String>,
    pub hint_en: Option<String>,
    pub exercise_order: i32,
}

#[derive(Serialize, Clone, ToSchema)]
pub struct CurriculumSubject {
    pub subject_id: String,
    pub subject_vi: String,
    pub subject_en: String,
    pub subject_icon: String,
    pub subject_color: String,
    pub lessons: Vec<ApiLesson>,
}

#[derive(Serialize, Clone, ToSchema)]
pub struct SubjectSummary {
    pub id: String,
    pub name_vi: String,
    pub name_en: String,
    pub icon: String,
    pub color: String,
    pub lesson_count: i64,
}

/// Lightweight lesson row for the per-subject lesson list. No
/// exercises (those are fetched on-demand by the lesson screen via
/// `GET /api/content/lesson/:id`). Without this, the subject screen
/// would have to call `get_curriculum` and download ~1700 lessons +
/// ~1730 exercises (808KB JSON) just to render a list of 30-50
/// lesson cards.
#[derive(Serialize, sqlx::FromRow, Clone, ToSchema)]
pub struct LessonSummary {
    pub id: String,
    pub subject_id: String,
    pub title_vi: String,
    pub title_en: String,
    pub lesson_order: i32,
    pub difficulty: i32,
    pub is_premium: bool,
}

// ============================================================================
// APP STATE
// ============================================================================

#[derive(Clone)]
pub struct AppState {
    pub db: PgPool,
}

// ============================================================================
// QUERIES
// ============================================================================

impl AppState {
    pub async fn get_subjects(&self, grade: i32) -> Result<Vec<SubjectSummary>, sqlx::Error> {
        let rows: Vec<(String, String, String, String, String, i64)> = sqlx::query_as(
            r#"
            SELECT
                s.id,
                s.name_vi,
                s.name_en,
                s.icon,
                s.color,
                COUNT(l.id)::bigint AS lesson_count
            FROM subjects s
            LEFT JOIN lessons l ON l.subject_id = s.id AND l.grade = $1
            WHERE s.grade_min <= $1 AND s.grade_max >= $1
            GROUP BY s.id, s.name_vi, s.name_en, s.icon, s.color, s.display_order
            ORDER BY s.display_order
            "#,
        )
        .bind(grade)
        .fetch_all(&self.db)
        .await?;

        Ok(rows
            .into_iter()
            .map(
                |(id, name_vi, name_en, icon, color, lesson_count)| SubjectSummary {
                    id,
                    name_vi,
                    name_en,
                    icon,
                    color,
                    lesson_count,
                },
            )
            .collect())
    }

    pub async fn get_curriculum(&self, grade: i32) -> Result<Vec<CurriculumSubject>, sqlx::Error> {
        let rows = sqlx::query_as::<_, CurriculumRow>(
            r#"SELECT
                s.id as subject_id,
                s.name_vi as subject_vi,
                s.name_en as subject_en,
                s.icon as subject_icon,
                s.color as subject_color,
                l.id as lesson_id,
                l.title_vi,
                l.title_en,
                l.lesson_order,
                l.difficulty,
                l.is_premium,
                e.id as ex_id,
                e.question_vi as ex_question_vi,
                e.question_en as ex_question_en,
                e.options as ex_options,
                e.correct_index as ex_correct_index,
                e.visual_asset as ex_visual_asset,
                e.hint_vi as ex_hint_vi,
                e.hint_en as ex_hint_en,
                e.exercise_order as ex_exercise_order
            FROM subjects s
            -- Return lessons for the user's grade PLUS lessons marked
            -- 'shared' (grade = 0) so the grade-2/3 seeders and the
            -- grade-1 mass-curriculum both surface. Migration 003
            -- (mass curriculum) inserted ~1700 lessons without a
            -- grade, defaulting to 1 — without OR l.grade = 0 those
            -- would be hidden from grade-2/3 users.
            LEFT JOIN lessons l ON l.subject_id = s.id
                                  AND (l.grade = $1 OR l.grade = 0)
            LEFT JOIN exercises e ON e.lesson_id = l.id
            WHERE s.grade_min <= $1 AND s.grade_max >= $1
            ORDER BY s.display_order, l.lesson_order, e.exercise_order"#,
        )
        .bind(grade)
        .fetch_all(&self.db)
        .await?;

        let mut result: Vec<CurriculumSubject> = Vec::new();
        let mut current_subject_id: Option<String> = None;
        let mut current_lesson_id: Option<String> = None;
        let mut subject_idx: usize = 0;
        let mut lesson_idx: usize = 0;

        for row in rows {
            if current_subject_id.as_ref() != Some(&row.subject_id) {
                result.push(CurriculumSubject {
                    subject_id: row.subject_id.clone(),
                    subject_vi: row.subject_vi.clone(),
                    subject_en: row.subject_en.clone(),
                    subject_icon: row.subject_icon.clone(),
                    subject_color: row.subject_color.clone(),
                    lessons: Vec::new(),
                });
                subject_idx = result.len() - 1;
                current_subject_id = Some(row.subject_id.clone());
                current_lesson_id = None;
            }

            if let Some(ref lid) = row.lesson_id {
                if current_lesson_id.as_ref() != Some(lid) {
                    result[subject_idx].lessons.push(ApiLesson {
                        id: lid.clone(),
                        title_vi: row.title_vi.clone().unwrap_or_default(),
                        title_en: row.title_en.clone().unwrap_or_default(),
                        description_vi: None,
                        description_en: None,
                        lesson_order: row.lesson_order.unwrap_or(1),
                        difficulty: row.difficulty.unwrap_or(1),
                        is_premium: row.is_premium.unwrap_or(false),
                        exercises: Vec::new(),
                    });
                    lesson_idx = result[subject_idx].lessons.len() - 1;
                    current_lesson_id = Some(lid.clone());
                }

                if let Some(ref eid) = row.ex_id {
                    result[subject_idx].lessons[lesson_idx]
                        .exercises
                        .push(ApiExercise {
                            id: eid.clone(),
                            question_vi: row.ex_question_vi.clone().unwrap_or_default(),
                            question_en: row.ex_question_en.clone().unwrap_or_default(),
                            options: row.ex_options.clone().unwrap_or_default(),
                            correct: row.ex_correct_index.unwrap_or(0),
                            visual: row.ex_visual_asset.clone().unwrap_or_default(),
                            hint_vi: row.ex_hint_vi.clone(),
                            hint_en: row.ex_hint_en.clone(),
                            exercise_order: row.ex_exercise_order.unwrap_or(1),
                        });
                }
            }
        }

        Ok(result)
    }

    pub async fn get_lesson(&self, lesson_id: &str) -> Result<Option<ApiLesson>, sqlx::Error> {
        let lesson = sqlx::query_as::<_, Lesson>("SELECT * FROM lessons WHERE id = $1")
            .bind(lesson_id)
            .fetch_optional(&self.db)
            .await?;

        match lesson {
            Some(l) => {
                let exercises = sqlx::query_as::<_, Exercise>(
                    "SELECT * FROM exercises WHERE lesson_id = $1 ORDER BY exercise_order",
                )
                .bind(&l.id)
                .fetch_all(&self.db)
                .await?;

                let api_exercises: Vec<ApiExercise> = exercises
                    .into_iter()
                    .map(|e| ApiExercise {
                        id: e.id,
                        question_vi: e.question_vi,
                        question_en: e.question_en,
                        options: e.options,
                        correct: e.correct_index,
                        visual: e.visual_asset,
                        hint_vi: e.hint_vi,
                        hint_en: e.hint_en,
                        exercise_order: e.exercise_order,
                    })
                    .collect();

                Ok(Some(ApiLesson {
                    id: l.id,
                    title_vi: l.title_vi,
                    title_en: l.title_en,
                    description_vi: l.description_vi,
                    description_en: l.description_en,
                    lesson_order: l.lesson_order,
                    difficulty: l.difficulty,
                    is_premium: l.is_premium,
                    exercises: api_exercises,
                }))
            }
            None => Ok(None),
        }
    }

    /// Lightweight per-subject lesson list for the subject screen.
    /// Returns just the lesson metadata (id, title, order, difficulty,
    /// is_premium) — no exercise data. The lesson screen fetches
    /// the full lesson + exercises on-demand when the user clicks
    /// a lesson card.
    ///
    /// Indexes used: `idx_lessons_subject_grade_order` (added in
    /// migration 013) for the WHERE + ORDER BY. The grade = 0
    /// fallback mirrors the curriculum() query so shared lessons
    /// surface in the right grade.
    pub async fn get_subject_lessons(
        &self,
        subject_id: &str,
        grade: i32,
    ) -> Result<Vec<LessonSummary>, sqlx::Error> {
        let rows = sqlx::query_as::<_, LessonSummary>(
            r#"SELECT
                id,
                subject_id,
                title_vi,
                title_en,
                lesson_order,
                difficulty,
                is_premium
            FROM lessons
            WHERE subject_id = $1 AND (grade = $2 OR grade = 0)
            ORDER BY lesson_order"#,
        )
        .bind(subject_id)
        .bind(grade)
        .fetch_all(&self.db)
        .await?;

        Ok(rows)
    }
}

// ============================================================================
// BACKWARD COMPAT: static data for tests / offline fallback
// ============================================================================

pub fn get_curriculum_static() -> Vec<CurriculumSubject> {
    vec![
        CurriculumSubject {
            subject_id: "numbers".to_string(),
            subject_vi: "Số học".to_string(),
            subject_en: "Numbers".to_string(),
            subject_icon: "🔢".to_string(),
            subject_color: "#FFE8F0".to_string(),
            lessons: vec![static_lesson(
                "lesson_n1",
                "Đếm đến 10",
                "Count to 10",
                vec![static_ex(StaticExerciseParams {
                    id: "ex_n1_01",
                    question_vi: "Có bao nhiêu quả táo 🍎?",
                    question_en: "How many apples 🍎?",
                    options: vec!["3".into(), "5".into(), "4".into()],
                    correct: 1,
                    visual: "🍎🍎🍎🍎🍎",
                    hint_vi: "Đếm từng quả táo và nhớ số cuối cùng!",
                    hint_en: "Count each apple, the last number is the answer!",
                })],
            )],
        },
        CurriculumSubject {
            subject_id: "geometry".to_string(),
            subject_vi: "Hình học".to_string(),
            subject_en: "Geometry".to_string(),
            subject_icon: "📐".to_string(),
            subject_color: "#E8F5E9".to_string(),
            lessons: vec![static_lesson(
                "lesson_g1",
                "Nhận biết hình tròn",
                "Recognize circles",
                vec![static_ex(StaticExerciseParams {
                    id: "ex_g1_01",
                    question_vi: "Hình nào là hình tròn?",
                    question_en: "Which shape is a circle?",
                    options: vec!["Tam giác".into(), "Hình tròn".into(), "Hình vuông".into()],
                    correct: 1,
                    visual: "🔺 🔴 ⬜",
                    hint_vi: "Hình tròn tròn trịa, không có góc cạnh!",
                    hint_en: "A circle is round with no corners!",
                })],
            )],
        },
        CurriculumSubject {
            subject_id: "logic".to_string(),
            subject_vi: "Tư duy".to_string(),
            subject_en: "Logic".to_string(),
            subject_icon: "🧩".to_string(),
            subject_color: "#E3F2FD".to_string(),
            lessons: vec![static_lesson(
                "lesson_l1",
                "Tìm quy luật số",
                "Number patterns",
                vec![static_ex(StaticExerciseParams {
                    id: "ex_l1_01",
                    question_vi: "Số tiếp theo: 2, 4, 6, ...?",
                    question_en: "Next number: 2, 4, 6, ...?",
                    options: vec!["7".into(), "8".into(), "9".into()],
                    correct: 1,
                    visual: "🔢",
                    hint_vi: "Cộng thêm 2 mỗi lần: 2+2=4, 4+2=6, 6+2=?",
                    hint_en: "Add 2 each time: 2+2=4, 4+2=6, 6+2=?",
                })],
            )],
        },
    ]
}

fn static_lesson(
    id: &str,
    title_vi: &str,
    title_en: &str,
    exercises: Vec<ApiExercise>,
) -> ApiLesson {
    ApiLesson {
        id: id.to_string(),
        title_vi: title_vi.to_string(),
        title_en: title_en.to_string(),
        description_vi: None,
        description_en: None,
        lesson_order: 1,
        difficulty: 1,
        is_premium: false,
        exercises,
    }
}

struct StaticExerciseParams<'a> {
    id: &'a str,
    question_vi: &'a str,
    question_en: &'a str,
    options: Vec<String>,
    correct: i32,
    visual: &'a str,
    hint_vi: &'a str,
    hint_en: &'a str,
}

fn static_ex(params: StaticExerciseParams<'_>) -> ApiExercise {
    ApiExercise {
        id: params.id.to_string(),
        question_vi: params.question_vi.to_string(),
        question_en: params.question_en.to_string(),
        options: params.options,
        correct: params.correct,
        visual: params.visual.to_string(),
        hint_vi: Some(params.hint_vi.to_string()),
        hint_en: Some(params.hint_en.to_string()),
        exercise_order: 1,
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn get_curriculum_static_returns_subjects() {
        let curriculum = get_curriculum_static();
        assert_eq!(curriculum.len(), 3);
        assert_eq!(curriculum[0].subject_id, "numbers");
        assert_eq!(curriculum[1].subject_id, "geometry");
        assert_eq!(curriculum[2].subject_id, "logic");
    }

    #[test]
    fn get_curriculum_static_lessons_have_exercises() {
        let curriculum = get_curriculum_static();
        let lesson = &curriculum[0].lessons[0];
        assert_eq!(lesson.id, "lesson_n1");
        assert_eq!(lesson.exercises.len(), 1);
        let ex = &lesson.exercises[0];
        assert_eq!(ex.options.len(), 3);
        assert_eq!(ex.correct, 1);
    }

    #[test]
    fn api_exercise_fields() {
        let ex = ApiExercise {
            id: "ex1".to_string(),
            question_vi: "Có bao nhiêu?".to_string(),
            question_en: "How many?".to_string(),
            options: vec!["3".into(), "5".into()],
            correct: 0,
            visual: "🍎".to_string(),
            hint_vi: Some("Đếm nhé".to_string()),
            hint_en: Some("Count them".to_string()),
            exercise_order: 1,
        };
        assert_eq!(ex.id, "ex1");
        assert_eq!(ex.hint_vi, Some("Đếm nhé".to_string()));
        assert_eq!(ex.options.len(), 2);
    }

    #[test]
    fn curriculum_subject_serde_roundtrip() {
        let subject = CurriculumSubject {
            subject_id: "math".to_string(),
            subject_vi: "Toán".to_string(),
            subject_en: "Math".to_string(),
            subject_icon: "🔢".to_string(),
            subject_color: "#FFE8F0".to_string(),
            lessons: vec![],
        };
        let json = serde_json::to_string(&subject).unwrap();
        assert!(json.contains("subject_id"));
        assert!(json.contains("Toán"));
    }

    #[test]
    fn subject_summary_lesson_count() {
        let s = SubjectSummary {
            id: "s1".to_string(),
            name_vi: "Tên".to_string(),
            name_en: "Name".to_string(),
            icon: "📚".to_string(),
            color: "#FFF".to_string(),
            lesson_count: 42,
        };
        assert_eq!(s.lesson_count, 42);
    }
}
