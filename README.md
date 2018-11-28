# marketplace-dbseed
Databases seeds for marketplace

## Usage

Specify configuration file with `DBSEED_CONF` environment variable. Deafult is
`conf/development`

* `./dbseed.sh database` - reinitialize specified database`
* `./dbseed.sh ALL` - reinitialize all databases

## Adding seeds

1. Create directory in `sql` named after the database;
2. Create file `config` (example below);
3. Add your seed file in this directory with `.sql` extension and starting with
two digit number, that defines the order in which these files apply.

## Config file

```
# K8S_POD_SELECTOR is generally `app=microservice_name`
k8s_pod_selector="K8S_POD_SELECTOR"
# Database owner in PostgreSQL, typically namedafter microservice
owner="OWNER"
```
