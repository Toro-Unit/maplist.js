// Generated by CoffeeScript 1.5.0
(function() {
  var __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  (function($) {
    var MapList, log;
    log = _.bind(console.log, console);
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
        this["default"] = __bind(this["default"], this);
        var _this = this;
        this.options = _.extend(_(this).result('default'), options);
        this.makeMap();
        this.entries = this.getEntries();
        this.entries.then(function(data) {
          return log(data);
        });
      }

      MapList.prototype.makeMap = function() {
        var canvas, mapOptions;
        mapOptions = _(this.options).clone();
        canvas = $(this.options.mapSelector).get(0);
        return this.map = new google.maps.Map(canvas, mapOptions);
      };

      MapList.prototype.getEntries = function() {
        var data, dfd,
          _this = this;
        dfd = new $.Deferred;
        data = this.options.data;
        if (_(data).isArray()) {
          dfd.resolve(data);
        } else if (_(data).isString()) {
          $.ajax({
            url: data
          }).done(function(data) {
            return dfd.resolve(_this.options.parse(data));
          }).fail(function() {
            return dfd.reject();
          });
        } else {
          dfd.reject();
        }
        return dfd.promise();
      };

      MapList.prototype.parse = function(data) {
        return data;
      };

      return MapList;

    })();
    return window.MapList = MapList;
  })(jQuery);

}).call(this);
