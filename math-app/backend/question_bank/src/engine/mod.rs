pub mod bkt;
pub mod distractor;
pub mod generator;
pub mod sampler;

use crate::engine::bkt::BktState;
use crate::models::Question;
use anyhow::Result;
use sqlx::PgPool;
use uuid::Uuid;

#[allow(dead_code)]
pub struct AdaptiveSelector<'a> {
    pool: &'a PgPool,
}

impl<'a> AdaptiveSelector<'a> {
    #[allow(dead_code)]
    pub fn new(pool: &'a PgPool) -> Self {
        Self { pool }
    }

    #[allow(dead_code)]
    pub async fn next_question(
        &self,
        student_id: Uuid,
        kc_id: Uuid,
        bkt: &BktState,
    ) -> Result<Option<Question>> {
        let target_diff = bkt.difficulty_target();

        let question = sqlx::query_as::<_, Question>(
            r#"
            SELECT q.* FROM question q
            WHERE q.kc_id = $1
            AND q.difficulty = $2
            AND q.id NOT IN (
                SELECT question_id FROM response
                WHERE student_id = $3
                ORDER BY created_at DESC
                LIMIT 20
            )
            ORDER BY random()
            LIMIT 1
            "#,
        )
        .bind(kc_id)
        .bind(target_diff)
        .bind(student_id)
        .fetch_optional(self.pool)
        .await?;

        Ok(question)
    }
}
