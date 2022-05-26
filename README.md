# cbc-webapp

Webapp XQuery sur le conseil des bâtiments civils.

- BaseX >9

```bash
ln -s /Users/path-to/cbc-webapp /path-to/basex/webapp/cbc
```

CORS issue
https://stackoverflow.com/questions/42932689/basex-rest-api-set-custom-http-response-header

```xml
<web-app>
  <!-- add those before the closing web-app tag: -->
  <filter>
    <filter-name>cross-origin</filter-name>
    <filter-class>org.eclipse.jetty.servlets.CrossOriginFilter</filter-class>
  </filter>
  <filter-mapping>
    <filter-name>cross-origin</filter-name>
    <url-pattern>/*</url-pattern>
  </filter-mapping>
</web-app>
```

### Créer l’élément affairs

```xquery
  declare default element namespace "http://conbavil.fr/namespace" ;
  insert node <affairs/> into db:open("cbc")/conbavil
```

### Supprimer les tests d’affaires

```xquery
  declare default element namespace "http://conbavil.fr/namespace" ;
  delete node db:open("cbc")/conbavil/affairs/*
```

### Ajouter des titres alternatifs aux délibérations

```xquery
declare default element namespace "http://conbavil.fr/namespace" ;

let $deliberations := db:open('cbc')/conbavil/files/file/meetings/meeting/deliberations/deliberation

for $d in $deliberations

  let $genre := fn:string-join(
    (
    for $i in $d/categories/category[@type = 'projectGenre']
    return $i => normalize-space()
    ), '/'
  )

  let $building := fn:string-join(
  	(
    for $i in $d/categories/category[@type = 'buildingType']
    return $i => normalize-space()
    ), '/'
  )

  let $commune := fn:string-join(
  	(
    for $i in $d/localisation/commune
    return $i => normalize-space()
    ), '/'
  )

  let $commune := if ($commune = '[?]' or $commune = '') then
  	$d/localisation/region => fn:normalize-space() else $commune

  let $altTitle := <altTitle>{
  	fn:string-join(
    for $i in ($genre, $building, $commune)
    where $i => fn:normalize-space() != ''
    return $i,
    ' · '
  )}</altTitle>

  return insert node $altTitle as first into $d
```

### Ajouter id aux séances

```xquery
declare default element namespace "http://conbavil.fr/namespace";

for $m in db:open('cbc')/conbavil/files/file/meetings/meeting
let $c := (
	<meeting xml:id="{fn:generate-id($m)}">
    	{$m/*}
    </meeting>
)
return replace node $m with $c
```

### Ajouter les id des séances aux délibérations

```xquery
declare default element namespace "http://conbavil.fr/namespace";

for $d in db:open('cbc')/conbavil/files/file/meetings/meeting/deliberations/deliberation
return insert node (
	<meetingId>
		{$d/parent::deliberations/parent::meeting/@xml:id => fn:normalize-space()}
	</meetingId>
) into $d
```

### Ajouter affairId aux délibérations

```xquery
declare default element namespace "http://conbavil.fr/namespace";

for $d in db:open('cbc')/conbavil//deliberation
return insert node <affairId></affairId> into $d
```

### Créer un index pour les déliberations, affaires et séances

```xquery
declare default element namespace "http://conbavil.fr/namespace";

let $affairs :=
    <affairs>{
      for $affair in db:open('cbc')/conbavil//affair
      return <affair xml:id="{$affair/@xml:id => fn:normalize-space()}">{fn:normalize-space($affair)}</affair>
    }</affairs>
  let $deliberations :=
    <deliberations>{
      for $deliberation in db:open('cbc')/conbavil//deliberation
      return
      <deliberation
        xml:id="{$deliberation/@xml:id => fn:normalize-space()}"
        meetingId="{$deliberation/meetingId => fn:normalize-space()}"
        affairId="{$deliberation/affairId => fn:normalize-space()}"
      >{fn:normalize-space($deliberation)}
      </deliberation>
    }</deliberations>
  let $meetings :=
    <meetings>
    {
      for $meeting in db:open('cbc')/conbavil//meeting
      return <meeting xml:id="{$meeting/@xml:id => fn:normalize-space()}">{fn:normalize-space($meeting)}</meeting>
    }
    </meetings>
  return db:create(
    'cbcFt',
    ($affairs, $deliberations, $meetings),
    ('affairs', 'deliberations', 'meetings'),
    map {
      'ftindex': fn:true(),
      'stemming': fn:true(),
      'casesens': fn:true(),
      'diacritics': fn:true(),
      'language': 'fr',
      'updindex': fn:true(),
      'autooptimize': fn:true(),
      'maxlen': 96,
      'maxcats': 100,
      'splitsize': 0,
      'chop': fn:false(),
      'textindex': fn:true(),
      'attrindex': fn:true(),
      'tokenindex': fn:true(),
      'xinclude': fn:true()
      }
    ),
  update:output(httpResponse(200, "L’index plein-texte des affaires a bien été créé."))
```
