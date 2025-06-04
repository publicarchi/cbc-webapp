xquery version "3.1" ;
module namespace cbc.models = "cbc.models" ;

(:~
 : This xquery module is an application for cbc
 :
 : @author emchateau
 : @since 2024-10
 : @version 0.3
 : @licence GNU http://www.gnu.org/licenses
 :
 :)

import module namespace G = "cbc.globals" at './globals.xqm' ;

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

declare namespace cbc = "http://public.archi/conbavil/namespace" ;
declare default element namespace "http://public.archi/conbavil/namespace" ;
declare default function namespace "cbc.models" ;

declare default collation "http://basex.org/collation?lang=fr" ;

(:~
 : this function return a mime-type for a specified file
 : @param  $name  file name
 : @return a mime type for the specified file
 :)
declare function mime-type($name as xs:string) as xs:string {
    fetch:content-type($name)
};

(:~
 : this function calls a wrapper
 : @param $content the content to serialize
 : @param $outputParams the output params
 : @return an updated document and instantiated pattern
 :)
declare function wrapper($content as map(*), $outputParams as map(*)) as node()* {
  let $layout := file:base-dir() || "files/" || map:get($outputParams, 'layout')
  let $wrap := fn:doc($layout)
  let $regex := '\{(.+?)\}'
  return
    $wrap/* update {
      for $node in .//*[fn:matches(text(), $regex)] | .//@*[fn:matches(., $regex)]
      let $key := fn:analyze-string($node, $regex)//fn:group/text()
      return switch ($key)
        case 'model' return replace node $node with getModels($content)
        case 'trigger' return replace node $node with getTriggers($content)
        case 'form' return replace node $node with getForms($content)
        case 'data' return replace node $node with $content?data
        case 'content' return replace node $node with $outputParams?mapping
        default return associate($content, $outputParams, $node)
      }
};

(:~
 : this function get the models
 : @param $content the content params
 : @return the default models or its instance version
 : @bug not generic enough
 : @todo add control on models and instances number
 :)
declare function getModels($content as map(*)){
  let $instances := map:get($content, 'instance')
  let $path := map:get($content, 'path')
  let $models := map:get($content, 'model')
  for $model at $i in $models return
    if ($instances[$i])
    then (
      copy $doc := fn:doc(file:base-dir() || "files/" || $model)
      modify replace value of node $doc/xf:model/xf:instance[@id=fn:substring-before($model, 'Model.xml')]/@src with '/cbc/' || $path || '/' || $instances[$i]
      return $doc
    )
    else
    fn:doc(file:base-dir() || "files/" || $model)
};

(:~
 : this function get the models
 : @param $content the content params
 : @return the default models or its instance version
 : @bug not generic enough
 :)
declare function getTriggers($content as map(*)){
  let $instance := map:get($content, 'instance')
  let $path := map:get($content, 'path')
  let $triggers := map:get($content, 'trigger')
  return if ($triggers) then fn:doc(file:base-dir() || "files/" || $triggers) else ()
};

(:~
 : this function get the forms
 : @param $content the content params
 : @return the default forms or its instance version
 : @bug not generic enough
 : @todo make loop if multiple forms
 :)
declare function getForms($content as map(*)){
  let $instance := map:get($content, 'instance')
  let $path := map:get($content, 'path')
  let $forms := map:get($content, 'form')
  return if ($forms) then fn:doc(file:base-dir() || "files/" || $forms) else ()
};

(:~
 : this function dispatch the content with the data
 : @param $content the content to serialize
 : @param $outputParams the serialization params
 : @return an updated node with the data
 : @bug the behavior is not complete
 :)
declare
  %updating
function associate($content as map(*), $outputParams as map(*), $node as node()) {
  let $regex := '\{(.+?)\}'
  let $keys := fn:analyze-string($node, $regex)//fn:group/text()
  let $values := map:get($content, $keys)
    return typeswitch ($values)
    case document-node() return replace node $node with $values
    case empty-sequence() return ()
    case text() return replace value of node $node with $values
    case xs:string return replace value of node $node with $values
    case xs:string+ return
      if ($node instance of attribute()) (: when key is an attribute value :)
      then
        replace node $node/parent::* with
          element {fn:name($node/parent::*)} {
          for $att in $node/parent::*/(@* except $node) return $att,
          attribute {fn:name($node)} {fn:string-join($values, ' ')},
          $node/parent::*/text()
          }
    else
      replace node $node with
      for $value in $values
      return element {fn:name($node)} {
        for $att in $node/@* return $att,
        $value
      }
    case xs:integer return replace value of node $node with xs:string($values)
    case element()+ return replace node $node with
      for $value in $values
      return element {fn:name($node)} {
        for $att in $node/@* return $att, "todo"
      }
    default return replace value of node $node with 'default'
};

declare function getXsltPath($queryParam, $xsl) {
  '@todo'
};

(:~
 : this function get metting pagination
 : @param $meeting the meeting id
 : @param $outputParams the serialization params
 : @return a amp with label and interval
 : @bug the behavior is not complete
 : @todo add explicit pagination to paginate IIIF
 :)
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

declare function extractProjectGenres($element as element()) as item()* {
  let $categories := $element//categories/category[@type="projectGenre"]
    => fn:distinct-values()
  return array { $categories }
};

declare function extractAdministrativeObjects($element as element()) as item()* {
  let $categories := $element//categories/category[@type="administrativeObject"]
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
   db:get('cbc')/conbavil/files/file/meetings
        /meeting[@xml:id = $meetingId]
        //deliberation[@xml:id = $id]
};

declare function getAffair($id as xs:string) as element() {
   db:get('cbc')/conbavil//affair[@xml:id = $id]
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
        "region" : $deliberation/localisation/region => fn:normalize-space()
      },
      "buildingTypes" : extractBuildingTypes($deliberation),
      "projectGenres" : extractProjectGenres($deliberation),
      "administrativeObjects": extractAdministrativeObjects($deliberation),
      "report" : $deliberation/report/author => fn:normalize-space(),
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
      let $d := db:get("cbc")/conbavil/files/file/meetings/meeting[@xml:id = $meetingId]/deliberations/deliberation[@xml:id = $id]
      return deliberationToMap($d)
    },
    'meta': metaToArray($affair)
  }
  return $result
};

(:
~:)
declare function meetingToMap($meeting as element(meeting)) as map(*) {
  map {
    "id": $meeting/@xml:id => fn:normalize-space(),
    "title" : $meeting/title => fn:normalize-space(), (: @todo deal with mix content:)
    "date" : $meeting/date/@when => fn:normalize-space(),
    "cote" : $meeting/parent::meetings/parent::file/idno => fn:normalize-space(),
    "coteDev" : $meeting/parent::meetings/parent::file/title => fn:normalize-space(),
    "pages" : getPages($meeting, map{}),
    "nb" : $meeting/deliberations/deliberation => fn:count(),
    "projectTypes" : array{ extractBuildingTypes($meeting) },
    "projectGenres" : array{ extractProjectGenres($meeting) },
    "deliberations" : array{
      for $deliberation in $meeting/deliberations/deliberation
      return deliberationToMap($deliberation)
    }
  }
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