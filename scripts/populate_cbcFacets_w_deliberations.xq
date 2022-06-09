declare default element namespace "http://conbavil.fr/namespace";

for $f in db:open('cbcFacets')//commune
  let $deliberations := 
    <deliberations>{ 
      for $x in db:open('cbc')//deliberation 
      where fn:normalize-space($x/localisation/commune) = $f => fn:normalize-space()
      return <deliberation xml:id="{ $x/@xml:id => fn:normalize-space() }" />
    }</deliberations>
    
  let $affairs := 
    <affairs>{ 
      for $x in db:open('cbc')//affair 
      where fn:normalize-space($x/localisation/commune) = $f => fn:normalize-space()
      return <affair xml:id="{ $x/@xml:id => fn:normalize-space() }" />
    }</affairs>
  
  let $meetings := 
    <meetings>{ 
      for $x in db:open('cbc')//meeting 
      where fn:normalize-space($x/localisation/commune) = $f => fn:normalize-space()
      return <meeting xml:id="{ $x/@xml:id => fn:normalize-space() }" />
    }</meetings>
    
  return (
    insert node $deliberations into $f/deliberations,
    insert node $affairs into $f/affairs,
    insert node $meetings into $f/meetings
  )
  
    
    
    
 