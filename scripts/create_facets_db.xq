declare default element namespace "http://conbavil.fr/namespace" ;
declare default function namespace "cbc.rest" ;

let $communes :=
  <communes>{
    for $c in fn:distinct-values(db:get('cbc')//commune)
    return <commune text="{$c => fn:normalize-space()}" />
  }</communes>
  
let $regions :=
  <regions>{
    for $c in fn:distinct-values(db:get('cbc')//region)
    return <region text="{$c => fn:normalize-space()}" />
  }</regions>
  
let $departements :=
  <departements>{
    for $c in fn:distinct-values(db:get('cbc')//departement[fn:not(@type)])
    return <departement text="{$c => fn:normalize-space()}" />
  }</departements>  
  
let $departementsAnciens :=
  <departementsAnciens>{
    for $c in fn:distinct-values(db:get('cbc')//departementAncien)
    return <departementAncien text="{$c => fn:normalize-space()}" />
  }</departementsAnciens> 

let $buildingTypes :=
  <buildingTypes>{
    for $c in fn:distinct-values(db:get('cbc')//category[@type = "buildingType"])
    return <buildingType text="{$c => fn:normalize-space()}" />
  }</buildingTypes> 
  
let $buildingCategories :=
  <buildingCategories>{
    for $c in fn:distinct-values(db:get('cbc')//category[@type = "buildingCategory"])
    return <buildingCategory text="{$c => fn:normalize-space()}" />
  }</buildingCategories>
  
let $projectGenres := 
   <projectGenres>{
    for $c in fn:distinct-values(db:get('cbc')//category[@type = "projectGenre"])
    return <projectGenre text="{$c => fn:normalize-space()}" />
  }</projectGenres>
  
let $administrativeObjects := 
   <administrativeObjects>{
    for $c in fn:distinct-values(db:get('cbc')//category[@type = "administrativeObject"])
    return <administrativeObject text="{$c => fn:normalize-space()}" />
  }</administrativeObjects>
  
let $participants :=
 <participants>{
    for $c in db:get('cbc')//persName
    return <participant persName="{$c => fn:normalize-space()}" />
  }</participants>
  
let $reports := 
   <reports>{
    for $c in fn:distinct-values(db:get('cbc')//report/author)
    return <report text="{$c => fn:normalize-space()}"/>
  }</reports>
  
let $facets := 
  <facets>
    {$communes}
    {$regions}
    {$departements}
    {$departementsAnciens}
    {$buildingTypes}
    {$buildingCategories}
    {$projectGenres}
    {$administrativeObjects}
    {$participants}
    {$reports}
  </facets>
  
return db:create('cbcFacets', ($facets), ('facets'))