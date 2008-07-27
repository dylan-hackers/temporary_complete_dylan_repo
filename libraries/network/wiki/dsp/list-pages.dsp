<%dsp:taglib name="wiki"/><%dsp:include url="xhtml-start.dsp"/>
<head>
  <title>Dylan: Pages</title>
  <%dsp:include url="meta.dsp"/>
</head>
<body>
  <%dsp:include url="header.dsp"/>
  <div id="content">
    <%dsp:include url="navigation.dsp"/>
    <div id="body">               
      <h2>Pages</h2>
      <dsp:when test="query-tagged?">
        <ul class="cloud" id="query-tags">
          <wiki:list-query-tags>
            <li><wiki:show-tag/></li>
          </wiki:list-query-tags>
        </ul>
      </dsp:when>
      <form action="/pages">
        <ul class="striped big">
          <li class="page">
            <input type="text" name="query" value=""/>
            <input type="submit" name="go" value="Create"/>
          </li>
          <wiki:list-pages use-query-tags="true">
            <li class="page">
              <a href="<wiki:show-page-permanent-link/>"><wiki:show-page-title/></a>
            </li>
          </wiki:list-pages>
        </ul>
      </form>
    </div>
  </div>
  <%dsp:include url="footer.dsp"/>
</body>
</html>