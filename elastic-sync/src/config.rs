#[derive(Debug, StructOpt, Clone)]
#[structopt(name = "elastic-sync", about = "Sync storiqa stores with elastic")]
pub struct Config {
    #[structopt(short = "p", long = "postgres")]
    pub postgres_url: String,
    #[structopt(short = "k", long = "kibana")]
    pub kibana_url: Option<String>,
    #[structopt(short = "e", long = "elastic")]
    pub elastic_url: Option<String>,
    #[structopt(short = "d", long = "delete-all")]
    pub delete_all: bool,
    pub entity_name: String,
    pub entity_id: Option<i32>,
    #[structopt(short = "m", long = "set-mapping")]
    pub entity_mapping_source: Option<String>,
    #[structopt(short = "s", long = "set-settings")]
    pub entity_settings_source: Option<String>,
}

impl Config {
    pub fn sanitize(self) -> Config {
        Config {
            postgres_url: self.postgres_url.trim_matches('/').to_string(),
            kibana_url: self.kibana_url.map(|s| s.trim_matches('/').to_string()),
            elastic_url: self.elastic_url.map(|s| s.trim_matches('/').to_string()),
            delete_all: self.delete_all,
            entity_name: self.entity_name,
            entity_id: self.entity_id,
            entity_mapping_source: self.entity_mapping_source,
            entity_settings_source: self.entity_settings_source,
        }
    }
}
