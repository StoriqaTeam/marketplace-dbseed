#!/bin/bash
# {"from":0,"query":{"bool":{"filter":[{"term":{"status":"published"}}],"must":{"nested":{"path":"name","query":{"match":{"name.text":"INPUT"}}}}}}}

declare -a arr=("foxwood_rus" "foxwood" "xwood" "foxwod" "fo" "fox" "fa" "fax" "foxw" "foxwo" "foxwoodrus")

for i in "${arr[@]}"
do
   echo "$i"
   query='{"from":0,"query":{"bool":{"filter":[{"term":{"status":"published"}}],"must":{"nested":{"path":"name","query":{"fuzzy":{"name.text":{"value":"'$i'","boost":1.0,"fuzziness":2,"prefix_length":0}}}}}}}}'
   curl -s -H "Content-Type:application/json" -X POST http://localhost:32776/stores/_search -d $query | jq -c -r '.hits.hits'
   printf '\n'
done
