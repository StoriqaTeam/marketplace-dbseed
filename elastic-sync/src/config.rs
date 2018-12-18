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
}
