
loadUrl = (url, callback) ->
  console.log("fetching", url)
  $.getJSON(url, callback)

class Loader
  constructor: (@callback) ->
    @sheetsLoading = []
    @sheetsLoaded = []
    @updateProgress()
    @count = 0

  updateProgress: () =>
    progressBar = $("#loading-progress");
    statusElement = $("#loading-status")

    progressBar.attr('aria-valuemax', @count)
    progress = 0
    if @count > 0
      if statusElement.is(":hidden")
        statusElement.slideDown("fast")
      progress = @sheetsLoaded.length / @count
    percent = progress * 100
    bar = progressBar.find("div");
    span = progressBar.find("span");
    bar.attr('aria-valuenow', @sheetsLoaded.length);
    bar.css('width', percent + '%');
    span.text(percent + '% Complete');
    console.log("percent", percent)
    if percent == 100 and @count > 1
      statusElement.slideUp()
      @callback()

    sheetsLoading = $("#sheets-loading")
    sheetsLoading.empty()
    for sheet in @sheetsLoading
      span = $("<span class='loading-sheet'>")
      span.text(sheet)
      sheetsLoading.append(span)

  loadingSheet: (name) =>
    @count += 1
    @sheetsLoading.push(name)
    console.log(@sheetsLoading, @sheetsLoaded)
    @updateProgress()

  loadedSheet: (name) =>
    @sheetsLoaded.push(name)
    @sheetsLoading = @sheetsLoading.filter((e) -> e != name)
    console.log(@sheetsLoading, @sheetsLoaded)
    @updateProgress()

class PieChart
  constructor: (@main, @spent, elementId) ->
    @categoryStack = []
    @chart = new google.visualization.PieChart(document.getElementById(elementId))

  gotoParentCategory: () ->
    current = @categoryStack.pop()
    parent = @categoryStac.pop()
    @setCategory(parent)

  getTotal: (category, start, end) ->
    total = 0

    for entry in @main.data
      date = entry.date
      inRange = start <= date <= end
      rightCategory = entry.category == category
      rightSign = (entry.cost < 0 and @spent) or (entry.cost > 0 and not @spent)
      if inRange and rightCategory and rightSign
        amount = Math.abs(entry.cost)
        total += amount

    children = @main.category[category]
    if children
      for child in children
        total += @getTotal(child, start, end)
    return total

  setCategory: (category) ->
    @categoryStack.push(category)
    children = @main.category[category]

    start = new Date($("#start-date").val())
    end = new Date($("#end-date").val())

    totals = {}
    total = 0
    for child in children
      amount = @getTotal(child, start, end)
      totals[child] = amount
      total += amount

    pieDataArray = [[category, cost] for category, cost of totals][0]
    pieDataArray.unshift(["Category", "Cost"])
    pieData = google.visualization.arrayToDataTable(pieDataArray)
    options = {
      title: "Total " + (if @spent then "Spent" else "Earned") + ": " + total
    }
    @chart.draw(pieData, options)

class Main
  scope: "https://spreadsheets.google.com/feeds"
  access: "private/full?alt=json-in-script&access_token="
  clientId: "172856935415-q064ntcqkmud5m4ub3tj2irri5v9dhs8.apps.googleusercontent.com"
  apiKey: "14OPwgdy9-2uTIS-x5CDMOYcn2Yo2kuML3Fn0tVMdWrA"

  constructor: () ->
    @category = {} # parent: string -> [ child: string, ... ]
    @data = [] # { date: Date, category: string, cost: number, notes: string }
    apiKey = localStorage["apiKey"]
    $("#start-date").change(@handleDateChange)
    $("#end-date").change(@handleDateChange)
    @spentChart = new PieChart(@, true, "pie-total-spent")
    @earnedChart = new PieChart(@, false, "pie-total-earned")

    if apiKey
      $("#api-key-input").val(apiKey)
      @newApiKey(apiKey)

  handleDateChange: () =>
    start = new Date($("#start-date").val())
    end = new Date($("#end-date").val())
    console.log("handleDateChange", start, end)
    invalidRange = $("#invalid-range")
    if start > end and invalidRange.is(":hidden")
      invalidRange.slideDown("fast")
      return
    else if start <= end and not invalidRange.is(":hidden")
      invalidRange.slideUp("fast")

    @spentChart.setCategory("all")
    @earnedChart.setCategory("all")

    # spentTotals = {}
    # totalSpent = 0
    # earnedTotals = {}
    # totalEarned = 0
    # for entry in @data
    #   date = entry.date
    #   if start <= date <= end
    #     if entry.cost < 0
    #       if not spentTotals[entry.category]
    #         spentTotals[entry.category] = 0
    #       amount = Math.abs(entry.cost)
    #       spentTotals[entry.category] += amount
    #       totalSpent += amount
    #     else
    #       if not earnedTotals[entry.category]
    #         earnedTotals[entry.category] = 0
    #       earnedTotals[entry.category] += entry.cost
    #       totalEarned += entry.cost

    # pieDataArray = [[category, cost] for category, cost of spentTotals][0]
    # pieDataArray.unshift(["Category", "Cost"])
    # console.log(pieDataArray)
    # pieData = google.visualization.arrayToDataTable(pieDataArray)
    # options = {
    #   title: "Total Spent: " + totalSpent,
    # }
    # chart = new google.visualization.PieChart(document.getElementById("pie-total-spent"))
    # chart.draw(pieData, options)

    # pieDataArray = [[category, cost] for category, cost of earnedTotals][0]
    # pieDataArray.unshift(["Category", "Cost"])
    # pieData = google.visualization.arrayToDataTable(pieDataArray)
    # options = {
    #   title: "Total Earned: " + totalEarned,
    # }
    # chart = new google.visualization.PieChart(document.getElementById("pie-total-earned"))
    # chart.draw(pieData, options)

  onFinishLoading: () =>
    console.log("finished loading", @data)
    @minDate = null
    @maxDate = null
    @dates = []
    for entry in @data
      date = entry.date
      if @minDate == null or date < @minDate
        @minDate = date
      if @maxDate == null or date > @maxDate
        @maxDate = date
      @dates.push(date)
    @dates.sort((i, j) ->
      if i.getTime() > j.getTime()
        return 1
      else if i.getTime() < j.getTime()
        return -1
      else
        return 0)
    $("#start-date").empty()
    $("#end-date").empty()
    for date in @dates
      option = $("<option>").text(date.toDateString())
      $("#start-date").append(option)
      option = $("<option>").text(date.toDateString())
      $("#end-date").append(option)
    $("#start-date").val(@minDate.toDateString())
    $("#end-date").val(@maxDate.toDateString())
    @handleDateChange()

  worksheetDataUrl: () =>
    token = gapi.auth.getToken().access_token
    url = @scope + "/worksheets/" + @apiKey + "/" + @access + token + "&callback=?";
    return url

  worksheetUrl: (worksheetId) =>
    token = gapi.auth.getToken().access_token
    url = @scope + "/list/" + @apiKey + "/" + worksheetId + "/" + @access + token + "&callback=?";
    return url

  handleCategoryWorksheet: (jsonData) =>
    console.log("handleCategoryWorksheet", jsonData)
    for row in jsonData.feed.entry
      categoryName = row.gsx$categoryname.$t
      parent = row.gsx$parentcategory.$t
      if not parent
        parent = "all"
      if not @category[parent]
        @category[parent] = []
      @category[parent].push(categoryName)
    console.log(@category)

  handleDataWorksheet: (jsonData) =>
    console.log("handleDataWorksheet", jsonData)
    for row in jsonData.feed.entry
      date = new Date(row.gsx$date.$t)
      category = row.gsx$category.$t
      cost = row.gsx$cost.$t.replace("$", "").replace(",", "")
      notes = row.gsx$notes.$t
      @data.push({
        date: date,
        category: category,
        cost: parseFloat(cost),
        notes: notes
      })

  handleWorksheetData: (jsonData) =>
    console.log("handleWorksheetData", jsonData)
    $("#sheet-title").text(jsonData.feed.title.$t)
    getCallback =(title) =>
      return (data) =>
        if title == "Categories"
          @handleCategoryWorksheet(data)
        else
          @handleDataWorksheet(data)
        @loader.loadedSheet(title)
    for worksheetData in jsonData.feed.entry
      title = worksheetData.title.$t
      sections = worksheetData.id.$t.split("/")
      id = sections[sections.length - 1]
      @loader.loadingSheet(title)
      loadUrl(@worksheetUrl(id),getCallback(title))

  newApiKey: (key) =>
    if @apiKey == key then return
    console.log("newApiKey", key)
    localStorage["apiKey"] = key
    @apiKey = key
    config = {
      'client_id': @clientId,
      'scope': @scope
    }
    @data = []
    @category = {}
    @loader = new Loader(@onFinishLoading)
    gapi.auth.authorize(config, () =>
      @loader.loadingSheet("Worksheet list")
      loadUrl(@worksheetDataUrl(), (data) =>
        @loader.loadedSheet("Worksheet list")
        @handleWorksheetData(data)))

main = null

$("#load-button").click(() ->
  main.newApiKey($("#api-key-input").val())
);

google.load("visualization", "1", {packages:["corechart"]})

google.setOnLoadCallback(() ->
  console.log("onLoad")
  main = new Main()
  console.log(main))

handleClientLoad = () ->
  console.log("handleClientLoad")
  main = new Main()
  console.log(main)