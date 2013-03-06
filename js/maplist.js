// Generated by CoffeeScript 1.5.0
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($) {
    var MapList;
    MapList = (function() {

      MapList.prototype["default"] = function() {
        return {
          center: new google.maps.LatLng(35, 135),
          zoom: 4,
          mapTypeId: google.maps.MapTypeId.ROADMAP,
          data: [],
          mapSelector: '#map_canvas',
          listSelector: '',
          listTemplate: '',
          infoTemplate: '',
          listToMarkerSelector: '',
          genreAlias: 'genre',
          genreContainerSelector: '',
          genreSelector: '',
          firstGenre: '__all__',
          parse: this.parse
        };
      };

      function MapList(options) {
        this["default"] = __bind(this["default"], this);        this.options = _.extend(_(this).result('default'), options);
        this.makeMap();
      }

      MapList.prototype.makeMap = function() {
        var canvas, mapOptions;
        mapOptions = _(this.options).clone();
        canvas = $(this.options.mapSelector).get(0);
        return this.map = new google.maps.Map(canvas, mapOptions);
      };

      MapList.prototype.parse = function() {};

      return MapList;

    })();
    return window.MapList = MapList;
  })(jQuery);

}).call(this);