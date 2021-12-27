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

declare namespace cbc = "http://conbavil.fr/namespace" ;
declare default element namespace "http://conbavil.fr/namespace" ;
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
declare function sequence2ArrayInMap($queryParams, $map as map(*)*, $outputParams) as map(*) {
for $content in $map
return
  map:merge((
    map:for-each(
      $map,
      function($a, $b) {
        map:entry(
          $a ,
          if (fn:count($b) > 1)
          then array{ $b } (: @quest call dispatch ? :)
          else $b
        )
      }
    )
  ))
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

declare function cbc.mappings:entry($value, $options) {
 ''
};

declare function cbc.mappings:toto($value, $options) {
 ''
};


(:~
 : this function dispatches the treatment of the XML document
 :)
declare
  %output:indent('no')
function dispatch($node as node()*, $options as map(*)) as item()* {
  typeswitch($node)
    case text() return $node[fn:normalize-space(.)!='']
    case element(cbc:hi) return $node ! hi(., $options)
    case element(cbc:emph) return $node ! emph(., $options)
    default return $node ! passthru(., $options)
};

(:~
 : This function pass through child nodes (xsl:apply-templates)
 :)
declare
  %output:indent('no')
function passthru($nodes as node(), $options as map(*)) as item()* {
  for $node in $nodes/node()
  return dispatch($node, $options)
};

(:~
 : ~:~:~:~:~:~:~:~:~
 : tei inline
 : ~:~:~:~:~:~:~:~:~
 :)
declare function hi($node as element(cbc:hi)+, $options as map(*)) {
  switch ($node)
  case ($node[@rend='italic' or @rend='it']) return <em>{ passthru($node, $options) }</em>
  case ($node[@rend='bold' or @rend='b']) return <strong>{ passthru($node, $options) }</strong>
  case ($node[@rend='superscript' or @rend='sup']) return <sup>{ passthru($node, $options) }</sup>
  case ($node[@rend='underscript' or @rend='sub']) return <sub>{ passthru($node, $options) }</sub>
  case ($node[@rend='underline' or @rend='u']) return <u>{ passthru($node, $options) }</u>
  case ($node[@rend='strikethrough']) return <del class="hi">{ passthru($node, $options) }</del>
  case ($node[@rend='caps' or @rend='uppercase']) return <span calss="uppercase">{ passthru($node, $options) }</span>
  case ($node[@rend='smallcaps' or @rend='sc']) return <span class="small-caps">{ passthru($node, $options) }</span>
  default return <span class="{$node/@rend}">{ passthru($node, $options) }</span>
};

declare function emph($node as element(cbc:emph), $options as map(*)) {
  <em class="emph">{ passthru($node, $options) }</em>
};
