use anyhow::Result;
use sqlx::PgPool;

#[derive(Clone)]
pub struct Db(PgPool);

impl Db {
    pub async fn connect(url: &str) -> Result<Self> {
        let pool = PgPool::connect(url).await?;
        Ok(Self(pool))
    }

    pub fn pool(&self) -> &PgPool {
        &self.0
    }

    pub async fn run_migrations(&self) -> Result<()> {
        let migration_dir = std::path::PathBuf::from(env!("CARGO_MANIFEST_DIR")).join("migrations");
        let migrator = sqlx::migrate::Migrator::new(migration_dir).await?;
        migrator.run(&self.0).await?;
        Ok(())
    }
}
