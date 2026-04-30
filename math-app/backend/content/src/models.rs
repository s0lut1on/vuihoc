use serde::Serialize;
use utoipa::ToSchema;

#[derive(Serialize, Clone, ToSchema)]
pub struct Exercise {
    pub id: String,
    pub question_vi: String,
    pub question_en: String,
    pub options: Vec<String>,
    pub correct: usize,
    pub visual: String,
    pub hint_vi: String,
    pub hint_en: String,
}

#[derive(Serialize, Clone, ToSchema)]
pub struct Lesson {
    pub id: String,
    pub title_vi: String,
    pub title_en: String,
    pub difficulty: u8,
    pub exercises: Vec<Exercise>,
}

#[derive(Serialize, Clone, ToSchema)]
pub struct CurriculumSubject {
    pub subject_id: String,
    pub subject_vi: String,
    pub subject_en: String,
    pub lessons: Vec<Lesson>,
}

#[derive(Serialize, Clone, ToSchema)]
pub struct SubjectSummary {
    pub id: String,
    pub name_vi: String,
    pub name_en: String,
    pub lesson_count: usize,
}

pub fn get_curriculum() -> Vec<CurriculumSubject> {
    vec![
        CurriculumSubject {
            subject_id: "numbers".to_string(),
            subject_vi: "So hoc".to_string(),
            subject_en: "Numbers".to_string(),
            lessons: vec![
                Lesson {
                    id: "lesson_001".to_string(),
                    title_vi: "Dem den 10".to_string(),
                    title_en: "Count to 10".to_string(),
                    difficulty: 1,
                    exercises: vec![Exercise {
                        id: "ex_001".to_string(),
                        question_vi: "Dem co bao nhieu qua tao?".to_string(),
                        question_en: "How many apples?".to_string(),
                        options: vec!["3".into(), "5".into(), "4".into()],
                        correct: 1,
                        visual: "apples_5".into(),
                        hint_vi: "Hay chi vao tung qua tao va dem!".into(),
                        hint_en: "Point at each apple and count!".into(),
                    }],
                },
                Lesson {
                    id: "lesson_002".to_string(),
                    title_vi: "So sanh cac so".to_string(),
                    title_en: "Compare numbers".to_string(),
                    difficulty: 1,
                    exercises: vec![Exercise {
                        id: "ex_002".to_string(),
                        question_vi: "So nao lon hon: 7 hay 3?".to_string(),
                        question_en: "Which is larger: 7 or 3?".to_string(),
                        options: vec!["3".into(), "7".into(), "Bang nhau".into()],
                        correct: 1,
                        visual: "numbers_compare".into(),
                        hint_vi: "Hay dem tren ngon tay!".into(),
                        hint_en: "Count on your fingers!".into(),
                    }],
                },
                Lesson {
                    id: "lesson_003".to_string(),
                    title_vi: "Phep cong 1 - 10".to_string(),
                    title_en: "Addition 1 - 10".to_string(),
                    difficulty: 1,
                    exercises: vec![Exercise {
                        id: "ex_003".to_string(),
                        question_vi: "3 + 5 = ?".to_string(),
                        question_en: "3 + 5 = ?".to_string(),
                        options: vec!["7".into(), "8".into(), "9".into()],
                        correct: 1,
                        visual: "add_3_5".into(),
                        hint_vi: "Dem tiep 5 buoc tu so 3".into(),
                        hint_en: "Count 5 more steps from 3".into(),
                    }],
                },
            ],
        },
        CurriculumSubject {
            subject_id: "geometry".to_string(),
            subject_vi: "Hinh hoc".to_string(),
            subject_en: "Geometry".to_string(),
            lessons: vec![Lesson {
                id: "lesson_g1".to_string(),
                title_vi: "Nhan biet hinh tron".to_string(),
                title_en: "Recognize circles".to_string(),
                difficulty: 1,
                exercises: vec![Exercise {
                    id: "ex_g1".to_string(),
                    question_vi: "Hinh nao la hinh tron?".to_string(),
                    question_en: "Which shape is a circle?".to_string(),
                    options: vec!["Tam giac".into(), "Hinh tron".into(), "Hinh vuong".into()],
                    correct: 1,
                    visual: "shapes_mix".into(),
                    hint_vi: "Tim hinh tron tron, khong co goc!".into(),
                    hint_en: "Find the round shape with no corners!".into(),
                }],
            }],
        },
        CurriculumSubject {
            subject_id: "logic".to_string(),
            subject_vi: "Tu duy".to_string(),
            subject_en: "Logic".to_string(),
            lessons: vec![Lesson {
                id: "lesson_l1".to_string(),
                title_vi: "Tim quy luat".to_string(),
                title_en: "Find the pattern".to_string(),
                difficulty: 1,
                exercises: vec![Exercise {
                    id: "ex_l1".to_string(),
                    question_vi: "So tiep theo: 2, 4, 6, ...?".to_string(),
                    question_en: "Next number: 2, 4, 6, ...?".to_string(),
                    options: vec!["7".into(), "8".into(), "9".into()],
                    correct: 1,
                    visual: "pattern_246".into(),
                    hint_vi: "Cong them 2 moi lan!".into(),
                    hint_en: "Add 2 each time!".into(),
                }],
            }],
        },
    ]
}
