// Generated by CoffeeScript 1.6.2
(function() {
  var Loader, Main, PieChart, handleClientLoad, loadUrl, main,
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

  PieChart = (function() {
    function PieChart(main, spent, elementId) {
      this.main = main;
      this.spent = spent;
      this.categoryStack = [];
      this.chart = new google.visualization.PieChart(document.getElementById(elementId));
    }

    PieChart.prototype.gotoParentCategory = function() {
      var current, parent;

      current = this.categoryStack.pop();
      parent = this.categoryStac.pop();
      return this.setCategory(parent);
    };

    PieChart.prototype.getTotal = function(category, start, end) {
      var amount, child, children, date, entry, inRange, rightCategory, rightSign, total, _i, _j, _len, _len1, _ref;

      total = 0;
      _ref = this.main.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entry = _ref[_i];
        date = entry.date;
        inRange = (start <= date && date <= end);
        rightCategory = entry.category === category;
        rightSign = (entry.cost < 0 && this.spent) || (entry.cost > 0 && !this.spent);
        if (inRange && rightCategory && rightSign) {
          amount = Math.abs(entry.cost);
          total += amount;
        }
      }
      children = this.main.category[category];
      if (children) {
        for (_j = 0, _len1 = children.length; _j < _len1; _j++) {
          child = children[_j];
          total += this.getTotal(child, start, end);
        }
      }
      return total;
    };

    PieChart.prototype.setCategory = function(category) {
      var amount, child, children, cost, end, options, pieData, pieDataArray, start, total, totals, _i, _len;

      this.categoryStack.push(category);
      children = this.main.category[category];
      start = new Date($("#start-date").val());
      end = new Date($("#end-date").val());
      totals = {};
      total = 0;
      for (_i = 0, _len = children.length; _i < _len; _i++) {
        child = children[_i];
        amount = this.getTotal(child, start, end);
        totals[child] = amount;
        total += amount;
      }
      pieDataArray = [
        (function() {
          var _results;

          _results = [];
          for (category in totals) {
            cost = totals[category];
            _results.push([category, cost]);
          }
          return _results;
        })()
      ][0];
      pieDataArray.unshift(["Category", "Cost"]);
      pieData = google.visualization.arrayToDataTable(pieDataArray);
      options = {
        title: "Total " + (this.spent ? "Spent" : "Earned") + ": " + total
      };
      return this.chart.draw(pieData, options);
    };

    return PieChart;

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
      this.handleDateChange = __bind(this.handleDateChange, this);
      var apiKey;

      this.category = {};
      this.data = [];
      apiKey = localStorage["apiKey"];
      $("#start-date").change(this.handleDateChange);
      $("#end-date").change(this.handleDateChange);
      this.spentChart = new PieChart(this, true, "pie-total-spent");
      this.earnedChart = new PieChart(this, false, "pie-total-earned");
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
        return;
      } else if (start <= end && !invalidRange.is(":hidden")) {
        invalidRange.slideUp("fast");
      }
      this.spentChart.setCategory("all");
      return this.earnedChart.setCategory("all");
    };

    Main.prototype.onFinishLoading = function() {
      var date, entry, option, _i, _j, _len, _len1, _ref, _ref1;

      console.log("finished loading", this.data);
      this.minDate = null;
      this.maxDate = null;
      this.dates = [];
      _ref = this.data;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        entry = _ref[_i];
        date = entry.date;
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
      for (_j = 0, _len1 = _ref1.length; _j < _len1; _j++) {
        date = _ref1[_j];
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
      var categoryName, parent, row, _i, _len, _ref;

      console.log("handleCategoryWorksheet", jsonData);
      _ref = jsonData.feed.entry;
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        row = _ref[_i];
        categoryName = row.gsx$categoryname.$t;
        parent = row.gsx$parentcategory.$t;
        if (!parent) {
          parent = "all";
        }
        if (!this.category[parent]) {
          this.category[parent] = [];
        }
        this.category[parent].push(categoryName);
      }
      return console.log(this.category);
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
        cost = row.gsx$cost.$t.replace("$", "").replace(",", "");
        notes = row.gsx$notes.$t;
        _results.push(this.data.push({
          date: date,
          category: category,
          cost: parseFloat(cost),
          notes: notes
        }));
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
      this.data = [];
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
    return main.newApiKey($("#api-key-input").val());
  });

  google.load("visualization", "1", {
    packages: ["corechart"]
  });

  google.setOnLoadCallback(function() {
    console.log("onLoad");
    main = new Main();
    return console.log(main);
  });

  handleClientLoad = function() {
    console.log("handleClientLoad");
    main = new Main();
    return console.log(main);
  };

}).call(this);
