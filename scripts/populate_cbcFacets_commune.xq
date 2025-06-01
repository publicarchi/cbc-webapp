declare default element namespace "http://conbavil.fr/namespace";
let $db := db:get('cbc')
for $f in $db//commune 
  let $deliberations := 
       <deliberations>{ 
          for $x in $db/conbavil/files/file/meetings/meeting/deliberations/deliberation 
          where fn:normalize-space($x/localisation/commune[.!=@type]) = $f
          return <deliberation xml:id="{ $x/@xml:id }" />
        }</deliberations>
    
   
  (:
  let $affairs := 
  (# db:copynode false #) {
    <affairs>{ 
      for $x in db:get('cbc')//affair 
      where fn:normalize-space($x/localisation/commune[.!=@type]) = $f => fn:normalize-space()
      return <affair xml:id="{ $x/@xml:id => fn:normalize-space() }" />
    }</affairs>
  }
  
  let $meetings := 
  (# db:copynode false #) {
      <meetings>{ 
        for $x in db:get('cbc')//meeting 
        where fn:normalize-space($x/localisation/commune[.!=@type]) = $f
        return <meeting xml:id="{ $x/@xml:id }" />
      }</meetings>
  }
  :)
   
  return (
    insert node $deliberations into $f/deliberations
  )
 
    
 