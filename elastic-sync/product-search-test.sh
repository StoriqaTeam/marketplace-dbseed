#!/bin/bash
# {"from":0,"query":{"bool":{"filter":[{"nested":{"inner_hits":{"_source":false,"docvalue_fields":["variants.prod_id"],"sort":[]},"path":"variants","query":{"bool":{"filter":[{"exists":{"field":"variants"}}]}}}}],"must":{"bool":{"should":[{"nested":{"path":"name","query":{"match":{"name.text":"'$i'"}}}},{"nested":{"path":"short_description","query":{"match":{"short_description.text":"'$i'"}}}},{"nested":{"path":"long_description","query":{"match":{"long_description.text":"'$i'"}}}}]}}}},"size":101,"sort":[]}

declare -a arr=("product" "poduct" "po" "pro" "prd" "pod" "pru")

for i in "${arr[@]}"
do
   echo "$i"
   query='{"from":0,"query":{"bool":{"filter":[{"nested":{"inner_hits":{"_source":false,"docvalue_fields":["variants.prod_id"],"sort":[]},"path":"variants","query":{"bool":{"filter":[{"exists":{"field":"variants"}}]}}}}],"must":{"bool":{"should":[{"nested":{"path":"name","query":{"fuzzy":{"name.text":{"value":"'$i'"}}}}},{"nested":{"path":"short_description","query":{"match":{"short_description.text":"'$i'"}}}},{"nested":{"path":"long_description","query":{"match":{"long_description.text":"'$i'"}}}}]}}}},"size":101,"sort":[]}'
   curl -s -H "Content-Type:application/json" -X POST http://localhost:32776/products/_search -d $query | jq -c -r '.hits.hits'
   printf '\n'
done
