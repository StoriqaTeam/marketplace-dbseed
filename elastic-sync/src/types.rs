pub trait Id {
    fn id(&self) -> i32;
}

#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct Store {
    pub id: i32,
    pub country: Option<String>,
    pub user_id: Option<i32>,
    pub product_categories: Option<serde_json::Value>,
    pub suggest_2: Option<serde_json::Value>,
    pub name: Option<serde_json::Value>,
    pub rating: f64,
    pub status: Option<String>,
}

#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct Translation {
    pub lang: String,
    pub text: String,
}
#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct Product {
    pub id: i32,
    pub name: Option<serde_json::Value>,
    pub short_description: Option<serde_json::Value>,
    pub long_description: Option<serde_json::Value>,
    pub category_id: Option<i32>,
    pub store_id: Option<i32>,
    pub views: Option<i32>,
    pub rating: Option<f64>,
    pub status: Option<String>,
    pub suggest_2: Option<serde_json::Value>,
    pub variants: Vec<Variant>,
    pub store_status: Option<String>,
}

#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct Variant {
    pub prod_id: i32,
    pub discount: Option<f64>,
    pub price: Option<f64>,
    pub currency: Option<String>,
    pub attrs: Vec<Attr>,
}

#[derive(Default, Debug, Clone, Serialize, Deserialize)]
pub struct Attr {
    pub attr_id: Option<i32>,
    pub float_val: Option<f64>,
    pub str_val: Option<String>,
}

impl Id for Product {
    fn id(&self) -> i32 {
        self.id
    }
}

impl Id for Store {
    fn id(&self) -> i32 {
        self.id
    }
}
