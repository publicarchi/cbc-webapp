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
  %rest:query-param("count", "{$count}", 10)
  %rest:query-param("nb", "{$nb}", 10)
function getMeetings($dpt as xs:string?, $start, $count, $nb) {
  let $queryParams := map {}
  let $data := db:open("cbc")/conbavil/files/file/meetings
  let $outputParams := map {}
  return array{
    for $meeting in fn:subsequence($data/meeting, 1, $nb)
    (: where 
      if ($dpt)
      then $meeting satisfies deliberations/deliberation/localisation/departement[@type="decimal"][fn:contains(., $dpt)]]
      else fn:true() 
    :)
    return map {
      "title" : $meeting/title => fn:normalize-space(), (: @todo deal with mix content:)
      "date" : $meeting/date => fn:normalize-space(),
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

(:~
 : This resource function lists all the reports
 : @return an ordered list of report in xml
 :)
declare
  %rest:path("/cbc/deliberations/{$id}")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getDeliberationById($id) {
  let $data := db:open("cbc")//deliberation[@xml:id = $id]
  return map{
    "id" : $data/@xml:id => fn:normalize-space(),
    "title" : $data/title => fn:normalize-space(),
    "item" : $data/item => fn:normalize-space(),
    "pages" : $data/pages => fn:normalize-space(),
    "localisation" : map {
      "commune" : $data/localisation/commune => fn:normalize-space(),
      "depatement" : $data/localisation/departement[@type="decimal"] => fn:normalize-space()
    },
    "recommendation" : fn:normalize-space($data/recommendation) => fn:normalize-space()
  }
};