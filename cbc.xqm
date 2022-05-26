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

(:~ import module namespace G = "cbc.globals" at './globals.xqm' ;

import module namespace cbc.mappings = "cbc.mappings" at './mappings.xqm' ;
import module namespace cbc.models = 'cbc.models' at './models.xqm' ; 
import module namespace Session = 'http://basex.org/modules/session' ; ~:)

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
  array {
    for $file in db:open("cbc")//file return
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
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getMeetings($start, $count) {
  let $data := db:open("cbc")/conbavil/files/file/meetings
  let $meta := map {
    'start' : $start,
    'count' : $count,
    'totalItems' : fn:count($data)
  }
  let $content :=  array{
    for $meeting in fn:subsequence($data/meeting, $start, $count)
    return map {
      "title" : $meeting/title => fn:normalize-space(), (: @todo deal with mix content:)
      "date" : $meeting/date/@when => fn:normalize-space(),
      "cote" : $meeting/parent::meetings/parent::file/idno => fn:normalize-space(),
      "coteDev" : $meeting/parent::meetings/parent::file/title => fn:normalize-space(),
      "pages" : getPages($meeting, map{}),
      "nb" : $meeting/deliberations/deliberation => fn:count(),
      "types" : array{ extractBuildingTypes($meeting) },
      "categories" : array{ extractCategories($meeting) },
      "deliberations" : array{
        for $deliberation in $meeting/deliberations/deliberation
        return deliberationToMap($deliberation)
      }
    }
  }

  return map{
    "meta": $meta,
    "content": $content
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

declare function extractBuildingTypes($element as element()) as item()* {
  let $buildingType := $element//categories/category[@type="buildingType"]
    => fn:distinct-values()
  return array { $buildingType }
};

declare function extractCategories($element as element()) as item()* {
  let $categories := $element//categories/category[@type="projectGenre"]
    => fn:distinct-values()
  return array { $categories }
};

declare function httpResponse($code as xs:integer, $msg as xs:string) as item()+ {
  let $res := (
     <rest:response>
          <http:response status="{$code}" message="">
            <http:header name="Content-Language" value="fr"/>
            <http:header name="Content-Type" value="text/plain; charset=utf-8"/>
          </http:response>
        </rest:response>,
        map {
          "message" : $msg
        }
  )
  return $res
};

declare function getDeliberation($id as xs:string, $meetingId as xs:string) as element() {
   db:open('cbc')/conbavil/files/file/meetings
        /meeting[@xml:id = $meetingId]
        //deliberation[@xml:id = $id]
};

declare function getAffair($id as xs:string) as element() {
   db:open('cbc')/conbavil//affair[@xml:id = $id]
};

declare function deliberationToMap($deliberation as element()) as map(*) {
 let $result := map{
      "meetingId": $deliberation/meetingId => fn:normalize-space(),
      "affairId": $deliberation/affairId => fn:normalize-space(),
      "seance" : $deliberation/parent::deliberations/parent::meeting/date/@when => fn:normalize-space(),
      "cote" : $deliberation/parent::deliberations/parent::meeting/parent::meetings/parent::file/idno => fn:normalize-space(),
      "id" : $deliberation/@xml:id => fn:normalize-space(),
      "title" : $deliberation/title => fn:normalize-space(),
      "altTitle" : $deliberation/altTitle => fn:normalize-space(),
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
      "types" : extractBuildingTypes($deliberation),
      "categories" : extractCategories($deliberation),
      "report" : $deliberation/report => fn:normalize-space(),
      "recommendation" : $deliberation/recommendation => fn:normalize-space(),
      "advice" : $deliberation//advice => fn:normalize-space()
    }
    return $result
};

declare function affairToMap($affair as element()) as map(*) {
  let $result := map{
    'id': $affair/[@xml:id] => fn:normalize-space(),
    'title': $affair/title => fn:normalize-space(),
    'localisation': map{
      'commune': $affair/localisation/commune => fn:normalize-space(),
      'departementDecimal': $affair/localisation/departementDecimal => fn:normalize-space(),
      'departement': $affair/localisation/departement => fn:normalize-space(),
      'departementAncien': $affair/localisation/departementAncien => fn:normalize-space(),
      'region': $affair/localisation/region => fn:normalize-space()
    },
    'types': extractBuildingTypes($affair),
	  'deliberations': array{
      for $deliberation in $affair/deliberations/deliberation
      let $id := $deliberation/[@id] => fn:normalize-space()
      let $meetingId := $deliberation/[@meetingId] => fn:normalize-space()
      let $d := db:open("cbc")/conbavil/files/file/meetings/meeting[@xml:id = $meetingId]/deliberations/deliberation[@xml:id = $id]
      return deliberationToMap($d)
    },
    'meta': metaToArray($affair)
  }
  return $result
};

declare function metaToArray($element as element()) as array(*) {
  let $meta := array{
    for $m in $element//change
    return map {
        'type': $m/[@type] => fn:normalize-space(),
        'when': $m/[@when] => fn:normalize-space(),
        'who': $m/[@who] => fn:normalize-space()
      } 
  }
  return $meta
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
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getDeliberations($start, $count) {
  let $deliberations := db:open("cbc")/conbavil/files/file/meetings/meeting/deliberations/deliberation
  let $meta := map {
    'start' : $start,
    'count' : $count,
    'totalItems' : fn:count($deliberations)
  }
  let $content := array{
    for $deliberation in fn:subsequence($deliberations, $start, $count)
    return deliberationToMap($deliberation)
  }
  return map{
    "meta": $meta,
    "content": $content
  }
};

(:~
 : This resource function searches for deliberations 
 : based on parms provided on post request.
 : @return an json collection of deliberations
 :)
declare
  %rest:path("/cbc/search")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:POST("{$content}")
function search($content) {
  let $body := json:parse($content, map{'format': 'xquery'})
  let $terms := $body('terms')
  let $element := $body('element')

  let $elements := db:open('cbcFt')//*[fn:name() = $element][
    text() contains text {for $t in $terms return $t} all words
  ]
    
  let $meta := map {
    'start' : xs:integer($body('meta')('start')),
    'count' : xs:integer($body('meta')('count')),
    'totalItems' : fn:count($elements)
  }

  let $results := switch ($element)
    case 'deliberation'
      return array {
        for $d in fn:subsequence($elements, $meta('start'), $meta('count'))
        return deliberationToMap(
          getDeliberation($d/@xml:id => fn:normalize-space(), $d/@meetingId => fn:normalize-space())
        )
      }
    case 'affair'
      return array{
        for $d in fn:subsequence($elements, $meta('start'), $meta('count'))
        return affairToMap(
          getAffair($d/@xml:id => fn:normalize-space())
        )
      }
    default return map{}

  return map{
    "meta": $meta,
    "content": $results
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
  return deliberationToMap($deliberation)
};


(:~
 : This resource function returns all possible values
 : for faceted search
 :)
declare
  %rest:path("/cbc/facets")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getDeliberationFacets() {
  map {
    'commune': array { for $x in db:open('cbcFacets')//commune/@text return $x => fn:normalize-space()},
    'region': array { for $x in db:open('cbcFacets')//region/@text return $x => fn:normalize-space()},
    'departement': array { for $x in db:open('cbcFacets')//departement/@text return $x => fn:normalize-space()},
    'departementAncien': array { for $x in db:open('cbcFacets')//departementAncien/@text return $x => fn:normalize-space()},
    'projectGenre': array{ for $x in db:open('cbcFacets')//projectGenre/@text return $x => fn:normalize-space()},
    'buildingType': array{ for $x in db:open('cbcFacets')//buildingType/@text return $x => fn:normalize-space()},
    'buildingCategory': array{ for $x in db:open('cbcFacets')//buildingCategory/@text return $x => fn:normalize-space() },
    'administrativeObject': array{ for $x in db:open('cbcFacets')//administrativeObject/@text return $x => fn:normalize-space()},
    'participant': array{ for $x in db:open('cbcFacets')//participant/@persName return $x => fn:normalize-space()}
  }
};


(:~
 : This resource function lists all the deliberations
 : @return an json collection of deliberations
 :)
declare
  %rest:path("/cbc/affaires")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getAffairs($start, $count) {
  let $affairs := db:open("cbc")/conbavil/affairs/affair
  let $meta := map {
    'start' : $start,
    'count' : $count,
    'totalItems' : fn:count($affairs)
  }
  let $content := array{
    for $affair in fn:subsequence($affairs, $start, $count)
    return affairToMap($affair)
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
  %rest:path("/cbc/affaires/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getAffairsById($id) {
  let $affair := db:open("cbc")/conbavil/affairs/affair[@xml:id = $id]
  return affairToMap($affair)
};

(:~
 : This resource function return all affaires linked to deliberations passed as params
 : @todo change path
 :)
declare
  %rest:path("/cbc/affaires/fromDeliberations")
  %rest:POST("{$content}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function affairesFromDeliberations($content) {
  let $deliberationIds := json:parse($content, map {'format': 'xquery'})("body")

  let $result :=
    for $affair in db:open('cbc')/conbavil/affairs/affair
    where
      array{
        for $i in $affair/deliberations/node()/text()
        return $i => fn:normalize-space()
      } = $deliberationIds
    return $affair

  return array{
    for $affair in $result
    return affairToMap($affair)
  }
};

(:~
 : This resource function post a new affair
 : @todo add id
 :)
declare
  %rest:path("/cbc/affaires/post")
  %rest:POST("{$content}")
  %rest:produces('application/json')
  %output:media-type('text/plain; charset=utf-8')
  %output:method('json')
  %updating
function postAffair($content) {
  let $body := json:parse($content, map {'format': 'xquery'})
  let $data := $body('affaire')
  let $type := $body('type')

  let $affairs := db:open('cbc')/conbavil/affairs

  let $affairId := 
    if ($type = 'modification') then $data('id')
    else fn:generate-id($affairs)

  let $affair := (
    <affair xml:id="{$affairId}">
      <title>{$data('title')}</title>
      <localisation>
        <commune>{$data('localisation')('commune')}</commune>
        <departement>{$data('localisation')('departement')}</departement>
        <departementDecimal>{$data('localisation')('departementDecimal')}</departementDecimal>
        <departementAncien>{$data('localisation')('departementAncien')}</departementAncien>
        <region>{$data('localisation')('region')}</region>
      </localisation>
      <deliberations>
      {
        for $i in (1 to array:size($data('deliberations')))
        return <deliberation id="{ $data('deliberations')($i)('id') }" meetingId="{ $data('deliberations')($i)('meetingId') }"/>
      }
      </deliberations>
      <categories>
      {
        for $i in (1 to array:size($data('types')))
        return <category type="buildingType">{ $data('types')($i) }</category>
      }
      </categories>
      <meta>
      {
        for $i in (1 to array:size($data('meta')))
        return <change type="{ $data('meta')($i)('type') }" who="{ $data('meta')($i)('who') }" when="{ $data('meta')($i)('when') }" />
      }
      </meta>
    </affair>
  )
  return 
  switch ($type) 
    case "modification" 
      return (
        replace node db:open('cbc')/conbavil/affairs/affair[@xml:id = $affairId] with $affair,
        for $i in (1 to array:size($data('deliberations')))
        return replace value of node db:open('cbc')//deliberations[@xml:id = $data('deliberations')($i)('id')] with $affairId,
        update:output(httpResponse(200, 'La ressource bien été modifiée.'))
      )
    case "creation" 
      return (
        insert node $affair into $affairs,
        for $i in (1 to array:size($data('deliberations')))
        return replace value of node db:open('cbc')//deliberation[@xml:id = $data('deliberations')($i)('id')]/affairId with $affairId,
        update:output(httpResponse(200, 'La ressource bien été créée.'))
      )
    default 
      return update:output(httpResponse(500, "Un problème est survenu, la ressource n'a pas pu être créée/modifiée."))
};