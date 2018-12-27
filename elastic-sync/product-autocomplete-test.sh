#!/bin/bash
# {"_source":false,"suggest":{"name-suggest":{"completion":{"contexts":{"store_and_status":["Published"]},"field":"suggest_2","fuzzy":true,"size":101,"skip_duplicates":true},"prefix":"product"}}}

declare -a arr=("product" "poduct" "po" "pro" "prd" "pod" "pru")

for i in "${arr[@]}"
do
   echo "$i"
   query='{"_source":false,"suggest":{"name-suggest":{"completion":{"contexts":{"store_and_status":["published"]},"field":"suggest","fuzzy":true,"size":101,"skip_duplicates":true},"prefix":"'$i'"}}}'
   curl -s -H "Content-Type:application/json" -X POST http://localhost:32776/products/_search -d $query | jq -c -r '.suggest."name-suggest"[0]'
   printf '\n'
done
