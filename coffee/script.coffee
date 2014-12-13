
loadUrl = (url, callback) ->
  console.log("fetching", url)
  $.getJSON(url, callback)

class Loader
  constructor: () ->
    @sheetsLoading = []
    @sheetsLoaded = []

  loadingSheet: (name) =>
    @sheetsLoading.push(name)
    console.log(@sheetsLoading, @sheetsLoaded)

  loadedSheet: (name) =>
    @sheetsLoaded.push(name)
    @sheetsLoading = @sheetsLoading.filter((e) -> e != name)
    console.log(@sheetsLoading, @sheetsLoaded)

class Main
  scope: "https://spreadsheets.google.com/feeds"
  access: "private/full?alt=json-in-script&access_token="
  clientId: "172856935415-q064ntcqkmud5m4ub3tj2irri5v9dhs8.apps.googleusercontent.com"
  apiKey: "14OPwgdy9-2uTIS-x5CDMOYcn2Yo2kuML3Fn0tVMdWrA"

  constructor: () ->
    @category = {} # Name: string -> { parent: string, recurring: string }
    @data = {} # Date -> { category: string: cost: number, notes: string }
    apiKey = localStorage["apiKey"]
    console.log(apiKey)
    if apiKey
      $("#api-key-input").val(apiKey)
      @newApiKey(apiKey)

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
      date = row.gsx$date.$t
      category = row.gsx$category.$t
      cost = row.gsx$cost.$t
      notes = row.gsx$notes.$t
      # TODO: check if category is valid?
      @data[new Date(date)] = {
        category: category,
        cost: parseFloat(cost),
        notes: notes
      }

  handleWorksheetData: (jsonData) =>
    console.log("handleWorksheetData", jsonData)
    $("#sheet-title").text(jsonData.feed.title.$t)
    getCallback =(title) =>
      return (data) =>
        @loader.loadedSheet(title)
        if title == "Categories"
          @handleCategoryWorksheet(data)
        else
          @handleDataWorksheet(data)
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
    @loader = new Loader()
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