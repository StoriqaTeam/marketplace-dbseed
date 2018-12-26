#!/bin/bash
# {"from":0,"query":{"bool":{"filter":[{"term":{"status":"published"}}],"must":{"nested":{"path":"name","query":{"match":{"name.text":"INPUT"}}}}}}}

declare -a arr=("foxwood_rus" "foxwood" "xwood" "foxwod" "faxwood" "xwood" "faxwod" "foxwood_ru")

for i in "${arr[@]}"
do
   echo "$i"
   query='{"from":0,"query":{"bool":{"filter":[{"term":{"status":"published"}}],"must":{"nested":{"path":"name","query":{"match":{"name.text":{"query":"'$i'","fuzziness":"AUTO"}}}}}}}}'
   curl -s -H "Content-Type:application/json" -X POST http://localhost:32813/stores/_search -d $query | jq -c -r '.hits.hits'
   printf '\n'
done
