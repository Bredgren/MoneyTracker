
# class Main
#   constructor: ->
#     console.log("hello")

# jQuery ->
#   m = new Main()

scopes = 'https://spreadsheets.google.com/feeds'
clientId = '225160616080-rlae3dprbofq5i1etegg5vdvobf2rhqi.apps.googleusercontent.com'
apiKey = '14OPwgdy9-2uTIS-x5CDMOYcn2Yo2kuML3Fn0tVMdWrA'

handleClientLoad = () ->
  console.log("handleClientLoad")
  gapi.client.setApiKey(apiKey)
  window.setTimeout(checkAuth, 1)

checkAuth = () ->
  console.log('checkAuth')
  gapi.auth.authorize({client_id: clientId, scope: scopes, immediate: true}, handleAuthResult)
  console.log('finished checkAuth')

handleAuthResult = (authResult) ->
  console.log("handleAuthResult", authResult)

loadClient = () ->
  config = {
    'client_id': clientId,
    'scope': scopes
  }
  gapi.auth.authorize(config, () ->
    console.log('login complete')
    token = gapi.auth.getToken().access_token
    console.log(token)
    url = 'https://spreadsheets.google.com/feeds/worksheets/' + apiKey + '/private/full?alt=json-in-script&access_token=' + token + '&callback=?'
    $.getJSON(url, (data) ->
      console.log("got json")
      console.log(data)
    )
  )

$("#authorize-button").click(loadClient);
