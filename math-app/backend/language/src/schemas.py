from pydantic import BaseModel, Field
from typing import List, Optional
from uuid import UUID

class ApiResponse(BaseModel):
    success: bool = True
    data: Optional[dict] = None
    error: Optional[str] = None

class SubjectSummary(BaseModel):
    id: str
    name_vi: str
    name_en: str
    icon: str
    color: str
    lesson_count: int

class ApiExercise(BaseModel):
    id: str
    exercise_type: str
    question_vi: str
    question_en: str
    options: List[str] = []
    correct_index: int = 0
    expected_text: Optional[str] = None
    validation_mode: str = "exact"
    max_edit_distance: Optional[int] = 0
    case_sensitive: bool = False
    diacritic_sensitive: bool = True
    audio_url: Optional[str] = None
    reference_audio_url: Optional[str] = None
    visual_asset: str = ""
    hint_vi: Optional[str] = None
    hint_en: Optional[str] = None
    exercise_order: int = 1

class ApiLesson(BaseModel):
    id: str
    title_vi: str
    title_en: str
    description_vi: Optional[str] = None
    description_en: Optional[str] = None
    lesson_order: int
    difficulty: int
    is_premium: Optional[bool] = False
    exercises: List[ApiExercise] = []

class CurriculumSubSubject(BaseModel):
    sub_subject_id: str
    sub_subject_vi: str
    sub_subject_en: str
    sub_subject_icon: str
    sub_subject_color: str
    lessons: List[ApiLesson] = []

class CurriculumSubject(BaseModel):
    subject_id: str
    subject_vi: str
    subject_en: str
    subject_icon: str
    subject_color: str
    sub_subjects: List[CurriculumSubSubject] = []
    lessons: List[ApiLesson] = []

class SubSubjectSummary(BaseModel):
    id: str
    subject_id: str
    name_vi: str
    name_en: str
    icon: str
    color: str
    display_order: int
    lesson_count: int

class TtsRequest(BaseModel):
    text: str
    language: str = "vi"

class TtsResponse(BaseModel):
    audio_url: str

class ValidateRequest(BaseModel):
    exercise_id: str
    user_text: str

class ValidateResult(BaseModel):
    is_correct: bool
    normalized_user: str
    distance: Optional[int] = None
    feedback_vi: str
    feedback_en: str

class ProgressUpdate(BaseModel):
    user_id: str
    lesson_id: str
    stars: int = Field(ge=1, le=3)
    completed: bool = True

class LanguageProgressOut(BaseModel):
    user_id: UUID
    lesson_id: str
    completed: bool
    stars: int
    attempts: int

class SubSubjectProgress(BaseModel):
    id: str
    name_vi: str
    name_en: str
    color: str
    icon: str
    total_lessons: int
    completed_lessons: int
    stars_earned: int
    max_stars: int
    completion_pct: float
    is_unlocked: bool

class SubjectProgress(BaseModel):
    subject_id: str
    subject_vi: str
    subject_en: str
    icon: str
    color: str
    total_lessons: int
    completed_lessons: int
    stars_earned: int
    max_stars: int
    completion_pct: float
    sub_subjects: List[SubSubjectProgress] = []

class SpeechEvaluateResult(BaseModel):
    transcribed_text: str
    is_correct: bool
    confidence: float
    pronunciation_score: float
    feedback_vi: str
    feedback_en: str
