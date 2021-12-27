xquery version "3.1" ;
module namespace G = "cbc.globals" ;

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

declare namespace file = "http://expath.org/ns/file" ;

declare variable $G:xsltFormsPath := "/cbc/files/xsltforms/xsltforms/xsltforms.xsl" ;
declare variable $G:home := file:base-dir() ;
declare variable $G:interface := fn:doc($G:home || "files/interface.xml") ;