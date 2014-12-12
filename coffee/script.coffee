
loadUrl = (url, callback) ->
  $.getJSON(url, callback)

class Main
  scope: "https://spreadsheets.google.com/feeds"
  access: "private/full?alt=json-in-script&access_token="
  clientId: "225160616080-rlae3dprbofq5i1etegg5vdvobf2rhqi.apps.googleusercontent.com"
  apiKey: "14OPwgdy9-2uTIS-x5CDMOYcn2Yo2kuML3Fn0tVMdWrA"

  constructor: () ->
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
    url = @scope + @apiKey + "/" + worksheetId + @access + token
    return url

  handleWorksheetData: (jsonData) =>
    console.log("handleWorksheetData", jsonData)
    for worksheetData in jsonData.feed.entry
      sections = worksheetData.id.$t.split("/")
      id = sections[sections.length - 1]
      console.log(id, @worksheetUrl(id))

  newApiKey: (key) =>
    # if @apiKey == key then return
    console.log("newApiKey", key)
    @apiKey = key
    config = {
      'client_id': @clientId,
      'scope': @scope
    }
    @data = {}
    gapi.auth.authorize(config, () =>
      loadUrl(@worksheetDataUrl(), @handleWorksheetData)
    )

$("#authorize-button").click(() ->
  m = new Main()
);
