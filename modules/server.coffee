# Server module

# Import modules
sys = require 'sys'
http = require 'http'
path = require 'path'
url = require 'url'
fs = require 'fs'

# The main method
main = (port=8080) ->
  # Set directory to root/public
  dir = path.join(process.cwd(), '.')

  # Create the server
  server = http.createServer (request, response) ->
    reqPath = url.parse(request.url).pathname
    if reqPath == '/'
      reqPath = '/index.html'
    sys.puts 'Requested path: ' + reqPath
    fullPath = path.join dir, reqPath

    if reqPath.indexOf('/server') == 0
      response.writeHeader 200,
          'Content-Type': 'text/plain'
      response.write 'Dummy server text\n'
      response.end()
    else
      path.exists fullPath, (exists) ->
        if not exists
          sys.puts '  Error: Requested path not found!'
          response.writeHeader 404,
            'Content-Type': 'text/plain'
          response.write '404 Not Found\n'
          response.end()
        else
          fs.readFile fullPath, 'binary', (err, file) ->
            if err
              response.writeHeader 500,
                'Content-Type': 'text/plain'
              response.write err + '\n'
              response.end()
            else
              # if fullPath.match(/\.css$/)
              #   response.writeHeader 200,
              #     'Content-Type': 'text/css'
              #   response.write file
              #   response.end()
              # else
              #   response.writeHeader 200
              #   response.write file, 'binary'
              #   response.end()
              contentType = getContentType reqPath
              response.writeHeader 200,
                'Content-Type': contentType
              response.write file, 'binary'
              response.end()

  # Start the server
  server.listen port
  sys.puts "Server now listening on port #{port}"

# Get the MIME type for the file
getContentType = (filename) ->
  # Text
  if filename.match /\.html?$/
    return 'text/html'
  if filename.match /\.css$/
    return 'text/css'
  if filename.match /\.txt$/
    return 'text/plain'
  # Application
  if filename.match /\.js$/
    return 'application/javascript'
  if filename.match /\.js$/
    return 'application/json'
  # Audio
  if filename.match /\.mp3$/
    return 'audio/mpeg'
  if filename.match /\.ogg$/
    return 'audio/ogg'
  # Images
  if filename.match /\.jpe?g$/
    return 'image/jpeg'
  if filename.match /\.png$/
    return 'image/png'
  # Default
  return ''

# Export server functions
module.exports =
  start: main
