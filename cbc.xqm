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
import module namespace cbc.models = 'models' at './models.xqm' ;
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

declare namespace cbc = "cbc" ;
declare default element namespace "cbc" ;
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
  web:redirect("/cbc/rapports/view")
};

(:~
 : This resource function lists all the reports
 : @return an ordered list of report in xml
 :)
declare
  %rest:path("/xpr/rapports")
  %rest:produces('application/xml')
  %output:method("xml")
function getReports() {
  db:open('cbc')/cbc/rapports
};

(:~
 : This resource function lists all the expertises
 : @return an ordered list of expertises in html
 :)
declare
  %rest:path("/xpr/rapports")
  %rest:produces('application/json')
  %output:media-type('application/json')
  %output:method('json')
function getReportsJson() {
  let $content := map {
    'title' : 'Liste des rapports',
    'data' : getReports()
  }
  let $outputParam := map {
    'layout' : "listReports.xml",
    'mapping' : cbc.mappings:listC2html(map:get($content, 'data'), map{})
  }
  return cbc.mappings:jsoner($queryParams, $result, $outputParams)
};