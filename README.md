# Augmenting Software Bills of Materials with Software Vulnerability Description: A Preliminary Study on GitHub

This repository contains the scripts, dataset, raw results and related materials for the study "Augmenting Software Bills of Materials with Software Vulnerability Description: A Preliminary Study on GitHub."

## Project structure

The project is organized into three folders.

### datasets
Contains datasets of SBOM and VEX used for the pull requests. To recreate the dataset, starting from a list of repositories containing SBOM files (`sbom_list.csv`), please run the Makefile (`make all`). This will generate the `gh_repos_with_stats_vulns.csv` dataset. Notice that the Makefile assumes that [Babashka](https://babashka.org) and [Jq](https://jqlang.github.io/jq/) are installed.

To generate a VEX from a SBOM, use the `sbom2vex.sh` script, which assumes [osv-scanner](https://github.com/google/osv-scanner) and [vexctl](https://github.com/openvex/vexctl) to be installed.

The folders `sboms` and `vex` contain the SBOM and VEX files for the repositories in the dataset. The latter are used as content for the pull requests in the selected repositories.

### pull_requests
This folder includes the (anonymized) text of the comment used when opening the pull request (`pr_message.txt`), and the resulting dataset (`pr_results.xlsx)`. For each of the analyzed repositories, the latter includes a link to the GitHub Pull Request, information about the pull request status (merged, rejected, open), the number of discussion messages, and the themes resulting from discussion after thematic analysis.

> [!WARNING]
> Reviewers please refrain to follow the link to individual pull requests during the review period to avoid violating double-blind. 

### survey 
The directory includes the dataset resulting from the answers maintainers provided to the survey (`survey_results.xlsx`). The survey asks maintainers whether they reviewed the pull request, and in positive case, whether the consider including vulnerability information through VEX was useful to them, with the possibility to provide additional comments.
