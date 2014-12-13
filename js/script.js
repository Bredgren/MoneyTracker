// Generated by CoffeeScript 1.6.2
(function() {
  var Loader, Main, handleClientLoad, loadUrl, main,
    __bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  loadUrl = function(url, callback) {
    console.log("fetching", url);
    return $.getJSON(url, callback);
  };

  Loader = (function() {
    function Loader(callback) {
      this.callback = callback;
      this.loadedSheet = __bind(this.loadedSheet, this);
      this.loadingSheet = __bind(this.loadingSheet, this);
      this.updateProgress = __bind(this.updateProgress, this);
      this.sheetsLoading = [];
      this.sheetsLoaded = [];
      this.updateProgress();
      this.count = 0;
    }

    Loader.prototype.updateProgress = function() {
      var bar, percent, progress, progressBar, sheet, sheetsLoading, span, statusElement, _i, _len, _ref, _results;

      progressBar = $("#loading-progress");
      statusElement = $("#loading-status");
      progressBar.attr('aria-valuemax', this.count);
      progress = 0;
      if (this.count > 0) {
        if (statusElement.is(":hidden")) {
          statusElement.slideDown("fast");
        }
        progress = this.sheetsLoaded.length / this.count;
      }
      percent = progress * 100;
      bar = progressBar.find("div");
      span = progressBar.find("span");
      bar.attr('aria-valuenow', this.sheetsLoaded.length);
      bar.css('width', percent + '%');
      span.text(percent + '% Complete');
      console.log("percent", percent);
      if (percent === 100 && this.count > 1) {
        statusElement.slideUp();
        this.callback();
      }
      sheetsLoading = $("#sheets-loading");
      sheetsLoading.empty();
      _ref = this.sheetsLoading;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        sheet = _ref[_i];
        span = $("<span class='loading-sheet'>");
        span.text(sheet);
        _results.push(sheetsLoading.append(span));
      }
      return _results;
    };

    Loader.prototype.loadingSheet = function(name) {
      this.count += 1;
      this.sheetsLoading.push(name);
      console.log(this.sheetsLoading, this.sheetsLoaded);
      return this.updateProgress();
    };

    Loader.prototype.loadedSheet = function(name) {
      this.sheetsLoaded.push(name);
      this.sheetsLoading = this.sheetsLoading.filter(function(e) {
        return e !== name;
      });
      console.log(this.sheetsLoading, this.sheetsLoaded);
      return this.updateProgress();
    };

    return Loader;

  })();

  Main = (function() {
    Main.prototype.scope = "https://spreadsheets.google.com/feeds";

    Main.prototype.access = "private/full?alt=json-in-script&access_token=";

    Main.prototype.clientId = "172856935415-q064ntcqkmud5m4ub3tj2irri5v9dhs8.apps.googleusercontent.com";

    Main.prototype.apiKey = "14OPwgdy9-2uTIS-x5CDMOYcn2Yo2kuML3Fn0tVMdWrA";

    function Main() {
      this.newApiKey = __bind(this.newApiKey, this);
      this.handleWorksheetData = __bind(this.handleWorksheetData, this);
      this.handleDataWorksheet = __bind(this.handleDataWorksheet, this);
      this.handleCategoryWorksheet = __bind(this.handleCategoryWorksheet, this);
      this.worksheetUrl = __bind(this.worksheetUrl, this);
      this.worksheetDataUrl = __bind(this.worksheetDataUrl, this);
      this.onFinishLoading = __bind(this.onFinishLoading, this);
      var apiKey;

      this.category = {};
      this.data = {};
      apiKey = localStorage["apiKey"];
      $("#start-date").change(this.handleDateChange);
      $("#end-date").change(this.handleDateChange);
      if (apiKey) {
        $("#api-key-input").val(apiKey);
        this.newApiKey(apiKey);
      }
    }

    Main.prototype.handleDateChange = function() {
      var end, invalidRange, start;

      start = new Date($("#start-date").val());
      end = new Date($("#end-date").val());
      console.log("handleDateChange", start, end);
      invalidRange = $("#invalid-range");
      if (start > end && invalidRange.is(":hidden")) {
        invalidRange.slideDown("fast");
      } else if (start <= end && !invalidRange.is(":hidden")) {
        return invalidRange.slideUp("fast");
      }
    };

    Main.prototype.onFinishLoading = function() {
      var data, date, dateString, option, _i, _len, _ref, _ref1;

      console.log("finished loading", this.data);
      this.minDate = null;
      this.maxDate = null;
      this.dates = [];
      _ref = this.data;
      for (dateString in _ref) {
        data = _ref[dateString];
        date = data.date;
        if (this.minDate === null || date < this.minDate) {
          this.minDate = date;
        }
        if (this.maxDate === null || date > this.maxDate) {
          this.maxDate = date;
        }
        this.dates.push(date);
      }
      this.dates.sort(function(i, j) {
        if (i.getTime() > j.getTime()) {
          return 1;
        } else if (i.getTime() < j.getTime()) {
          return -1;
        } else {
          return 0;
        }
      });
      $("#start-date").empty();
      $("#end-date").empty();
      _ref1 = this.dates;
      for (_i = 0, _len = _ref1.length; _i < _len; _i++) {
        date = _ref1[_i];
        option = $("<option>").text(date.toDateString());
        $("#start-date").append(option);
        option = $("<option>").text(date.toDateString());
        $("#end-date").append(option);
      }
      $("#start-date").val(this.minDate.toDateString());
      $("#end-date").val(this.maxDate.toDateString());
      return this.handleDateChange();
    };

    Main.prototype.worksheetDataUrl = function() {
      var token, url;

      token = gapi.auth.getToken().access_token;
      url = this.scope + "/worksheets/" + this.apiKey + "/" + this.access + token + "&callback=?";
      return url;
    };

    Main.prototype.worksheetUrl = function(worksheetId) {
      var token, url;

      token = gapi.auth.getToken().access_token;
      url = this.scope + "/list/" + this.apiKey + "/" + worksheetId + "/" + this.access + token + "&callback=?";
      return url;
    };

    Main.prototype.handleCategoryWorksheet = function(jsonData) {
      var categoryName, parentCategory, recurring, row, _i, _len, _ref, _results;

      console.log("handleCategoryWorksheet", jsonData);
      _ref = jsonData.feed.entry;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        categoryName = row.gsx$categoryname.$t;
        parentCategory = row.gsx$parentcategory.$t;
        recurring = row.gsx$recurring.$t;
        _results.push(this.category[categoryName] = {
          parent: parentCategory,
          recurring: recurring
        });
      }
      return _results;
    };

    Main.prototype.handleDataWorksheet = function(jsonData) {
      var category, cost, date, notes, row, _i, _len, _ref, _results;

      console.log("handleDataWorksheet", jsonData);
      _ref = jsonData.feed.entry;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        date = new Date(row.gsx$date.$t);
        category = row.gsx$category.$t;
        cost = row.gsx$cost.$t;
        notes = row.gsx$notes.$t;
        _results.push(this.data[date.toDateString()] = {
          date: date,
          category: category,
          cost: parseFloat(cost),
          notes: notes
        });
      }
      return _results;
    };

    Main.prototype.handleWorksheetData = function(jsonData) {
      var getCallback, id, sections, title, worksheetData, _i, _len, _ref, _results,
        _this = this;

      console.log("handleWorksheetData", jsonData);
      $("#sheet-title").text(jsonData.feed.title.$t);
      getCallback = function(title) {
        return function(data) {
          if (title === "Categories") {
            _this.handleCategoryWorksheet(data);
          } else {
            _this.handleDataWorksheet(data);
          }
          return _this.loader.loadedSheet(title);
        };
      };
      _ref = jsonData.feed.entry;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        worksheetData = _ref[_i];
        title = worksheetData.title.$t;
        sections = worksheetData.id.$t.split("/");
        id = sections[sections.length - 1];
        this.loader.loadingSheet(title);
        _results.push(loadUrl(this.worksheetUrl(id), getCallback(title)));
      }
      return _results;
    };

    Main.prototype.newApiKey = function(key) {
      var config,
        _this = this;

      if (this.apiKey === key) {
        return;
      }
      console.log("newApiKey", key);
      localStorage["apiKey"] = key;
      this.apiKey = key;
      config = {
        'client_id': this.clientId,
        'scope': this.scope
      };
      this.data = {};
      this.category = {};
      this.loader = new Loader(this.onFinishLoading);
      return gapi.auth.authorize(config, function() {
        _this.loader.loadingSheet("Worksheet list");
        return loadUrl(_this.worksheetDataUrl(), function(data) {
          _this.loader.loadedSheet("Worksheet list");
          return _this.handleWorksheetData(data);
        });
      });
    };

    return Main;

  })();

  main = null;

  $("#load-button").click(function() {
    handleClientLoad();
    return main.newApiKey($("#api-key-input").val());
  });

  handleClientLoad = function() {
    console.log("handleClientLoad");
    main = new Main();
    return console.log(main);
  };

}).call(this);
