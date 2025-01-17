INPUT = ../esem-nier-2024/datasets/sbom_list.csv
OUTPUT = gh_repos_with_stats_vulns.csv
INTERMEDIATES = sbom_list.json gh_repos.txt gh_repos_with_stats.csv gh_repos_with_stats.json 

all: $(OUTPUT)
# Filter out all url containing a .gz file (i.e., a release SBOM) and gitlab repos
gh_repos.txt: $(INPUT)
	csvjson $(INPUT) > sbom_list.json
	cat sbom_list.json | jq '.[] | select((.URL | contains("gz") or contains("zip")) | not) | .name' | sed 's/\"//g;/gitlab/d' | sort -u > gh_repos.txt

# Run script to calculate stars, contributors, commits, etc for each repo
gh_repos_with_stats.json: gh_repos.txt
	bb -f calculate-repo-stats.clj gh_repos.txt gh_repos_with_stats.json

# Convert json to csv
gh_repos_with_stats.csv: gh_repos_with_stats.json
	jq -sr '(["name", "stars", "contributors", "commits"], (.[] | [.repository, .stars, .contributors, .commits])) | @csv' gh_repos_with_stats.json > gh_repos_with_stats.csv

# Create final dataset including the vulnerabilities with the stats 
$(OUTPUT): gh_repos_with_stats.csv
	csvjoin --left gh_repos_with_stats.csv $(INPUT) -c "name"> $@

clean:
	rm -f $(INTERMEDIATES)

.PHONY: all clean
