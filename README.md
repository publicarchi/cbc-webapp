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
