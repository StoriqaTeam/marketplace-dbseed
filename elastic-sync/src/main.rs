#[macro_use]
extern crate structopt;
#[macro_use]
extern crate log;
extern crate env_logger;
#[macro_use]
extern crate failure;
extern crate postgres;
extern crate reqwest;
#[macro_use]
extern crate serde_derive;
extern crate serde;
#[macro_use]
extern crate serde_json;

use std::collections::HashMap;

use failure::Error as FailureError;
use postgres::{Connection, TlsMode};
use reqwest::Client;
use serde::ser::Serialize;
use structopt::StructOpt;

mod config;
mod types;

use config::Config;
use types::{Attr, Id, Product, Store, Translation, Variant};

fn main() {
    env_logger::init();
    match start() {
        Err(err) => {
            error!("{}", err);
            ::std::process::exit(1);
        }
        Ok(()) => info!("Success"),
    }
}

fn start() -> Result<(), FailureError> {
    let config = Config::from_args();
    let config_without_passwords = Config {
        postgres_url: "***".to_string(),
        ..config.clone()
    };
    info!("Starting app with config {:#?}", config_without_passwords);
    let conn = Connection::connect(config.postgres_url.clone(), TlsMode::None)?;
    let http_client = reqwest::Client::new();

    let provider = match (config.kibana_url.clone(), config.elastic_url.clone()) {
        (Some(kibana_url), None) => Box::new(KibanaProvider {
            http_client,
            url: kibana_url,
        }) as Box<dyn ApiProvider>,
        (None, Some(elastic_url)) => Box::new(ElasticProvider {
            http_client,
            url: elastic_url,
        }) as Box<dyn ApiProvider>,
        _ => {
            bail!("Either kibana or elastic config is permitted");
        }
    };

    let app = App {
        conn,
        provider,
        config,
    };

    match app.config.entity_name.as_ref() {
        "stores" => app.sync_stores()?,
        "products" => app.sync_products()?,
        _ => bail!("Only \"stores\" and \"products\" table avalilable"),
    };

    Ok(())
}

struct App {
    conn: Connection,
    provider: Box<dyn ApiProvider>,
    config: Config,
}

struct ElasticProvider {
    url: String,
    http_client: Client,
}

struct KibanaProvider {
    url: String,
    http_client: Client,
}

trait ApiProvider {
    fn delete_all(&self, index: &str) -> Result<(), FailureError>;
    fn bulk(&self, data: String) -> Result<(), FailureError>;
}

impl ApiProvider for ElasticProvider {
    fn delete_all(&self, index: &str) -> Result<(), FailureError> {
        info!("deleting all entries from {}", index);
        let url = format!("{}/{}/_delete_by_query", self.url, index,);
        let _ = self.request_json(&url, Some(&json!({"query" : { "match_all" : {}}})))?;
        Ok(())
    }

    fn bulk(&self, data: String) -> Result<(), FailureError> {
        let url = format!("{}/_bulk", self.url);
        let _ = self.request(&url, data)?;
        Ok(())
    }
}

impl ElasticProvider {
    fn request_json<T: Serialize>(
        &self,
        url: &str,
        payload: Option<&T>,
    ) -> Result<String, FailureError> {
        let mut request = self.http_client.post(url).header("kbn-xsrf", "reporting");
        if let Some(payload) = payload {
            request = request.json(&payload);
        }

        debug!("request: {:?}", request);
        let mut response = request.send()?;
        let response_text = response.text()?;

        if !response.status().is_success() {
            bail!("{}", response_text);
        }
        Ok(response_text)
    }

    fn request(&self, url: &str, payload: String) -> Result<String, FailureError> {
        let request = self
            .http_client
            .post(url)
            .header("kbn-xsrf", "reporting")
            .header("Content-Type", "application/json")
            .body(payload);
        debug!("request: {:?}", request);
        let mut response = request.send()?;
        let response_text = response.text()?;

        if !response.status().is_success() {
            bail!("{}", response_text);
        }
        Ok(response_text)
    }
}

impl ApiProvider for KibanaProvider {
    fn delete_all(&self, index: &str) -> Result<(), FailureError> {
        info!("deleting all entries from {}", index);
        let url = format!(
            "{}/api/console/proxy?path={}/_delete_by_query&method=POST",
            self.url, index,
        );
        let _ = self.request_json(&url, Some(&json!({"query" : { "match_all" : {}}})))?;
        Ok(())
    }

    fn bulk(&self, data: String) -> Result<(), FailureError> {
        let url = format!("{}/api/console/proxy?path=_bulk&method=POST", self.url);
        let _ = self.request(&url, data)?;
        Ok(())
    }
}

impl KibanaProvider {
    fn request_json<T: Serialize>(
        &self,
        url: &str,
        payload: Option<&T>,
    ) -> Result<String, FailureError> {
        let mut request = self
            .http_client
            .post(url)
            .header("Cookie", "holyshit=iamcool")
            .header("kbn-xsrf", "reporting");
        if let Some(payload) = payload {
            request = request.json(&payload);
        }

        debug!("request: {:?}", request);
        let mut response = request.send()?;
        let response_text = response.text()?;

        if !response.status().is_success() {
            bail!("{}", response_text);
        }
        Ok(response_text)
    }

    fn request(&self, url: &str, payload: String) -> Result<String, FailureError> {
        let request = self
            .http_client
            .post(url)
            .header("Cookie", "holyshit=iamcool")
            .header("kbn-xsrf", "reporting")
            .header("Content-Type", "application/json")
            .body(payload);
        debug!("request: {:?}", request);
        let mut response = request.send()?;
        let response_text = response.text()?;

        if !response.status().is_success() {
            bail!("{}", response_text);
        }
        Ok(response_text)
    }
}

impl App {
    fn sync_products(&self) -> Result<(), FailureError> {
        if self.config.entity_id.is_none() && self.config.delete_all {
            self.provider.delete_all("products")?;
        }

        let base_products = if let Some(store_id) = self.config.entity_id {
            self.conn
                .query("SELECT id, store_id, short_description, long_description, category_id, views, rating, name, status FROM base_products WHERE id=$1", &[&store_id])?
        } else {
            self.conn.query("SELECT id, store_id, short_description, long_description, category_id, views, rating, name, status FROM base_products", &[])?
        };
        debug!("got {} products from db", base_products.len());

        let mut products = Vec::new();

        for base_product in &base_products {
            trace!("base_product: \n {:?}", base_product);
            let product = match self.extract_base_product(&base_product) {
                Ok(product) => product,
                Err(error) => {
                    error!("extracting product {:?} failed: {}", base_product, error);
                    continue;
                }
            };

            products.push(product);
        }

        self.fill_product_variants(&mut products)?;

        info!("inserting {} entries in products", products.len());
        let payload = self.serialize_bulk_put("products", products)?;
        self.provider.bulk(payload)?;

        Ok(())
    }

    fn extract_base_product(
        &self,
        base_product: &postgres::rows::Row,
    ) -> Result<Product, FailureError> {
        let name: Option<serde_json::Value> = base_product.get("name");
        let default_name = default_name(serde_json::from_value::<Vec<Translation>>(
            name.clone().unwrap_or(json!([])),
        )?).ok_or(format_err!("Could not extract default name"))?;
        let status: Option<String> = base_product.get("status");
        let store_id: Option<i32> = base_product.get("store_id");
        let store_and_status = format!(
            "{}_{}",
            store_id.ok_or(format_err!("Store id not found"))?,
            status.clone().ok_or(format_err!("Status not found"))?
        );
        let product = Product {
            id: base_product.get("id"),
            store_id,
            short_description: base_product.get("short_description"),
            long_description: base_product.get("long_description"),
            category_id: base_product.get("category_id"),
            views: base_product.get("views"),
            rating: base_product.get("rating"),
            suggest_2: Some(json!({
                "input": [
                    default_name,
                    default_name
                ],
                "contexts": {
                    "store_and_status": [
                    store_and_status,
                    status.clone().ok_or(format_err!("Status not found"))?
                    ]
                }
            })),
            name,
            status,
            variants: Vec::new(),
        };

        Ok(product)
    }

    fn fill_product_variants(&self, products: &mut [Product]) -> Result<(), FailureError> {
        if products.is_empty() {
            return Ok(());
        }

        let product_ids: Vec<i32> = products.iter().map(|p| p.id).collect();

        let mut products_by_id: HashMap<i32, &mut Product> =
            products.iter_mut().map(|p| (p.id, p)).collect();

        let product_variants = self.conn.query(
            "SELECT base_product_id, id, discount, price, currency FROM products WHERE base_product_id = ANY ($1)",
            &[&product_ids],
        )?;

        debug!(
            "got {} products variants for base products from db",
            product_variants.len()
        );

        for product_variant in &product_variants {
            let base_product_id: i32 = product_variant.get("base_product_id");
            let mut variant = Variant {
                prod_id: product_variant.get("id"),
                discount: product_variant.get("discount"),
                price: product_variant.get("price"),
                currency: product_variant.get("currency"),
                attrs: Vec::new(),
            };

            if let Some(product) = products_by_id.get_mut(&base_product_id) {
                product.variants.push(variant);
            }
        }

        let mut variats_by_id: HashMap<i32, &mut Variant> = products_by_id
            .iter_mut()
            .flat_map(|(_, p)| p.variants.iter_mut())
            .map(|v| (v.prod_id, v))
            .collect();

        let product_variant_ids: Vec<i32> = variats_by_id.keys().cloned().collect();

        let variant_attrs = self.conn.query(
            "SELECT prod_id, attr_id, value, value_type FROM prod_attr_values WHERE prod_id = ANY ($1)",
            &[&product_variant_ids],
        )?;

        debug!("got {} variant attributes db", variant_attrs.len());

        for variant_attr in &variant_attrs {
            let value_type: Option<String> = variant_attr.get("value_type");
            let value: Option<String> = variant_attr.get("value");
            let (float_val, str_val) =
                match (value_type.as_ref().map(|s| s.as_str()), value.clone()) {
                    (Some("str"), str_val) => (None, str_val.clone()),
                    (Some("float"), float_val) => {
                        (float_val.and_then(|f| f.parse::<f64>().ok()), None)
                    }
                    _ => bail!(
                        "Bad variant attribute - value_type={:?}, value={:?}",
                        value_type,
                        value
                    ),
                };
            let attr = Attr {
                attr_id: variant_attr.get("attr_id"),
                float_val,
                str_val,
            };

            let prod_id: i32 = variant_attr.get("prod_id");

            if let Some(variant) = variats_by_id.get_mut(&prod_id) {
                variant.attrs.push(attr);
            }
        }

        Ok(())
    }

    fn sync_stores(&self) -> Result<(), FailureError> {
        if self.config.entity_id.is_none() && self.config.delete_all {
            self.provider.delete_all("stores")?;
        }

        let rows = if let Some(store_id) = self.config.entity_id {
            self.conn
                .query("SELECT id, country, user_id, product_categories, name, rating, status FROM stores WHERE id=$1", &[&store_id])?
        } else {
            self.conn.query(
                "SELECT id, country, user_id, product_categories, name, rating, status FROM stores",
                &[],
            )?
        };

        debug!("got {} stores from db", rows.len());

        let mut stores = Vec::new();
        for row in &rows {
            trace!("store: \n {:?}", row);

            let store = match Self::extract_store(&row) {
                Ok(store) => store,
                Err(error) => {
                    error!("extracting store {:?} failed: {}", row, error);
                    continue;
                }
            };

            stores.push(store);
        }

        info!("inserting {} entries in stores", stores.len());
        let payload = self.serialize_bulk_put("stores", stores)?;
        self.provider.bulk(payload)?;

        Ok(())
    }

    fn extract_store(row: &postgres::rows::Row) -> Result<Store, FailureError> {
        let name: Option<serde_json::Value> = row.get("name");
        let status = row.get("status");
        let default_name = default_name(serde_json::from_value::<Vec<Translation>>(
            name.clone().unwrap_or(json!([])),
        )?).ok_or(format_err!("Could not extract default name"))?;
        let store = Store {
            id: row.get("id"),
            country: row.get("country"),
            user_id: row.get("user_id"),
            product_categories: row.get("product_categories"),
            name,
            rating: row.get("rating"),
            suggest_2: Some(json!({
                "input": [
                    default_name,
                    default_name,
                ],
                "contexts": {
                    "status": [
                        status
                    ]
                }
            })),
            status,
        };
        Ok(store)
    }

    fn serialize_bulk_put<T: Serialize + Id>(
        &self,
        index: &str,
        values: Vec<T>,
    ) -> Result<String, FailureError> {
        let mut payload = String::new();
        for value in values {
            payload.push_str(&serde_json::to_string(
                &json!({ "create" : { "_index": index, "_type" : "_doc", "_id" : value.id() } }),
            )?);
            payload.push('\n');
            payload.push_str(&serde_json::to_string(&value)?);
            payload.push('\n');
        }
        Ok(payload)
    }
}

fn default_name(names: Vec<Translation>) -> Option<String> {
    let en_name = names
        .iter()
        .filter(|name| name.lang == "en")
        .map(|name| name.text.clone())
        .next();
    let first_name = names.first().map(|name| name.text.clone());
    en_name.or(first_name)
}
