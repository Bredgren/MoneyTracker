
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

class Main
  scope: "https://spreadsheets.google.com/feeds"
  access: "private/full?alt=json-in-script&access_token="
  clientId: "172856935415-q064ntcqkmud5m4ub3tj2irri5v9dhs8.apps.googleusercontent.com"
  apiKey: "14OPwgdy9-2uTIS-x5CDMOYcn2Yo2kuML3Fn0tVMdWrA"

  constructor: () ->
    @category = {} # Name: string -> { parent: string, recurring: string }
    @data = {} # Date -> { category: string: cost: number, notes: string }
    apiKey = localStorage["apiKey"]
    $("#start-date").change(@handleDateChange)
    $("#end-date").change(@handleDateChange)

    if apiKey
      $("#api-key-input").val(apiKey)
      @newApiKey(apiKey)

  handleDateChange: () ->
    start = new Date($("#start-date").val())
    end = new Date($("#end-date").val())
    console.log("handleDateChange", start, end)
    invalidRange = $("#invalid-range")
    if start > end and invalidRange.is(":hidden")
      invalidRange.slideDown("fast")
      return
    else if start <= end and not invalidRange.is(":hidden")
      invalidRange.slideUp("fast")

  onFinishLoading: () =>
    console.log("finished loading", @data)
    @minDate = null
    @maxDate = null
    @dates = []
    for dateString, data of @data
      date = data.date
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
      parentCategory = row.gsx$parentcategory.$t
      recurring = row.gsx$recurring.$t
      @category[categoryName] = {
        parent: parentCategory,
        recurring: recurring
      }

  handleDataWorksheet: (jsonData) =>
    console.log("handleDataWorksheet", jsonData)
    for row in jsonData.feed.entry
      date = new Date(row.gsx$date.$t)
      category = row.gsx$category.$t
      cost = row.gsx$cost.$t
      notes = row.gsx$notes.$t
      # TODO: check if category is valid?
      @data[date.toDateString()] = {
        date: date,
        category: category,
        cost: parseFloat(cost),
        notes: notes
      }

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
    @data = {}
    @category = {}
    @loader = new Loader(@onFinishLoading)
    gapi.auth.authorize(config, () =>
      @loader.loadingSheet("Worksheet list")
      loadUrl(@worksheetDataUrl(), (data) =>
        @loader.loadedSheet("Worksheet list")
        @handleWorksheetData(data)))

main = null

$("#load-button").click(() ->
  handleClientLoad()
  main.newApiKey($("#api-key-input").val())
);

handleClientLoad = () ->
  console.log("handleClientLoad")
  main = new Main()
  console.log(main)