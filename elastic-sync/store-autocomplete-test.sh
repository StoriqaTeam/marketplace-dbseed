#!/bin/bash
# {"from":0,"query":{"bool":{"filter":[{"term":{"status":"published"}}],"must":{"nested":{"path":"name","query":{"match":{"name.text":"INPUT"}}}}}}}

declare -a arr=("foxwood_rus" "foxwood" "xwood" "foxwod" "fo" "fox" "fa" "fax" "foxw" "foxwo" "faxw")

for i in "${arr[@]}"
do
   echo "$i"
   query='{"_source":false,"suggest":{"name-suggest":{"completion":{"contexts":{"status":"published"},"field":"suggest_2","fuzzy":true,"size":101,"skip_duplicates":true},"prefix":"'$i'"}}}'
   echo "$query"
   curl -s -H "Content-Type:application/json" -X POST http://localhost:32776/stores/_search -d $query | jq -c -r '.suggest."name-suggest"[0]'
   printf '\n'
done
