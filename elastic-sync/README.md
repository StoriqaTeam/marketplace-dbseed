# elastic-sync
Synchronize marketplace stores and products entities with elastic

## Usage
```bash
USAGE:
    elastic-sync [FLAGS] [OPTIONS] --postgres <postgres_url> <entity_name> [entity_id]

FLAGS:
    -d, --delete-all    Delete all entries from index before synchronization
    -h, --help          Prints help information
    -V, --version       Prints version information

OPTIONS:
    -e, --elastic <elastic_url>                    
    -m, --set-mapping <entity_mapping_source>      
    -s, --set-settings <entity_settings_source>    
    -k, --kibana <kibana_url>                      
    -p, --postgres <postgres_url>                  

ARGS:
    <entity_name>    
    <entity_id>  
```

## Example usage

Build project and synchronize all stores with mapping and settings override
```bash
cargo build && RUST_LOG=elastic_sync=debug ./target/debug/elastic-sync --postgres "postgresql://stores:stores@100.71.27.96/stores" --elastic "http://100.66.28.123:9200" --delete-all -m "stores-mapping-with-analyzer.json" -s "stores-settings.json" stores
```

Build project and synchronize all products with mapping and settings override
```bash
cargo build && RUST_LOG=elastic_sync=debug ./target/debug/elastic-sync --postgres "postgresql://stores:stores@100.71.27.96/stores" --elastic "http://100.66.28.123:9200" --delete-all -m "products-mapping-with-analyzer.json" -s "products-settings.json" products
```

Build project and synchronize all products without deleting all entries from elastic
```bash
cargo build && RUST_LOG=elastic_sync=debug ./target/debug/elastic-sync --postgres "postgresql://stores:stores@100.71.27.96/stores" --elastic "http://100.66.28.123:9200" products
```

Build project, delete all product entries from elastic and synchronize all products
```bash
cargo build && RUST_LOG=elastic_sync=debug ./target/debug/elastic-sync --postgres "postgresql://stores:stores@100.71.27.96/stores" --elastic "http://100.66.28.123:9200" --delete-all products
```

Build project and synchronize all stores without deleting all entries from elastic
```bash
cargo build && RUST_LOG=elastic_sync=debug ./target/debug/elastic-sync --postgres "postgresql://stores:stores@100.71.27.96/stores" --elastic "http://100.66.28.123:9200" stores
```

Build project, delete all store entries from elastic and synchronize all stores
```bash
cargo build && RUST_LOG=elastic_sync=debug ./target/debug/elastic-sync --postgres "postgresql://stores:stores@100.71.27.96/stores" --elastic "http://100.66.28.123:9200" --delete-all stores
```
