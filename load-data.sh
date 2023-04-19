#!/bin/bash

# Log the info with the same format as NEO4J outputs
log_info() {
  # https://www.howtogeek.com/410442/how-to-display-the-date-and-time-in-the-linux-terminal-and-use-it-in-bash-scripts/
  printf '%s %s\n' "$(date -u +"%Y-%m-%d %H:%M:%S:%3N%z") INFO  MGT: $1"
  return
}

# turn on bash's job control
set -m

log_info "Loading data"

# crate a constraint for person and movie on id proprty
bin/cypher-shell --database=neo4j "CREATE CONSTRAINT personIdConstraint FOR (person:Person) REQUIRE person.id IS UNIQUE" -u neo4j -p password
bin/cypher-shell --database=neo4j "CREATE CONSTRAINT movieIdConstraint FOR (movie:Movie) REQUIRE movie.id IS UNIQUE" -u neo4j -p password

# create an index on country node on name property
bin/cypher-shell --database=neo4j "CREATE INDEX FOR (c:Country) ON (c.name)" -u neo4j -p password

# load persons.csv
bin/cypher-shell --database=neo4j 'LOAD CSV WITH HEADERS FROM "file:///persons.csv" AS csvLine CREATE (p:Person {id:toInteger(csvLine.id), name:csvLine.name})' -u neo4j -p password

# load movies.csv
bin/cypher-shell --database=neo4j 'LOAD CSV WITH HEADERS FROM "file:///movies.csv" AS csvLine MERGE (country:Country {name:csvLine.country}) CREATE (movie:Movie {id:toInteger(csvLine.id), title:csvLine.title, year:toInteger(csvLine.year)}) CREATE (movie)-[:ORIGIN]->(country)' -u neo4j -p password

# load roles.csv
bin/cypher-shell --database=neo4j 'LOAD CSV WITH HEADERS FROM "file:///roles.csv" AS csvLine CALL {WITH csvLine MATCH (person:Person {id: toInteger(csvLine.personId)}), (movie:Movie {id: toInteger(csvLine.movieId)}) CREATE (person)-[:ACTED_IN {role: csvLine.role}]->(movie)} IN TRANSACTIONS OF 2 ROWS' -u neo4j -p password