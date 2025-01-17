#!/usr/bin/env bb
(require '[clojure.java.io :as io]
         '[cheshire.core :as json]
         '[babashka.http-client :as client])

(defn get-github-api [endpoint]
  (let [url (str "https://api.github.com" endpoint)
        token (System/getenv "GITHUB_TOKEN")
        headers {"Authorization" (str "Bearer " token) "Accept" "application/vnd.github+json"}]
    (try 
      (-> (client/get url {:headers headers})
        :body
        (json/parse-string true))
      (catch Exception e 
        (let [status (:status (ex-data e))]
          (when (= status 400)
            (println "repo not found"))
          nil))
      )))

; repo url are in the format github.com/owner/repo
(defn get-repo-name [repo]
  (let [parts (clojure.string/split repo #"/")]
    (str (second parts) "/" (last parts))))

(defn fetch-repo-stats [repo]
  (println "Fetching stats for" repo)
  (if-let [repo-name (get-repo-name repo)
           repo-data (get-github-api (str "/repos/" repo-nane))]
    (let [stars (get-in (get-github-api (str "/repos/" repo-name)) [:stargazers_count])
        contributors (count (get-github-api (str "/repos/" repo-name "/stats/contributors")))
        commit-activity (reduce + (map :total (get-github-api (str "/repos/" repo-name "/stats/commit_activity"))))]
    {:repository repo
     :stars stars
     :contributors contributors
     :commits commit-activity})
    (println "Skipping repo")))

(defn read-repos [file-path]
  (with-open [rdr (io/reader file-path)]
    (doall (line-seq rdr))))

(defn write-json [data output-file]
  (with-open [wrtr (io/writer output-file :append true)]
    (.write wrtr (str (json/generate-string data) "\n"))))

; (defn -main [& args]
;     (let [input-file (first args)
;           output-file (second args)
;           repos (read-repos input-file)]
;       (doseq [repo repos]
;         (let [stats (fetch-repo-stats repo)]
;           (write-json stats output-file)))))
(defn show-help []
  (println (str "Usage: " (last (clojure.string/split *file* #"/")) " <input-file> <output-file>"))
  (println (str "Example: " (last (clojure.string/split *file* #"/"))" repos.txt output.json")))

(defn -main [& args]
  (if (not= (count args) 2)
    (show-help)
    (let [input-file (first args)
          output-file (second args)]
      (try
        (let [repos (read-repos input-file)]
          (doseq [repo repos]
            (let [stats (fetch-repo-stats repo)]
              (write-json stats output-file))))
        (catch Exception e
          (println "Error: " (.getMessage e))
          (show-help))))))

(comment 
    (get-repo-name "github.com/borkdude/babashka")
    (read-repos "repos_for_parsing_ESEM.txt")
    (get-github-api "/repos/borkdude/babashka")
    (fetch-repo-stats "borkdude/babashka"))

; Main entry point
(apply -main *command-line-args*)
