xquery version "3.1" ;
module namespace cbc.rest = "cbc.rest" ;

(:~
 : This xquery module is an application for cbc
 :
 : @author emchateau
 : @since 2024-10
 : @licence GNU http://www.gnu.org/licenses
 : @version 0.3
 :
 : cbc is free software: you can redistribute it and/or modify
 : it under the terms of the GNU General Public License as published by
 : the Free Software Foundation, either version 3 of the License, or
 : (at your option) any later version.
 :
 :)

import module namespace G = "cbc.globals" at './globals.xqm' ;

(:~
 : import module namespace cbc.mappings = "cbc.mappings" at './mappings.xqm' ;
 : import module namespace cbc.models = 'cbc.models' at './models.xqm' ;
 : import module namespace Session = 'http://basex.org/modules/session' ;
:)

declare namespace db = "http://basex.org/modules/db" ;
declare namespace file = "http://expath.org/ns/file" ;
declare namespace fn = "http://www.w3.org/2005/xpath-functions" ;
declare namespace http = "http://expath.org/ns/http-client" ;
declare namespace json = "http://basex.org/modules/json" ;
declare namespace map = "http://www.w3.org/2005/xpath-functions/map" ;
declare namespace output = "http://www.w3.org/2010/xslt-xquery-serialization" ;
declare namespace perm = "http://basex.org/modules/perm" ;
declare namespace rest = "http://exquery.org/ns/restxq" ;
declare namespace session = "http://basex.org/modules/session" ;
declare namespace update = "http://basex.org/modules/update" ;
declare namespace user = "http://basex.org/modules/user" ;
declare namespace web = "http://basex.org/modules/web" ;

declare namespace cbc = "http://public.archi/conbavil/namespace" ;
declare default element namespace "http://public.archi/conbavil/namespace" ;
declare default function namespace "cbc.rest" ;

import module namespace cbc.models = 'cbc.models' at './models.xqm' ;

declare default collation "http://basex.org/collation?lang=fr" ;

(:~
 : This resource function defines the application home
 : @return redirect to the report list
 :)
declare
  %rest:path("/cbc/")
  %output:method("xml")
function home() {
  web:redirect("/cbc/reports")
};

(:~
 : Resource function for the files
 : @param $start the item position to start from
 : @param $count the number of item to return
 : @return a json collection of files
 : @todo change key
 :)
declare
  %rest:path("/cbc/files")
  %rest:produces("application/json")
  %output:media-type("application/json")
  %output:method("json")
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getFiles($start, $count) {
  let $data := db:get('cbc')/conbavil/files/file
  let $meta := map {
    'title' : "Liste des cotes",
    'idno' : $G:domain || "/cbc/files",
    'id' : 'files',
    'start' : $start,
    'count' : $count,
    'quantity' : fn:count($data)
    }
  let $content := array {
    for  $file in $data
    return map {
        'title' : fn:normalize-space($file/title), (: @todo deal with mix content:)
        'idno' : $G:domain || "/cbc/files/" || $file/@xml:id,
        'id' : ( $file/@xml:id => fn:string() ),
        'nbMeetings' : fn:count($file/meetings/meeting)
      }
    }
  return map{
    'meta': $meta,
    'content': $content
  }
};

(:~
 : Resource function for a file
 : @param $id file id
 : @return a json representation of a file
 :)
 declare
   %rest:path("/cbc/files/{$id}")
   %rest:produces("application/json")
   %output:media-type("application/json")
   %output:method("json")
 function getFilesById($id as xs:string) {
   let $data := db:get('cbc')/conbavil/files/file[@xml:id = $id]
   let $meta := map {
     'title': "Registre " || $id,
     'idno' : $G:domain || "/cbc/files/" || $id,
     'id' : $id
     }
   let $content :=
     map {
       'title' : fn:normalize-space($data/title), (: @todo deal with mix content :)
       'idno' : $G:domain || "/cbc/files/" || $data/@xml:id,
       'id' : $id,
       'nbMeetings' : fn:count($data/meetings/meeting),
       'nbDeliberations' : fn:count($data/meetings/meeting/deliberations/deliberation)
     }
   return map{
     'meta': $meta,
     'content': $content
     }
 };

(:~
 : Resource function for meetings
 : @param $start the item position to start from
 : @param $count the number of item to return
 : @return a json collection of reports
 :)
declare
  %rest:path("/cbc/meetings")
  %rest:produces("application/json")
  %output:media-type("application/json")
  %output:method("json")
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getMeetings($start, $count) {
  let $data := db:get('cbc')/conbavil/files/file/meetings/meeting
  let $meta := map {
    'title' : "Liste des séances",
    'idno' : $G:domain || "/cbc/meetings",
    'id' : 'meetings',
    'start' : $start,
    'count' : $count,
    'quantity' : fn:count($data)
  }
  let $content :=  array {
    for $meeting in fn:subsequence($data, $start, $count)
    return cbc.models:meetingToMap($meeting)
    }
  return map{
    "meta": $meta,
    "content": $content
  }
};

(:~
 : Resource function for a meeting
 : @param $id meeting id
 : @return a json meeting representation
 :)
declare
  %rest:path("/cbc/meetings/{$id}")
  %rest:produces("application/json")
  %output:media-type("application/json")
  %output:method("json")
function getMeetingById($id) {
  let $data := db:get('cbc')/conbavil/files/file/meetings/meeting[@xml:id = $id]
  let $meta := map {
    'title' : fn:normalize-space($data/title),
    'idno' : $G:domain || "/cbc/meetings/" || $id,
    'id' : $id,
    'nbDeliberations' : fn:count($data/deliberations/deliberation)
  }
  let $content := cbc.models:meetingToMap($data)
  return map {
    'meta' : $meta,
    'content' : $content
  }
};

(:~
 : Resource function for the deliberations
 : @param $start the item position to start from
 : @param $count the number of item to return
 : @return a json collection of deliberations
 :)
declare
  %rest:path("/cbc/deliberations")
  %rest:produces("application/json")
  %output:media-type("application/json")
  %output:method("json")
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getDeliberations($start, $count) {
  let $deliberations := db:get("cbc")/conbavil/files/file/meetings/meeting/deliberations/deliberation
  let $meta := map {
    'title' : "Liste des délibérations",
    'idno' : $G:domain || "/cbc/deliberations",
    'id' : 'deliberations',
    'start' : $start,
    'count' : $count,
    'quantity' : fn:count($deliberations)
  }
  let $content := array {
    for $deliberation in fn:subsequence($deliberations, $start, $count)
    return cbc.models:deliberationToMap($deliberation)
  }
  return map{
    "meta": $meta,
    "content": $content
  }
};

(:~
 : Resource function for deliberation
 : @param $id deliberation id
 : @return a json representation of a deliberation
 :)
declare
  %rest:path("/cbc/deliberations/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getDeliberationById($id) {
  let $data := db:get("cbc")//deliberation[@xml:id = $id]
  let $meta := map {
    'title' : "Délibération " || "@todo",
    'idno' : $G:domain || "/cbc/deliberations/" || $id,
    'id' : $id
  }
  let $content := cbc.models:deliberationToMap($data)
  return map {
    'meta' : $meta,
    'content' : $content
  }
};

(:~
 : Resource function for searching deliberations
 : based on parms provided on post request.
 : @return an json collection of deliberations
 :)

(:~
 : Resource function for types
 : @return a json collection of types
 :)
declare
  %rest:path("/cbc/types")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getTypes() {
  let $types := db:get("cbc")/conbavil/files/file/meetings/meeting/deliberations/deliberation/categories/category[@type="buildingType"][.!=""]
  let $meta := map {
    'title' : "Liste des types",
    'idno' : $G:domain || "/cbc/types/",
    'id' : 'types',
    'quantity' : fn:count($types)
  }
  let $content := array{
     $types
         => fn:distinct-values()
         => fn:sort()
  }
  return map {
    'meta' : $meta,
    'content' : $content
  }
};

(: @todo add types by id :)

(:~
 : Resource function for categories
 : @return a json collection of categories
 :)
declare
  %rest:path("/cbc/categories")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getCategories() {
  let $categories := db:get("cbc")/conbavil/files/file/meetings/meeting/deliberations/deliberation/categories/category[@type="projectGenre"][.!=""]
  let $meta := {
    'title' : "Liste des catégories",
    'idno' : $G:domain || "/cbc/categories/",
    'id' : "categories",
    'quantity' : fn:count($categories)
  }
  let $content := array {
    $categories
          => fn:distinct-values()
          => fn:sort()
  }
  return map {
    'meta' : $meta,
    'content' : $content
  }
};

(: @todo add category by id :)

(:~
 : Resource function for affairs
 : @param $start the item position to start from
 : @param $count the number of item to return
 : @return an json collection of deliberations
 :)
declare
  %rest:path("/cbc/affairs")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getAffairs($start, $count) {
  let $affairs := db:get("cbc")/conbavil/affairs/affair
  let $meta := map {
    'title' : "Liste des affaires",
    'idno' : $G:domain || "/cbc/affairs/",
    'id' : 'affairs',
    'start' : $start,
    'count' : $count,
    'quantity' : fn:count($affairs)
  }
  let $content := array{
    for $affair in fn:subsequence($affairs, $start, $count)
    return cbc.models:affairToMap($affair)
  }
  return map{
    "meta": $meta,
    "content": $content
  }
};

(:~
 : Resource fonction for an affair
 : @id the affair id
 : @return a json representation of an affair
 : @todo
 :)
declare
  %rest:path("/cbc/affairs/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getAffairById($id) {
  let $affair := db:get("cbc")/conbavil/affairs/affair[@xml:id = $id]
  return cbc.models:affairToMap($affair)
};

(:~
 : This resource function return all affaires linked to deliberations passed as params
 : @todo change path
 :)
declare
  %rest:path("/cbc/affairs/fromDeliberations")
  %rest:POST("{$content}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function affairesFromDeliberations($content) {
  let $deliberationIds := json:parse($content, map {'format': 'xquery'})("body")

  let $result :=
    for $affair in db:get('cbc')/conbavil/affairs/affair
    where
      array{
        for $i in $affair/deliberations/node()/text()
        return $i => fn:normalize-space()
      } = $deliberationIds
    return $affair

  return array{
    for $affair in $result
    return cbc.models:affairToMap($affair)
  }
};

(:~
 : This resource function post a new affair
 : @todo add id
 :)
declare
  %rest:path("/cbc/affairs/post")
  %rest:POST("{$content}")
  %rest:produces('application/json')
  %output:media-type('text/plain; charset=utf-8')
  %output:method('json')
  %updating
function postAffair($content) {
  let $body := json:parse($content, map {'format': 'xquery'})
  let $data := $body('affaire')
  let $type := $body('type')

  let $affairs := db:get('cbc')/conbavil/affairs

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
        replace node db:get('cbc')//affair[@xml:id = $affairId] with $affair,
        for $i in (1 to array:size($data('deliberations')))
        return replace value of node db:get('cbc')//deliberation[@xml:id = $data('deliberations')($i)('id')]/affairId with $affairId,
        update:output(cbc.models:httpResponse(200, 'La ressource bien été modifiée.'))
      )
    case "creation" 
      return (
        insert node $affair into $affairs,
        for $i in (1 to array:size($data('deliberations')))
        return replace value of node db:get('cbc')//deliberation[@xml:id = $data('deliberations')($i)('id')]/affairId with $affairId,
        update:output(cbc.models:httpResponse(200, 'La ressource bien été créée.'))
      )
    default 
      return update:output(cbc.models:httpResponse(500, "Un problème est survenu, la ressource n'a pas pu être créée/modifiée."))
};

(:~
 : This resource function post a new affair
 `: @todo add id
 :)
declare
  %rest:path("/cbc/deliberations/post")
  %rest:POST("{$content}")
  %rest:produces('application/json')
  %output:media-type('application/xml')
  %output:method('json')
  %updating
function postDeliberation($content) {
  let $body := json:parse($content, map {'format': 'xquery'})
  let $data := $body('deliberation')
  let $type := $body('type')

  let $deliberations := db:get('cbc')//deliberations

  let $deliberationId := 
    if ($type = 'modification') then $data('id')
    else fn:generate-id($deliberations)

  let $deliberation := (
    <deliberation xml:id="{$deliberationId}">
      <title>{$data('title')}</title>
      <altTitle>{$data('altTitle')}</altTitle>
      <meetingId>{$data('meetingId')}</meetingId>
      <affairId>{$data('affairId')}</affairId>
      <cote>{$data('cote')}</cote>
      <report><author>{ $data('report') }</author></report>
      <recommandation>{$data('recommandation')}</recommandation>
      <advice>{$data('advice')}</advice>
      <localisation>
        <commune>{$data('localisation')('commune')}</commune>
        <communeAncien>{$data('localisation')('communeAncien')}</communeAncien>
        <departement>{$data('localisation')('departement')}</departement>
        <departementDecimal>{$data('localisation')('departementDecimal')}</departementDecimal>
        <region>{$data('localisation')('region')}</region>
      </localisation>
      
      <categories>
      {
        for $i in (1 to array:size($data('buildingTypes')))
        return <category type="buildingType">{ $data('buildingTypes')($i) }</category>,
        
        for $i in (1 to array:size($data('buildingCategories')))
        return <category type="buildingCategories">{ $data('buildingCategories')($i) }</category>,
        
        for $i in (1 to array:size($data('administrativeObjects')))
        return <category type="administrativeObject">{ $data('administrativeObjects')($i) }</category>
      }
      </categories>
      <meta>
      {
        for $i in (1 to array:size($data('meta')))
        return <change type="{ $data('meta')($i)('type') }" who="{ $data('meta')($i)('who') }" when="{ $data('meta')($i)('when') }" />
      }
      </meta>
    </deliberation>
  )

  return 
  switch ($type) 
    case "modification" 
      return (
        replace node db:get('cbc')//deliberation[@xml:id = $deliberationId] with $deliberation,
        update:output(cbc.models:httpResponse(200, 'La ressource bien été modifiée.'))
      )
    case "creation" 
      return (
        insert node $deliberation into $deliberations,
        update:output(cbc.models:httpResponse(200, 'La ressource bien été créée.'))
      )
    default 
      return update:output(cbc.models:httpResponse(500, "Un problème est survenu, la ressource n'a pas pu être créée/modifiée."))
  
};

(:~
 : Resource function of the edifices
 : @param $start the item position to start from
 : @param $count the number of item to return
 : @return a json collection of edifices
 :)
declare
  %rest:path("/cbc/edifices")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getEdifices($start, $count) {

};

(:~
 : Resource function to an edifice
 : @param $id the edifice id
 : @return a json representation of the edifice
 :)
declare
  %rest:path("/cbc/edifices/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getEdificeById($id) {
  let $data := db:get('cbc')/conbavil/edifices/edifice[@xml:id = $id]
  let $meta := map {
    'title' : fn:normalize-space($data/title),
    'idno' : $G:domain || "/cbc/edifices/" || $id,
    'id' : $id,
    'nbDeliberations' : fn:count($data/deliberations/deliberation)
  }
  let $content := "cbc.models:edificesToMap($data)"
  return map {
    'meta' : $meta,
    'content' : $content
  }
};

(:~
 : Resource function for a prosopographical content
 : @param $start the item position to start from
 : @param $count the number of item to return
 : @return a json collection of persons
 :)
declare
  %rest:path("/cbc/persons")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
  %rest:query-param("start", "{$start}", 1)
  %rest:query-param("count", "{$count}", 20)
function getPersons($start, $count) {
  ''
};

(:~
 : Resource function for a person
 : $id the person id
 : @return a json representation of a person
 :)
declare
  %rest:path("/cbc/persons/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getPersons($id) {
  let $data := ''
  let $meta := ''
  let $content := ''
  return map {
      'meta' : $meta,
      'content' : $content
    }
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
    'commune': array { for $x in db:get('cbcFacets')//commune/@text return $x => fn:normalize-space()},
    'region': array { for $x in db:get('cbcFacets')//region/@text return $x => fn:normalize-space()},
    'departement': array { for $x in db:get('cbcFacets')//departement/@text return $x => fn:normalize-space()},
    'departementAncien': array { for $x in db:get('cbcFacets')//departementAncien/@text return $x => fn:normalize-space()},
    'projectGenre': array{ for $x in db:get('cbcFacets')//projectGenre/@text return $x => fn:normalize-space()},
    'buildingType': array{ for $x in db:get('cbcFacets')//buildingType/label return $x => fn:normalize-space()},
    'administrativeObject': array{ for $x in db:get('cbcFacets')//administrativeObject/@text return $x => fn:normalize-space()},
    'participant': array{ for $x in db:get('cbcFacets')//participant/@persName return $x => fn:normalize-space()}
  }
};

(:~
 : This resource function is a search
 : @param $content string content
 : @return cases and affairs
 : @todo output to revise
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
  let $facets := $body('facets')

  let $elements := db:get('cbcFt')//*[fn:name() = $element][
    text() contains text {for $t in $terms return $t} all words
  ]
  (:~ let $dbFacets:= db:get('cbcFacets')
  let $faceted := array {
    for $f in $facets
      for $val in $facets($f)
        for $e in $dbFacets/*[fn:name() = $f]
  } ~:)
  let $meta := map {
    'start' : xs:integer($body('meta')('start')),
    'count' : xs:integer($body('meta')('count')),
    'quantity' : fn:count($elements)
  }
  let $results := switch ($element)
    case 'deliberation'
      return array {
        for $d in fn:subsequence($elements, $meta('start'), $meta('count'))
        return cbc.models:deliberationToMap(
          cbc.models:getDeliberation($d/@xml:id => fn:normalize-space(), $d/@meetingId => fn:normalize-space())
        )
      }
    case 'affair'
      return array{
        for $d in fn:subsequence($elements, $meta('start'), $meta('count'))
        return cbc.models:affairToMap(
          cbc.models:getAffair($d/@xml:id => fn:normalize-space())
        )
      }
    default return map{}

  return map{
    'meta': $meta,
    'content': $results
  }
};