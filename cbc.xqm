xquery version "3.1" ;
module namespace cbc.rest = "cbc.rest" ;

(:~
 : This xquery module is an application for cbc
 :
 : @author emchateau
 : @since 2021-12-26
 : @licence GNU http://www.gnu.org/licenses
 : @version 0.1
 :
 : cbc is free software: you can redistribute it and/or modify
 : it under the terms of the GNU General Public License as published by
 : the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 :)

import module namespace G = "cbc.globals" at './globals.xqm' ;

import module namespace cbc.mappings = "cbc.mappings" at './mappings.xqm' ;
import module namespace cbc.models = 'cbc.models' at './models.xqm' ;
import module namespace Session = 'http://basex.org/modules/session';

declare namespace rest = "http://exquery.org/ns/restxq" ;
declare namespace file = "http://expath.org/ns/file" ;
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization" ;
declare namespace db = "http://basex.org/modules/db" ;
declare namespace web = "http://basex.org/modules/web" ;
declare namespace update = "http://basex.org/modules/update" ;
declare namespace perm = "http://basex.org/modules/perm" ;
declare namespace user = "http://basex.org/modules/user" ;
declare namespace session = "http://basex.org/modules/session" ;
declare namespace http = "http://expath.org/ns/http-client" ;

declare namespace ev = "http://www.w3.org/2001/xml-events" ;
declare namespace map = "http://www.w3.org/2005/xpath-functions/map" ;
declare namespace xf = "http://www.w3.org/2002/xforms" ;
declare namespace xlink = "http://www.w3.org/1999/xlink" ;

declare namespace cbc = "http://conbavil.fr/namespace" ;
declare default element namespace "http://conbavil.fr/namespace" ;
declare default function namespace "cbc.rest" ;

declare default collation "http://basex.org/collation?lang=fr" ;

(:~
 : This resource function defines the application home
 : @return redirect to the report list
 :)
declare
  %rest:path("/cbc/home")
  %output:method("xml")
function home() {
  web:redirect("/cbc/rapports")
};

(:~
 : This resource function lists all the files
 : @return an ordered list of report in xml
 :)
declare
  %rest:path("/cbc/files")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getFiles() {
  let $queryParams := map {}
  let $data := db:open("cbc")//file
  let $outputParams := map {}
  return array{
    for $file in $data return
    map {
      "title" : fn:normalize-space($file/title) , (: @todo deal with mix content:)
      "idno" : fn:normalize-space($file/idno)
    }
  }
};

(:~
 : This resource function lists all the meetings
 : @return an ordered list of report in xml
 :)
declare
  %rest:path("/cbc/meetings")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:query-param("dpt", "{$dpt}")
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 50)
function getMeetings($dpt as xs:string?, $start, $count) {
  let $queryParams := map {}
  let $data := db:open("cbc")/conbavil/files/file/meetings
  let $outputParams := map {}
  return array{
    for $meeting in fn:subsequence($data/meeting, 1, $count)
    (: where
      if ($dpt)
      then $meeting satisfies deliberations/deliberation/localisation/departement[@type="decimal"][fn:contains(., $dpt)]]
      else fn:true()
    :)
    return map {
      "title" : $meeting/title => fn:normalize-space(), (: @todo deal with mix content:)
      "date" : $meeting/date/@when => fn:normalize-space(),
      "cote" : $meeting/parent::meetings/parent::file/idno => fn:normalize-space(),
      "coteDev" : $meeting/parent::meetings/parent::file/title => fn:normalize-space(),
      "pages" : getPages($meeting, map{}),
      "nb" : $meeting/deliberations/deliberation => fn:count(),
      "types" : array{extractBuildingTypes($meeting, map{})},
      "categories" : array{extractCategories($meeting, map{})},
      "deliberations" : array{
        for $deliberation in $meeting/deliberations/deliberation
        return map{
          "id" : $deliberation/@xml:id => fn:normalize-space(),
          "title" : $deliberation/title => fn:normalize-space(),
          "commune" : $deliberation/localisation/commune[1] => fn:normalize-space(),
          "departement" : $deliberation/localisation/departement[@type="decimal"] => fn:normalize-space()
        }
      }
    }
  }
};

declare function getPages($meeting as element(), $params as map(*)) as map(*) {
  let $pages := $meeting/deliberations/deliberation/pages ! fn:analyze-string(., '\d+')//fn:match
    => fn:distinct-values()
    => fn:sort()
  return
    if (fn:count($pages) >1)
    then map {
      "label" : "pp.",
      "pages" : $pages[1] || "-" || $pages[fn:last()]
    }
    else map {
      "label" : "p.",
      "pages" : $pages[1]
    }
};

declare function extractBuildingTypes($meeting as element(), $params as map(*)) as item()* {
  let $buildingType := $meeting//categories/category[@type="buildingType"]
    => fn:distinct-values()
  return $buildingType
};

declare function extractCategories($meeting as element(), $params as map(*)) as item()* {
  let $categories := $meeting//categories/category[@type="projectGenre"]
    => fn:distinct-values()
  return $categories
};

(:~
 : This resource function lists all the meetings
 : @return an ordered list of report in xml
 :)
declare
  %rest:path("/cbc/types")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getTypes() {
  array{
    db:open("cbc")/conbavil/files/file/meetings/meeting/deliberations/deliberation/categories/category[@type="buildingType"][.!=""]
    => fn:distinct-values()
    => fn:sort()
  }
};

(:~
 : This resource function lists all the meetings
 : @return an ordered list of report in xml
 :)
declare
  %rest:path("/cbc/categories")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getCategories() {
  array{
    db:open("cbc")/conbavil/files/file/meetings/meeting/deliberations/deliberation/categories/category[@type="projectGenre"][.!=""]
      => fn:distinct-values()
      => fn:sort()
  }
};

(:~
 : This resource function lists all the deliberations
 : @return an json collection of deliberations
 :)
declare
  %rest:path("/cbc/deliberations")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:query-param("dpt", "{$dpt}", 'all')
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 1000)
function getDeliberations($dpt, $start, $count) {
  let $deliberations := db:open("cbc")/conbavil/files/file/meetings/meeting/deliberations/deliberation
  let $meta := map {
    'start' : $start,
    'count' : $count,
    'totalItems' : fn:count($deliberations)
  }
  let $content := array{
    for $deliberation in fn:subsequence($deliberations, $start, $count)
    return map{
      "seance" : $deliberation/parent::deliberations/parent::meeting/date/@when => fn:normalize-space(),
      "cote" : $deliberation/parent::deliberations/parent::meeting/parent::meetings/parent::file/idno => fn:normalize-space(),
      "id" : $deliberation/@xml:id => fn:normalize-space(),
      "title" : $deliberation/title => fn:normalize-space(),
      "item" : $deliberation/item => fn:normalize-space(),
      "pages" : $deliberation/pages => fn:normalize-space(),
      "localisation" : map {
        "commune" : $deliberation/localisation/commune[.!=@type] => fn:normalize-space(),
        "communeAncien" : $deliberation/localisation/commune[@type="orig"] => fn:normalize-space(),
        "adress" : $deliberation/localisation/adresse[@type="orig"] => fn:normalize-space(),
        "departementDecimal" : $deliberation/localisation/departement[@type="decimal"] => fn:normalize-space(),
        "departement" : $deliberation/localisation/departement[fn:not(@type)] => fn:normalize-space(),
        "departementAncien" : $deliberation/localisation/departement[@type="orig"] => fn:normalize-space(),
        "region" : $deliberation/localisation/region => fn:normalize-space()
      },
      "types" : array{extractBuildingTypes($deliberation, map{})},
      "categories" : array{extractCategories($deliberation, map{})},
      "report" : fn:normalize-space($deliberation/report) => fn:normalize-space(),
      "recommendation" : fn:normalize-space($deliberation/recommendation) => fn:normalize-space(),
      "advice" : fn:normalize-space($deliberation/recommendation) => fn:normalize-space(),
      "affaireId": ""
    }
  }
  return map{
    "meta": $meta,
    "content": $content
  }
};

(:~
 : This resource function lists all the reports
 : @return a json deliberation
 :)
declare
  %rest:path("/cbc/deliberations/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getDeliberationById($id) {
  let $deliberation := db:open("cbc")//deliberation[@xml:id = $id]
  return map{
    "seance" : $deliberation/parent::deliberations/parent::meeting/date/@when => fn:normalize-space(),
    "cote" : $deliberation/parent::deliberations/parent::meeting/parent::meetings/parent::file/idno => fn:normalize-space(),
    "id" : $deliberation/@xml:id => fn:normalize-space(),
    "title" : $deliberation/title => fn:normalize-space(),
    "item" : $deliberation/item => fn:normalize-space(),
    "pages" : $deliberation/pages => fn:normalize-space(),
    "localisation" : map {
      "commune" : $deliberation/localisation/commune => fn:normalize-space(),
      "adress" : $deliberation/localisation/adresse[@type="orig"] => fn:normalize-space(),
      "departementDecimal" : $deliberation/localisation/departement[@type="decimal"] => fn:normalize-space(),
      "departement" : $deliberation/localisation/departement[fn:not(@type)] => fn:normalize-space(),
      "departementAncien" : $deliberation/localisation/departement[@type="orig"] => fn:normalize-space(),
      "region" : $deliberation/localisation/region => fn:normalize-space()
    },
    "types" : array{extractBuildingTypes($deliberation, map{})},
    "categories" : array{extractCategories($deliberation, map{})},
    "report" : fn:normalize-space($deliberation/report) => fn:normalize-space(),
    "recommendation" : fn:normalize-space($deliberation/recommendation) => fn:normalize-space()
  }
};

(:~
 : This resource function lists all the deliberations
 : @return an json collection of deliberations
 :)
declare
  %rest:path("/cbc/affairs")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:query-param("dpt", "{$dpt}", 'all')
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 1000)
function getAffairs($dpt, $start, $count) {
  let $affairs := db:open("cbc")/conbavil/affairs
  let $meta := map {
    'start' : $start,
    'count' : $count,
    'totalItems' : fn:count($affairs)
  }
  let $content := array{
    for $affair in fn:subsequence($affairs, $start, $count)
    return map{
      "head" : $affair/head,
      "localisation" : map {
        "commune" : $affair/localisation/commune => fn:normalize-space(),
        "departementDecimal" : $affair/localisation/departement[@type="decimal"] => fn:normalize-space(),
        "departement" : $affair/localisation/departement[fn:not(@type)] => fn:normalize-space(),
        "departementAncien" : $affair/localisation/departement[@type="orig"] => fn:normalize-space(),
        "region" : $affair/localisation/region => fn:normalize-space()
      },
      "types" : array{extractBuildingTypes($affair, map{})},
      "deliberations" : array{$affair/deliberations/*}
    }
  }
  return map{
    "meta": $meta,
    "content": $content
  }
};

(:~
 : This resource function lists all the reports
 : @return a json deliberation
 :)
declare
  %rest:path("/cbc/affairs/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getAffairsById($id) {
  let $affairs := db:open("cbc")/conbavil/affairs/affair[@xml:id = $id]
  let $meta := map {
      'totalItems' : fn:count($affairs)
    }
  let $content := map {}
  return map{
    "meta" : $meta,
    "content" : $content
  }
};

(:~
 : This resource function post a new affair
 : @todo change path
 :)
declare
  %rest:path("/cbc/post")
  %rest:POST("{$content}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function postDeliberation($content) {
  map{
    "content" : $content,
    "message" : "La ressource a été ajoutée."
  }
};

(:~
 : This resource function post a new affair
 : @todo add id
 :)
declare
  %rest:path("/cbc/postaffairs/post")
  %rest:POST("{$content}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %updating
function postAffair($content) {
  (
    let $affairs := db:open('cbc')/conbavil/affairs
    let $affair := <affair xml:id="{fn:generate-id($affairs)}">{json:parse($content)/*/node()}</affair>
    return insert node $affair into $affairs,
    update:output(
    (
            <rest:response>
              <http:response status="200" message="">
                <http:header name="Content-Language" value="fr"/>
                <http:header name="Content-Type" value="text/plain; charset=utf-8"/>
              </http:response>
            </rest:response>,
            map {
              "message" : "La ressource a bien été ajoutée."
            }
          )
       )
    )
};