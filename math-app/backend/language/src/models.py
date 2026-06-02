from sqlalchemy import Column, String, Integer, Boolean, DateTime, Text, ARRAY, Float, ForeignKey
from sqlalchemy.dialects.postgresql import UUID
from db import Base
from datetime import datetime
import uuid

class LanguageSubject(Base):
    __tablename__ = "language_subjects"
    id = Column(String(50), primary_key=True)
    name_vi = Column(String(255), nullable=False)
    name_en = Column(String(255), nullable=False)
    icon = Column(String(10), default='📚')
    color = Column(String(50), default='#FFEBEE')
    display_order = Column(Integer, default=0)
    target_language = Column(String(10), nullable=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class LanguageLesson(Base):
    __tablename__ = "language_lessons"
    id = Column(String(50), primary_key=True)
    subject_id = Column(String(50), ForeignKey("language_subjects.id", ondelete="CASCADE"), nullable=False)
    title_vi = Column(String(255), nullable=False)
    title_en = Column(String(255), nullable=False)
    description_vi = Column(Text)
    description_en = Column(Text)
    lesson_order = Column(Integer, nullable=False, default=1)
    difficulty = Column(Integer, nullable=False, default=1)
    is_premium = Column(Boolean, default=False)
    created_at = Column(DateTime, default=datetime.utcnow)

class LanguageExercise(Base):
    __tablename__ = "language_exercises"
    id = Column(String(50), primary_key=True)
    lesson_id = Column(String(50), ForeignKey("language_lessons.id", ondelete="CASCADE"), nullable=False)
    exercise_type = Column(String(20), nullable=False)
    question_vi = Column(Text, nullable=False)
    question_en = Column(Text, nullable=False)
    options = Column(ARRAY(String), default=[])
    correct_index = Column(Integer, default=0)
    expected_text = Column(String(500))
    validation_mode = Column(String(20), default='exact')
    max_edit_distance = Column(Integer, default=0)
    case_sensitive = Column(Boolean, default=False)
    diacritic_sensitive = Column(Boolean, default=True)
    audio_url = Column(String(255))
    reference_audio_url = Column(String(255))
    visual_asset = Column(String(50), default='')
    hint_vi = Column(Text)
    hint_en = Column(Text)
    exercise_order = Column(Integer, default=1)
    created_at = Column(DateTime, default=datetime.utcnow)

class LanguageProgress(Base):
    __tablename__ = "language_progress"
    user_id = Column(UUID(as_uuid=True), primary_key=True)
    lesson_id = Column(String(50), primary_key=True)
    completed = Column(Boolean, default=False)
    stars = Column(Integer, default=0)
    attempts = Column(Integer, default=0)
    updated_at = Column(DateTime, default=datetime.utcnow)

class SpeechSubmission(Base):
    __tablename__ = "speech_submissions"
    id = Column(UUID(as_uuid=True), primary_key=True, default=uuid.uuid4)
    user_id = Column(UUID(as_uuid=True), nullable=False)
    exercise_id = Column(String(50), nullable=False)
    audio_url = Column(String(255), nullable=False)
    transcribed_text = Column(String(500))
    confidence = Column(Float)
    is_correct = Column(Boolean)
    pronunciation_score = Column(Float)
    created_at = Column(DateTime, default=datetime.utcnow)
