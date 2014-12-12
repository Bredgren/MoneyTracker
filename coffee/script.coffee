
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
  clientId: "225160616080-rlae3dprbofq5i1etegg5vdvobf2rhqi.apps.googleusercontent.com"
  apiKey: "14OPwgdy9-2uTIS-x5CDMOYcn2Yo2kuML3Fn0tVMdWrA"

  constructor: () ->
    @category = {} # Name: string -> { parent: string, recuring: string }
    @data = {} # Date -> { category: string: cost: number, notes: string }
    apiKey = localStorage["apiKey"]
    # if apiKey
    #   @newApiKey(apiKey)
    @newApiKey(@apiKey)

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
      recuring = row.gsx$recuring.$t
      @category[categoryName] = {
        parent: parentCategory,
        recuring: recuring
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
    for worksheetData in jsonData.feed.entry
      title = worksheetData.title.$t
      sections = worksheetData.id.$t.split("/")
      id = sections[sections.length - 1]
      @loader.loadingSheet(title)
      if title == "Categories"
        loadUrl(@worksheetUrl(id), (data) =>
          @loader.loadedSheet(title)
          @handleCategoryWorksheet(data))
      else
        loadUrl(@worksheetUrl(id), (data) =>
          @loader.loadedSheet(title)
          @handleDataWorksheet(data))

  newApiKey: (key) =>
    # if @apiKey == key then return
    console.log("newApiKey", key)
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

$("#authorize-button").click(() ->
  m = new Main()
  console.log(m)
);

handleClientLoad = () ->
  console.log("handleClientLoad")
