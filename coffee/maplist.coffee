###
MapList JavaScript Library v1.0.0
http://github.com/jimon93/maplist.js

Require Library
  jquery.js
  jquery.tmpl.js
  underscore.js

MIT License
###
do ($=jQuery,global=this)->
  log = _.bind( console.log, console )
  class Facade
    default: => {
      # 緯度
      lat                    : 35
      # 経度
      lng                    : 135
      # 緯度経度
      # 上の属性より優先される
      center                 : null #new google.maps.LatLng( 35, 135 )
      # デフォルトのZoom
      zoom                   : 4
      # デフォルトのマップタイプ
      mapTypeId              : google.maps.MapTypeId.ROADMAP
      # entry data
      data                   : []
      # 地図を表示するDOM要素のセレクター
      mapSelector            : '#map_canvas'
      # リストを表示するDOM要素のセレクター
      listSelector           : '#list'
      # リストを構築する為のテンプレート
      listTemplate           : null
      # InfoWindowを構築する為のテンプレート
      infoTemplate           : null
      # リストからマーカーを開くDOM要素のセレクター
      listToMarkerSelector   : '.open-info'
      # genreの別名
      genreAlias             : 'genre'
      # genreを保持するDOMのテンプレート
      genreContainerSelector : '#genre'
      genreSelector          : 'a'
      genreDataName          : "target-genre"
      # デフォルトで表示するgenre
      firstGenre             : '__all__'
      # 以下コールバック
      infoOpened             : null
      beforeBuild            : null
      afterBuild             : null
      beforeClear            : null
      afterClear             : null
      # 構築後,表示しているマーカーが全て映るように地図を動かす
      doFit                  : true
      # FitするときZoomも変更する
      fitZoomReset           : false
      # infoを開いた時, 地図の全てが映るように動かす
      toMapScroll            : true
      # 使用するテンプレートエンジン
      # デフォルトでは_.templateを
      # jquery.tmplがある場合,そちらを利用する
      templateEngine         : $.tmpl || _.template
    }
    # 表示中のentryを保持する
    usingEntries : []

    constructor:(options)->
      _.bindAll(@)
      @options = @_makeOptions(options)
      @entries = new Entries(_.clone @options)
      @maplist = new MapList(_.clone @options)
      @entries.then =>
        @rebuild( @options.firstGenre )

      # event
      $(@options.genreContainerSelector).on( "click", @options.genreSelector, @_selectGenre )

    # 地図とリストを構築する
    build:(genreId)->
      @options.beforeBuild?(genreId)
      @entries.filterdThen genreId, (@usingEntries)=>
        @maplist.build(@usingEntries)
        @options.afterBuild?(genreId, @usingEntries)

    # 地図とリストを初期化する
    clear:->
      @options.beforeClear?()
      @maplist.clear(@usingEntries)
      @options.afterClear?()

    # 地図とリストを初期化して，構築する
    rebuild:(genreId)->
      @clear()
      @build(genreId)

    # map objectを取得
    getMap:->
      return @maplist.map

  # private
  #--------------------------------------------------
    # ジャンルをクリックされた時のためのコールバック関数
    _selectGenre:(e, genreId)->
      unless genreId?
        $target = $(e.currentTarget)
        genreId = $target.data( @options.genreDataName )
      @rebuild genreId
      return false

    # オプションを作ります
    _makeOptions:(options)->
      options = _.extend( {}, _(@).result('default'), options)
      unless options.center?
        options.center = new google.maps.LatLng( options.lat, options.lng )
      return options

  # Entryのコレクション
  class Entries
    constructor:(@options)->
      _.bindAll(@)
      parser = new Parser(_.clone @options)
      @options = _.extend( {parse:parser.parse}, @options)
      @entries = @_makeEntries()

    then:(done,fail)->
      @entries.then(done,fail)

    # entryを検索した上で then
    filterdThen:(genreId,done,fail)->
      @entries.then(
        (entries)=>done(@_filterdEntries genreId, entries)
        (e)=>fail(e)
      )

    # private
    #--------------------------------------------------
    _makeEntries:->
      dfd = new $.Deferred
      data = @options.data
      if _.isArray(data)
        dfd.resolve( data )
      else if _.isString(data)
        $.ajax({url:data}).done( (data)=>
          dfd.resolve( @options.parse( data ) )
        ).fail(=>
          dfd.reject()
        )
      else
        dfd.reject()
      dfd.promise()

    _filterdEntries:(genreId, entries)->
      if genreId == "__all__"
        entries
      else
        alias = @options.genreAlias
        (entry for entry in entries when entry[alias] is genreId)

  class Parser
    constructor:(@options)->
      _.bindAll(@)

    # 引数のデータを適した形のデータに変換して返す
    parse:(data)->
      if $.isXMLDoc(data)
        @_parseForXML( data )
      else if _.isObject(data)
        @_parseForObject( data )
      else
        data

    _parseForXML:(data)->
      $root = $(">*:eq(0)", data)
      alias = @options.genreAlias
      $.map $root.find(">#{alias}"), (genre)=>
        $genre = $(genre)
        genre = { "icon" : $genre.attr("icon") }
        genre["#{alias}"] = $genre.attr("id")
        genre["#{alias}Name"] = $genre.attr("name")
        $.map $genre.find(">place"), (place)=>
          $place = $(place)
          lat = $place.attr('latitude')
          lng = $place.attr('longitude')
          return null unless lat and lng
          res = {} # reduceでやりたい
          $place.children().each (idx,elem)=>
            res[elem.nodeName] = $(elem).text()
          position = { lat: $place.attr('latitude'), lng: $place.attr('longitude') }
          return _.extend( {}, genre, position, res )

    _parseForObject:(data)->
      data

  class MapList
    constructor:(@options)->
      _.bindAll(@)
      mapOptions = _(@options).clone()
      canvas = $(@options.mapSelector).get(0)
      @map = new google.maps.Map( canvas, mapOptions )

    # 構築
    # マーカー，インフォ，リストを構築
    build:(entries)->
      bounds = new google.maps.LatLngBounds if @options.doFit
      for entry in entries
        [info,marker,listElem] = @getEntryData(entry)
        marker.setMap(@map)
        bounds.extend( marker.getPosition() ) if @options.doFit
        listElem?.appendTo $(@options.listSelector)
      if @options.doFit
        unless @options.fitZoomReset
          @map.fitBounds( bounds )
        else
          @map.setCenter( bounds.getCenter() )
          @map.setZoom( @options.zoom )

    # マーカー, インフォ, リストを消す
    clear:(entries)->
      for entry in entries
        [info,marker,listElem] = @getEntryData(entry)
        @openInfo.close() if @openInfo?
        marker.setMap(null)
        listElem?.detach()

    # entryからinfo,marker,listを作成して返す
    getEntryData:(entry)->
      info     = entry.__info     ? entry.__info     = @makeInfo( entry )
      marker   = entry.__marker   ? entry.__marker   = @makeMarker( entry, info )
      listElem = entry.__listElem ? entry.__listElem = @makeListElem( entry, marker, info )
      return [info,marker,listElem]

    makeInfo:(entry)->
      content = @makeHTML @options.infoTemplate, entry
      if content?
        content = $( content ).html()
        info = new google.maps.InfoWindow {content}
        google.maps.event.addListener info, 'closeclick', =>
          @openInfo = null
        return info
      else
        return null

    makeMarker:(entry,info)->
      position = new google.maps.LatLng( entry.lat, entry.lng )
      marker = new google.maps.Marker { position, icon: entry.icon, shadow: entry.shadow }
      google.maps.event.addListener( marker, 'click', @openInfoFunc(marker,info) ) if info
      return marker

    makeListElem:(entry,marker,info)->
      content = @makeHTML @options.listTemplate, entry
      if content?
        $content = $(content)
        $content.data( @options.genreAlias, entry[@options.genreAlias] )
        if @options.listToMarkerSelector?
          $content.on( "click", @options.listToMarkerSelector, @openInfoFunc(marker,info) )
        return $content
      else
        return null

    # infoを開く関数を返す関数
    openInfoFunc:(marker,info)->
      (e)=>
        @openInfo.close() if @openInfo?
        info.open(@map, marker)
        @openInfo = info
        @toMapScroll() if @options.toMapScroll
        @options.infoOpened?(marker,info)

    makeHTML:(template, entry)->
      return null unless template?
      res = @options.templateEngine( template, entry )
      return $(res)

    # map上部へスクロール
    toMapScroll:->
      top = $(@options.mapSelector).offset().top
      $('html,body').animate({ scrollTop: top }, 'fast')

  global.MapList = Facade
