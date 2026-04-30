use chrono::{DateTime, Utc};
use serde::Serialize;
use sqlx::PgPool;
use utoipa::ToSchema;

// ============================================================================
// DATABASE MODELS (sqlx::FromRow)
// ============================================================================

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
    pub async fn get_subjects(&self) -> Result<Vec<SubjectSummary>, sqlx::Error> {
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
            LEFT JOIN lessons l ON l.subject_id = s.id
            GROUP BY s.id, s.name_vi, s.name_en, s.icon, s.color, s.display_order
            ORDER BY s.display_order
            "#
        )
        .fetch_all(&self.db)
        .await?;

        Ok(rows
            .into_iter()
            .map(|(id, name_vi, name_en, icon, color, lesson_count)| SubjectSummary {
                id,
                name_vi,
                name_en,
                icon,
                color,
                lesson_count,
            })
            .collect())
    }

    pub async fn get_curriculum(&self) -> Result<Vec<CurriculumSubject>, sqlx::Error> {
        let subjects = sqlx::query_as::<_, Subject>(
            "SELECT * FROM subjects ORDER BY display_order"
        )
        .fetch_all(&self.db)
        .await?;

        let mut result = Vec::with_capacity(subjects.len());

        for subj in subjects {
            let lessons = sqlx::query_as::<_, Lesson>(
                "SELECT * FROM lessons WHERE subject_id = $1 ORDER BY lesson_order"
            )
            .bind(&subj.id)
            .fetch_all(&self.db)
            .await?;

            let mut api_lessons = Vec::with_capacity(lessons.len());
            for lesson in lessons {
                let exercises = sqlx::query_as::<_, Exercise>(
                    "SELECT * FROM exercises WHERE lesson_id = $1 ORDER BY exercise_order"
                )
                .bind(&lesson.id)
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

                api_lessons.push(ApiLesson {
                    id: lesson.id,
                    title_vi: lesson.title_vi,
                    title_en: lesson.title_en,
                    description_vi: lesson.description_vi,
                    description_en: lesson.description_en,
                    lesson_order: lesson.lesson_order,
                    difficulty: lesson.difficulty,
                    is_premium: lesson.is_premium,
                    exercises: api_exercises,
                });
            }

            result.push(CurriculumSubject {
                subject_id: subj.id,
                subject_vi: subj.name_vi,
                subject_en: subj.name_en,
                subject_icon: subj.icon,
                subject_color: subj.color,
                lessons: api_lessons,
            });
        }

        Ok(result)
    }

    pub async fn get_lesson(&self, lesson_id: &str) -> Result<Option<ApiLesson>, sqlx::Error> {
        let lesson = sqlx::query_as::<_, Lesson>(
            "SELECT * FROM lessons WHERE id = $1"
        )
        .bind(lesson_id)
        .fetch_optional(&self.db)
        .await?;

        match lesson {
            Some(l) => {
                let exercises = sqlx::query_as::<_, Exercise>(
                    "SELECT * FROM exercises WHERE lesson_id = $1 ORDER BY exercise_order"
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
            lessons: vec![
                static_lesson("lesson_n1", "Đếm đến 10", "Count to 10", vec![
                    static_ex(
                        "ex_n1_01",
                        "Có bao nhiêu quả táo 🍎?", "How many apples 🍎?",
                        vec!["3".into(), "5".into(), "4".into()], 1,
                        "🍎🍎🍎🍎🍎",
                        "Đếm từng quả táo và nhớ số cuối cùng!",
                        "Count each apple, the last number is the answer!",
                    ),
                ]),
            ],
        },
        CurriculumSubject {
            subject_id: "geometry".to_string(),
            subject_vi: "Hình học".to_string(),
            subject_en: "Geometry".to_string(),
            subject_icon: "📐".to_string(),
            subject_color: "#E8F5E9".to_string(),
            lessons: vec![
                static_lesson("lesson_g1", "Nhận biết hình tròn", "Recognize circles", vec![
                    static_ex(
                        "ex_g1_01",
                        "Hình nào là hình tròn?", "Which shape is a circle?",
                        vec!["Tam giác".into(), "Hình tròn".into(), "Hình vuông".into()], 1,
                        "🔺 🔴 ⬜",
                        "Hình tròn tròn trịa, không có góc cạnh!",
                        "A circle is round with no corners!",
                    ),
                ]),
            ],
        },
        CurriculumSubject {
            subject_id: "logic".to_string(),
            subject_vi: "Tư duy".to_string(),
            subject_en: "Logic".to_string(),
            subject_icon: "🧩".to_string(),
            subject_color: "#E3F2FD".to_string(),
            lessons: vec![
                static_lesson("lesson_l1", "Tìm quy luật số", "Number patterns", vec![
                    static_ex(
                        "ex_l1_01",
                        "Số tiếp theo: 2, 4, 6, ...?", "Next number: 2, 4, 6, ...?",
                        vec!["7".into(), "8".into(), "9".into()], 1,
                        "🔢",
                        "Cộng thêm 2 mỗi lần: 2+2=4, 4+2=6, 6+2=?",
                        "Add 2 each time: 2+2=4, 4+2=6, 6+2=?",
                    ),
                ]),
            ],
        },
    ]
}

fn static_lesson(id: &str, title_vi: &str, title_en: &str, exercises: Vec<ApiExercise>) -> ApiLesson {
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

fn static_ex(
    id: &str, question_vi: &str, question_en: &str,
    options: Vec<String>, correct: i32, visual: &str,
    hint_vi: &str, hint_en: &str,
) -> ApiExercise {
    ApiExercise {
        id: id.to_string(),
        question_vi: question_vi.to_string(),
        question_en: question_en.to_string(),
        options,
        correct,
        visual: visual.to_string(),
        hint_vi: Some(hint_vi.to_string()),
        hint_en: Some(hint_en.to_string()),
        exercise_order: 1,
    }
}
