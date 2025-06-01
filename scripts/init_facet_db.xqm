declare default element namespace "http://conbavil.fr/namespace";

let $db := db:get('cbc')

let $communes := 
<communes>{
  for $group in $db/conbavil/files/file/meetings/meeting/deliberations/deliberation
  let $commune := $group/localisation/commune[.!=@type]
  group by $commune
  return 
  <commune text="{$commune => fn:normalize-space()}">
    <deliberations>{
      for $d in $group
      return <deliberation xml:id="{$d/@xml:id}"></deliberation>
    }
    </deliberations>
  </commune>
}</communes>

let $departements := 
<departements>{
  for $group in $db/conbavil/files/file/meetings/meeting/deliberations/deliberation
  let $departement := $group/localisation/departement[fn:not(@type)]
  group by $departement
  return 
  <departement text="{$departement => fn:normalize-space()}">
    <deliberations>{
      for $d in $group
      return <deliberation xml:id="{$d/@xml:id}"></deliberation>
    }
    </deliberations>
  </departement>
}</departements>

let $regions := 
<regions>{
  for $group in $db/conbavil/files/file/meetings/meeting/deliberations/deliberation
  let $region := $group/localisation/region
  group by $region
  return 
  <region text="{$region => fn:normalize-space()}">
    <deliberations>{
      for $d in $group
      return <deliberation xml:id="{$d/@xml:id}"></deliberation>
    }
    </deliberations>
  </region>
}</regions>

let $bts := fn:distinct-values($db//category[@type = "buildingType"])

let $buildingTypes := 
<buildingTypes>{
  for $c in $bts
  return 
    <buildingType text="{$c => fn:normalize-space()}">
      <deliberations>{
        for $d in $db//deliberation
        where fn:contains(fn:serialize($d//categories), fn:normalize-space($c))
        return <deliberation xml:id="{$d/@xml:id}" />
      }</deliberations>
    </buildingType>
}</buildingTypes>


let $pgs := fn:distinct-values($db//category[@type = "projectGenre"])
let $projectGenres := 
<projectGenres>{
  for $c in $pgs
  return 
    <projectGenre text="{$c => fn:normalize-space()}">
      <deliberations>{
        for $d in $db//deliberation
        where fn:contains(fn:serialize($d//categories), fn:normalize-space($c))
        return <deliberation xml:id="{$d/@xml:id}" />
      }</deliberations>
    </projectGenre>
}</projectGenres>


let $aos := fn:distinct-values($db//category[@type = "administrativeObject"])
let $administrativeObjects := 
<administrativeObjects>{
  for $c in $pgs
  return 
    <administrativeObject text="{$c => fn:normalize-space()}">
      <deliberations>{
        for $d in $db//deliberation
        where fn:contains(fn:serialize($d//categories), fn:normalize-space($c))
        return <deliberation xml:id="{$d/@xml:id}" />
      }</deliberations>
    </administrativeObject>
}</administrativeObjects>

let $facets:= 
<facets>
  {$communes}
  {$regions}
  {$departements}
  {$buildingTypes}
  {$projectGenres}
  {$administrativeObjects}
</facets>
  
(:return db:create('cbcFacets', ($facets), ('facets')):)

return $facets