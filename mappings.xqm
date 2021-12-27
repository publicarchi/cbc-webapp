xquery version "3.1" ;
module namespace cbc.mappings = "cbc.mappings" ;

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

import module namespace G = "cbc.globals" at "./globals.xqm" ;
import module namespace cbc.models = 'cbc.models' at './models.xqm' ;

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

declare namespace cbc = "cbc" ;
declare default element namespace "cbc" ;
declare default function namespace "cbc.mappings" ;

declare default collation "http://basex.org/collation?lang=fr" ;

(:~
 :
 :)

(:~
 : this function wrap the content in an HTML layout
 :
 : @param $queryParams the query params defined in restxq
 : @param $data the result of the query
 : @param $outputParams the serialization params
 : @return an updated HTML document and instantiate pattern
 : @todo treat in the same loop @* and text() ?
 @todo add handling of outputParams (for example {class} attribute or call to an xslt)
 :)
declare function jsoner($queryParams as map(*), $data as map(*), $outputParams as map(*)) {
  let $contents := map:get($data, 'content')
  let $meta := map:get($data, 'meta')
  return map{
    'meta' : sequence2ArrayInMap($queryParams, $meta, $outputParams),
    'content' : if (fn:count($contents) > 1) then array{
        for $content in $contents
        return sequence2ArrayInMap($queryParams, $content, $outputParams)
        }
        (:
        else sequence2ArrayInMap($queryParams, $contents, $outputParams)
        :)
        (: for debug :)
        else if (fn:count($contents) = 0)
          then 'vide'
          else sequence2ArrayInMap($queryParams, $contents, $outputParams)
    }
};

(:~
 : this function transforms a map into a map with arrays
 :
 : @param $map the map to convert
 : @return a map with array instead of sequences
 : @rmq deals only with right keys
 :)
declare function sequence2ArrayInMap($queryParams, $map as map(*), $outputParams) as map(*) {
  map:merge((
    map:for-each(
      $map,
      function($a, $b) {
        map:entry(
          $a ,
          if (fn:count($b) > 1)
          then array{ dispatch($b, $queryParams, $outputParams) }
          else dispatch($b, $queryParams, $outputParams)
        )
      }
    )
  ))
};

declare function dispatch($b as item()*, $queryParams, $outputParams) {
  typeswitch($b)
    case empty-sequence() return ()
    case map(*)+ return $b ! sequence2ArrayInMap($queryParams, ., $outputParams)
    case xs:string return $b
    case xs:string+ return $b
    (: case xs:anyAtomicType return fn:data($b)
    case xs:anyAtomicType+ return $b ! fn:data(.) :)
    case xs:integer return fn:data($b)
    case xs:double return fn:format-number($b, "0.00")
    case array(*) return array:for-each($b, function($i){
      dispatch($i, $queryParams, $outputParams)
    })
    case attribute() return fn:string($b)
    case text() return fn:string($b)
    default return render($queryParams, $outputParams, $b)/node()
      => fn:serialize(map {'method' : 'html'})
};

declare function recurse($queryParams, $map as map(*), $outputParams) {
  sequence2ArrayInMap($queryParams, $map, $outputParams)
};

(:~
 : this function dispatch the rendering based on $outpoutParams
 :
 : @param $value the content to render
 : @param $outputParams the serialization params
 : @return an html serialization
 :
 : @todo check the xslt with an xslt 1.0
 : @todo select the xquery transformation from xqm
 :)
declare function render($queryParams as map(*), $outputParams as map(*), $value as item()* ) as item()* {
  let $xquery := map:get($outputParams, 'xquery')
  let $xsl :=  map:get($outputParams, 'xsl')
  let $options := map{
    'lb' : map:get($outputParams, 'lb')
    }
  let $params := map:get($outputParams, 'params')
  return
    if ($xquery)
      then cbc.mappings:entry($value, $options)
    else if ($xsl)
      then for $node in $value
           return
               if (fn:empty($params) )
                 then xslt:transform($node, cbc.models:getXsltPath($queryParams, $xsl))
                 else xslt:transform($node, cbc.models:getXsltPath($queryParams, $xsl), $params)
      else $value
};