local socket = require("socket")
local url = require('socket.url') -- Use socket.url for URL parsing
local json = require('cjson')     -- Use your json library
local lfs = require('lfs')        -- LuaFileSystem for file operations (to replace fs)

function getDir()
  local handle
  local result
  
  if os.getenv("OS") == "Windows_NT" then
    handle = io.popen("cd")
  else
    handle = io.popen("pwd")
  end
  
  if handle then
    result = handle:read("*a"):gsub("%s+", "")
    handle:close()
  else
    result = "Failed to get directory"
  end
  
  return result
end

package.path = package.path .. ";" ..  getDir() .. "/?.lua"
package.path = package.path .. ";" ..  getDir() .. "/?/init.lua"
package.cpath = package.cpath .. ";" ..  getDir() .. "/?.dll"

local utility = require('utility')

local page = require('templates.page')
local todoEdit = require('templates.todo-edit')
local toggleMain = require('templates.toggle-main')
local todoItem = require('templates.todo-item')
local todoList = require('templates.todo-list')
local clearCompleted = require('templates.clear-completed')
local todoFooter = require('templates.todo-footer')

local todos = {}

local idCounter = #todos

local filters = {
  { url = "#/",          name = "All",       selected = true },
  { url = "#/active",    name = "Active",    selected = false },
  { url = "#/completed", name = "Completed", selected = false },
}

local function Page(client, headers)
  local cookieString = headers["cookie"]
  local sessionId = cookieString and cookieString:match("sessionId=([^;]+)")
  
  local setCookie
  if not sessionId then
    local newCookieValue = utility.randomString(32)
    
    setCookie = "sessionId="
      .. newCookieValue
      .. "; Expires="
      .. os.date("%a, %d %b %Y %X GMT", os.time() + 6000)
      .. "; HttpOnly"
    -- reset todos, counter
    todos = {}
    idCounter = 0
  end

  local html = page.Page(todos, filters)

  local customHeaders = nil

  if setCookie then
    customHeaders = {
      ["Set-Cookie"] = setCookie
    }
  end

  utility.render(client, "200 OK", html, customHeaders)
end

local function SetHash(client, queryName)
  local name = queryName or "All"

  for _, filter in ipairs(filters) do
    filter.selected = (filter.name == name)
  end

  utility.render(client, "200 OK")
end

local function TodoJSON(client, queryCount)
  local count = queryCount == 'true'
  if count then
    utility.render(client, "200 OK", string.format(#todos), { ["Content-Type"] = "text/plain" })
  else
    utility.render(client, "200 OK", json.encode(todos), { ["Content-Type"] = "application/json" })
  end
end

local function Footer(client)
  local html = todoFooter.TodoFooter(todos, filters)
  utility.render(client, "200 OK", html)
end

local function AddTodo(client, title)
  local newTodo

  if title and title ~= '' then
    idCounter = idCounter + 1
    newTodo = {
      id = idCounter,
      title = utility.unescape(title),
      done = false,
      editing = false
    }

    table.insert(todos, newTodo)
  end

  local html

  if #todos == 1 then
    html = todoList.TodoList(todos, filters)
  else
    local filterName = utility.selectedFilter(filters)
    html = todoItem.TodoItem(newTodo, filterName)
  end

  utility.render(client, "200 OK", html)
end

local function ToggleMain(client)
  local html = toggleMain.ToggleMain(todos)
  utility.render(client, "200 OK", html)
end

local function UpdateCount(client)
  local uncompletedCount = utility.countNotDone(todos)
  local plural = ''
  if uncompletedCount ~= 1 then
    plural = 's'
  end

  local str = string.format('<strong>%s</strong> item%s left', uncompletedCount, plural)

  utility.render(client, "200 OK", str)
end

local function ToggleTodo(client, query)
  local id = tonumber(query.id)
  local done = query.done == 'true'

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      todo.done = not done
      local filterName = utility.selectedFilter(filters)
      html = todoItem.TodoItem(todo, filterName)
      break
    end
  end

  utility.render(client, "200 OK", html)
end

local function ToggleAll(client)
  local checked = utility.defChecked(todos)
  utility.render(client, "200 OK", tostring(checked))
end

local function Completed(client)
  local hasCompleted = utility.hasCompleteTask(todos)
  local html
  if hasCompleted then
    html = clearCompleted.ClearCompleted(todos)
  end

  utility.render(client, "200 OK", html)
end

local function RemoveTodo(client, queryId)
  local id = tonumber(queryId)

  for index, todo in ipairs(todos) do
    if todo.id == id then
      table.remove(todos, index)
      break
    end
  end

  utility.render(client, "200 OK")
end

local function EditTodo(client, queryId)
  local id = tonumber(queryId)

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      html = todoEdit.EditTodo({ id = id, title = todo.title, done = false, editing = true })
      break
    end
  end

  utility.render(client, "200 OK", html)
end

local function UpdateTodo(client, query)
  local id = tonumber(query.id)
  local title = query.title

  local html
  for index, todo in ipairs(todos) do
    if todo.id == id then
      if title and title ~= '' then
        todo.title = utility.unescape(title)
        local filterName = utility.selectedFilter(filters)
        html = todoItem.TodoItem(todo, filterName)
      else
        table.remove(todos, index)
      end
      break
    end
  end

  utility.render(client, "200 OK", html)
end

local function SwapJSON(client, queryAll)
  local all = queryAll == 'true'

  for _, todo in ipairs(todos) do
    if all then
      todo.done = true
    else
      todo.done = false
    end
  end

  utility.render(client, "200 OK")
end

local function TodoItem(client, queryId)
  local id = tonumber(queryId)

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      local filterName = utility.selectedFilter(filters)
      html = todoItem.TodoItem(todo, filterName)
      break
    end
  end

  utility.render(client, "200 OK", html)
end

local function handler(client, request, headers)

  if request then
    local method, path = request:match("^(%w+)%s([^%s]+)%sHTTP")

    local parsedUrl = url.parse(path)

    local queryString = parsedUrl.query

    if parsedUrl.path == "/" then
      Page(client, headers)
    elseif parsedUrl.path == "/set-hash" then
      SetHash(client, utility.parseQuery(queryString, "name"))

    elseif parsedUrl.path == "/todo-json" then
      TodoJSON(client, utility.parseQuery(queryString, "count"))
    
    elseif parsedUrl.path == "/footer" then
      Footer(client)

    elseif parsedUrl.path == "/add-todo" then
      AddTodo(client, utility.parseQuery(queryString, "title"))
    
    elseif parsedUrl.path == "/toggle-main" then
      ToggleMain(client)
    
    elseif parsedUrl.path == "/update-count" then
      UpdateCount(client)

    elseif parsedUrl.path == "/toggle-todo" then
      ToggleTodo(client, utility.parseQuery(queryString))
    
    elseif parsedUrl.path == "/toggle-all" then
      ToggleAll(client)

    elseif parsedUrl.path == "/completed" then
      Completed(client)
    
    elseif parsedUrl.path == "/remove-todo" then
      RemoveTodo(client, utility.parseQuery(queryString, "id"))
    
    elseif parsedUrl.path == "/edit-todo" then
      EditTodo(client, utility.parseQuery(queryString, "id"))

    elseif parsedUrl.path == "/update-todo" then
      UpdateTodo(client, utility.parseQuery(queryString))

    elseif parsedUrl.path == "/swap-json" then
      SwapJSON(client, utility.parseQuery(queryString, "all"))

    elseif parsedUrl.path == "/todo-item" then
      TodoItem(client, utility.parseQuery(queryString, "id"))

    elseif utility.mimes[parsedUrl.path:lower():match("[^.]*$")] and method == "GET" then
      local file = parsedUrl.path
      local contentType = utility.getType(file)
      -- custom axe-core path
      if file == '/node_modules/axe-core/axe.min.js' then
        file = './cypress-example-todomvc' .. file:gsub('^%.', '')
      end
      local content, err = utility.readStaticFile(file)
      if not err then
        utility.render(client, "200 OK", content, { ["Content-Type"] = contentType })
      else
        utility.render(client, "404 Not Found", "Not Found", { ["Content-Type"] = "text/plain" })
      end

    else
      -- 404
      utility.render(client, "404 Not Found", "Not Found", { ["Content-Type"] = "text/plain" })
    end
  end
end

-- non blocking io socket setup
local server = socket.tcp()

server:bind("*", 8888)
server:listen()
server:settimeout(0)

print('Lua Socket TCP Server running at http://127.0.0.1:8888/')

while true do
  -- Check for new connections
  local client = server:accept()
  if client then
      client:settimeout(10)
      local headers = {}
      local request, err = client:receive()
      if not err then
        utility.getHeaders(client, headers)
        handler(client, request, headers)
      end
      -- done with client, close the object
      client:close()
  end
end