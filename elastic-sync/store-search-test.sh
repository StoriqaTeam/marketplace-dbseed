#!/bin/bash
# {"from":0,"query":{"bool":{"filter":[{"term":{"status":"published"}}],"must":{"nested":{"path":"name","query":{"match":{"name.text":"INPUT"}}}}}}}

declare -a arr=("foxwood_rus" "foxwood" "xwood" "foxwod" "fo" "fox" "fa" "fax" "foxw" "foxwo" "foxwoodrus" "wood" "LesMeduses" "hand" "faxwood" "xwood" "faxwod")

for i in "${arr[@]}"
do
   echo "$i"
   query='{"from":0,"query":{"bool":{"filter":[{"term":{"status":"published"}}],"must":{"nested":{"path":"name","query":{"multi_match":{"query":"'$i'","fields":["name.text.fuzzy_search","name.text.substring_search"],"type":"most_fields"}}}}}}}'
   curl -s -H "Content-Type:application/json" -X POST http://localhost:32776/stores/_search -d $query | jq -c -r '.hits.hits'
   printf '\n'
done
