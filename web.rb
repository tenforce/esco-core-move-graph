CHECK_AUTHORIZATION_QUERY = <<QUERY
PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
PREFIX esco: <http://data.europa.eu/esco/model#>

ASK
FROM <#{settings.graph}>
{
  ?x mu:uuid %uuid% ;
  a esco:Graph ;
  esco:status esco:Validated .
}
QUERY

UPDATE_METADATA_QUERY = <<QUERY
PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
PREFIX esco: <http://data.europa.eu/esco/model#>

WITH <#{settings.graph}>
DELETE
{
  ?x esco:status ?previous .
}
INSERT
{
  ?x esco:status esco:Imported .
}
WHERE
{
  ?x mu:uuid %uuid% ;
  a esco:Graph ;
  esco:status ?previous .
}
QUERY

FIND_GRAPH_QUERY = <<QUERY
PREFIX mu: <http://mu.semte.ch/vocabularies/core/>
PREFIX esco: <http://data.europa.eu/esco/model#>

SELECT ?graph
FROM <#{settings.graph}>
WHERE
{
  ?x mu:uuid %uuid% ;
  a esco:Graph ;
  esco:graph ?graph .
}
QUERY

get "/move" do
  uuid = params[:uuid]

  if uuid.nil?
    status 400
    body "Argument uuid is required"
    return
  end

  if !query(CHECK_AUTHORIZATION_QUERY.gsub("%uuid%", uuid.sparql_escape))
    status 403
    body "Unable to comply"
    return
  end

  graph_uri = query(FIND_GRAPH_QUERY.gsub("%uuid%", uuid.sparql_escape)).first["graph"]

  update("ADD GRAPH <#{graph_uri}> TO <#{settings.graph}>")
  update("CLEAR GRAPH <#{graph_uri}>")

  update(UPDATE_METADATA_QUERY.gsub("%uuid%", uuid.sparql_escape))

  status 204
end
