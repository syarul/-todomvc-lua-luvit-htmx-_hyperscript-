local utility = {}

function utility.selectedFilter(filters)
  for _, filter in ipairs(filters) do
    if filter.selected then
      return filter.name
    end
  end
  return 'All'
end

function utility.hasCompleteTask(todos)
  for _, todo in ipairs(todos) do
    if todo.done then
      return true
    end
  end
  return false
end

function utility.countNotDone(todos)
  local count = 0
  for _, todo in pairs(todos) do
    if not todo.done then
      count = count + 1
    end
  end
  return count
end

function utility.defChecked(todos)
  local uncompletedCount = utility.countNotDone(todos)
  local defaultChecked = false
  if uncompletedCount == 0 and #todos > 0 then
    defaultChecked = true
  end
  return defaultChecked
end

function utility.map(a, fcn)
  local b = {}
  for _, v in ipairs(a) do
    table.insert(b, fcn(v))
  end
  return b
end

function utility.decodeURI(str)
  str = string.gsub(str, "%%(%x%x)", function(hex)
      return string.char(tonumber(hex, 16))
  end)
  return str
end

function utility.parseQuery(query, param)
  if not query then
    return query
  end

  local result

  for key, value in query:gmatch("([^&=?]+)=([^&=?]+)") do

    if key == "title" then
      value = utility.decodeURI(value)
    end

    if param then
      result = value
    else
      result = result or {}
      result[key] = value
    end
  end
  return result
end

function utility.getHeaders(client, headers)
  while true do
    local line, _ = client:receive()
    if line == "" or line == nil then
      break
    else
      local key, value = line:match("^(.-):%s*(.*)$")
      if key and value then
        if key:lower() == "cookie" then
          headers[key:lower()] = value
          break -- only read cookie
        end
      end
    end
  end
end

local charset = {}
do -- [0-9a-zA-Z]
  for c = 48, 57 do table.insert(charset, string.char(c)) end
  for c = 65, 90 do table.insert(charset, string.char(c)) end
  for c = 97, 122 do table.insert(charset, string.char(c)) end
end

function utility.randomString(length)
  if not length or length <= 0 then return '' end
  math.randomseed(os.time() * 10000)
  return utility.randomString(length - 1) .. charset[math.random(1, #charset)]
end

function utility.unescape(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

function utility.render(client, statusCode, body, customHeaders)
  local headerString = "HTTP/1.1 " .. statusCode .. "\r\n"
  local headers = {
    ["Content-Type"] = "text/html"
  }
  if type(customHeaders) == "table" then
    for k, v in pairs(customHeaders) do
      headers[k] = v
    end
  end
  for k, v in pairs(headers) do
    headerString = headerString .. k .. ": " .. v .. "\r\n"
  end
  headerString = headerString .. "\r\n"
  if type(body) == "table" then
    body = _G.h(body)
  end
  client:send(headerString .. (body or ""))
end

function utility.readStaticFile(filePath)
  local file, err = io.open(_G.getDir() .. filePath, "rb")  -- in binary mode
  if not file then
      return nil, "Error opening file: " .. err
  end

  local content = file:read("*all")
  file:close()
  return content
end

utility.mimes = {
  _hs = 'text/hyperscript',
  json = 'application/json',
  js = 'application/javascript'
}

function utility.getType(path)
  return utility.mimes[path:lower():match("[^.]*$")] or "application/octet-stream"
end

return utility