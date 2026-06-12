mod db;
mod engine;
mod handlers;
mod llm;
mod models;

use axum::{routing::get, Router};
use std::net::SocketAddr;
use std::sync::Arc;
use tower_http::cors::CorsLayer;
use utoipa::OpenApi;
use utoipa_swagger_ui::SwaggerUi;

use handlers::AppState;
use models::{
    AnswerPayload, AnswerResult, BktState, GenerateRequest, HintRequest, HintResponse, Kc, Question,
    QuestionTemplate, RecordWrongPayload, RecordWrongResult, ReviewList, ReviewEntry,
};

#[derive(OpenApi)]
#[openapi(components(schemas(
    Kc,
    QuestionTemplate,
    Question,
    BktState,
    GenerateRequest,
    AnswerPayload,
    AnswerResult,
    RecordWrongPayload,
    RecordWrongResult,
    ReviewList,
    ReviewEntry,
    HintRequest,
    HintResponse,
)))]
pub struct ApiDoc;

#[tokio::main]
async fn main() {
    tracing_subscriber::fmt::init();

    let db_url = std::env::var("DATABASE_URL")
        .unwrap_or_else(|_| "postgres://qb_user:qb_pass@localhost:5432/qb_db".into());

    let db = match db::Db::connect(&db_url).await {
        Ok(d) => {
            tracing::info!("Connected to question bank database");
            if let Err(e) = d.run_migrations().await {
                tracing::warn!("Migration failed ({}), continuing", e);
            }
            d
        }
        Err(e) => {
            tracing::error!("Database connection failed: {}", e);
            panic!("Question bank service requires database");
        }
    };

    let state = Arc::new(AppState { db });

    let app = Router::new()
        .route("/api/questions/health", get(handlers::health))
        .route(
            "/api/questions/next/:student_id",
            get(handlers::next_question),
        )
        .route(
            "/api/questions/answer/:student_id",
            axum::routing::post(handlers::submit_answer),
        )
        .route(
            "/api/questions/generate",
            axum::routing::post(handlers::generate_questions),
        )
        .route(
            "/api/questions/mastery/:student_id/:kc_id",
            get(handlers::get_mastery),
        )
        .route(
            "/api/questions/review/:user_id",
            axum::routing::get(handlers::get_review),
        )
        .route(
            "/api/questions/review/:user_id",
            axum::routing::post(handlers::record_wrong),
        )
        .route(
            "/api/questions/review/:user_id/:exercise_id",
            axum::routing::delete(handlers::clear_wrong),
        )
        .route(
            "/api/questions/hint",
            axum::routing::post(handlers::get_hint),
        )
        .merge(
            SwaggerUi::new("/api/questions/swagger-ui")
                .url("/api/questions/openapi.json", ApiDoc::openapi()),
        )
        .layer(CorsLayer::permissive())
        .with_state(state);

    let port: u16 = std::env::var("PORT")
        .unwrap_or_else(|_| "3000".into())
        .parse()
        .unwrap();
    let addr = SocketAddr::from(([0, 0, 0, 0], port));
    let listener = tokio::net::TcpListener::bind(addr).await.unwrap();

    tracing::info!("Question Bank service listening on http://{}", addr);
    axum::serve(listener, app).await.unwrap();
}
