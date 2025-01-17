#!/bin/bash

# Check if an argument is provided
if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <sbom-file>"
  exit 1
fi

# Get the input SBOM file and derive the VEX file name
sbom_file="$1"
vex_file="${sbom_file%.json}.vex.json"
merge_products=false

# Check if we want to merge in a single list all tested products with the same CVE
if [[ "$2" == "--merge-products" ]]; then
  merge_products=true
fi

# Run osv-scanner and store the output in a variable
osv_output=$(osv-scanner -S "$sbom_file" --format json)

if echo "$osv_output" | jq -e '.results | length == 0' > /dev/null; then
  echo "No vulnerabilities found in osv-scanner results. Exiting."
  exit 0
fi
# Extract the data using jq and store it in a variable
results=$(
echo "$osv_output" | jq -r '[
.results[].packages[] |
  select(.vulnerabilities != null and .vulnerabilities[]?.aliases != null) |
    . as $pkg |
    {
      purl: (
      "pkg:" + 
      ($pkg.package.ecosystem | ascii_downcase) + "/" +
      ($pkg.package.name) +
      (if $pkg.package?.version != null and $pkg.package.version != "" then
      "@" + $pkg.package.version
    else
      ""
    end) |
      gsub("%40"; "@") | gsub("%2F"; "/") | gsub("%3A"; ":") |
      gsub("%2D"; "-") | gsub("%2E"; ".") | gsub("%5F"; "_") |
      gsub("%7E"; "~")
          ),
          cve: (
          $pkg.vulnerabilities[]?.aliases[]? |
            select(test("^CVE-"))
              )
            }
            ] | unique | .[] | select(.purl != "@" and .cve != null) |
              "\(.purl) \(.cve)"')
                          # Initialize a flag to track the first element
                          first_element=true

# Iterate over the extracted results
while IFS= read -r line; do
  purl=$(echo "$line" | awk '{print $1}')
  cve=$(echo "$line" | awk '{print $2}')

  if $first_element; then
    # For the first element, use the 'create' command
    vexctl create "$purl" "$cve" under_investigation --file "$vex_file"
    first_element=false
  else
    # For subsequent elements, use the 'add' command
    vexctl add -i "$vex_file" --product="$purl" --vuln="$cve" --status="under_investigation"
  fi

done <<< "$results"

if $merge_products; then
jq '{
  "@context": .["@context"],
  "@id": .["@id"],
  "author": .author,
  "timestamp": .timestamp,
  "last_updated": .last_updated,
  "version": .version,
  "statements": [
    (.statements | group_by(.vulnerability.name)[] | {
      "vulnerability": {"name": .[0].vulnerability.name},
      "timestamp": .[0].timestamp,
      "products": (map(.products[]."@id") | unique | map({ "@id": . })),
      "status": .[0].status
    })
  ]
}' $vex_file > tmp.json && mv tmp.json $vex_file
fi

