local http = require('http')
local fs = require('fs')
local url = require('url')
local json = require('json')

local mimes = {
  _hs = 'text/hyperscript'
}

mimes.default = "application/octet-stream"

local function getType(path)
  return mimes[path:lower():match("[^.]*$")] or mimes.default
end

local page = require('templates.page')
local todoEdit = require('templates.todo-edit')
local toggleMain = require('templates.toggle-main')
local todoItem = require('templates.todo-item')
local todoList = require('templates.todo-list')
local clearCompleted = require('templates.clear-completed')
local todoFooter = require('templates.todo-footer')

local utility = require('utility')

local todos = {}

local idCounter = #todos

local filters = {
  { url = "#/",          name = "All",       selected = true },
  { url = "#/active",    name = "Active",    selected = false },
  { url = "#/completed", name = "Completed", selected = false },
}

local function unescape(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

local function SetHash(req, res)
  local parsedUrl = url.parse(req.url, true)
  local name = parsedUrl.query.name or "All"

  for _, filter in ipairs(filters) do
    filter.selected = (filter.name == name)
  end

  -- ptable(filters, 0)

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish('\n') --- luvit won't send empty string to client which needed by htmx:afterRequest or /fetch
end

local function AddTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local title = parsedUrl.query.title
  local newTodo

  if title and title ~= '' then
    idCounter = idCounter + 1
    newTodo = {
      id = idCounter,
      title = unescape(title),
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

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function ToggleTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)
  local done = parsedUrl.query.done == 'true'

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      todo.done = not done
      local filterName = utility.selectedFilter(filters)
      html = todoItem.TodoItem(todo, filterName)
      break
    end
  end

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function Footer(_, res)
  local html = todoFooter.TodoFooter(todos, filters)

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function UpdateCount(_, res)
  local uncompletedCount = utility.countNotDone(todos)
  local plural = ''
  if uncompletedCount ~= 1 then
    plural = 's'
  end

  local str = string.format('<strong>%s</strong> item%s left', uncompletedCount, plural)

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(str)
end

local function TodoJson(_, res)
  res.statusCode = 200
  res:setHeader('Content-Type', 'application/json')
  res:finish(json.encode(todos))
end

local function SwapJson(req, res)
  local parsedUrl = url.parse(req.url, true)
  local all = parsedUrl.query.all == 'true'

  for _, todo in ipairs(todos) do
    if all then
      todo.done = true
    else
      todo.done = false
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish('\n')
end

local function TodoCompleted(_, res)
  local hasCompleted = utility.hasCompleteTask(todos)
  local html = '\n' -- luvit won't send empty string to client which needed by htmx:afterRequest or /fetch
  if hasCompleted then
    html = clearCompleted.ClearCompleted(todos)
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function TodoToggleAll(_, res)
  local checked = utility.defChecked(todos)

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(tostring(checked))
end

local function TodoHandleItem(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      local filterName = utility.selectedFilter(filters)
      html = todoItem.TodoItem(todo, filterName)
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function EditHandlerTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      html = todoEdit.EditTodo({ id = id, title = todo.title, done = false, editing = true })
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function UpdateTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)
  local title = parsedUrl.query.title

  local html = '\n' -- luvit won't send empty string to client which needed by htmx:afterRequest or /fetch
  for index, todo in ipairs(todos) do
    if todo.id == id then
      if title and title ~= '' then
        todo.title = unescape(title)
        local filterName = utility.selectedFilter(filters)
        html = todoItem.TodoItem(todo, filterName)
      else
        table.remove(todos, index)
      end
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function RemoveTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)

  for index, todo in ipairs(todos) do
    if todo.id == id then
      table.remove(todos, index)
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish('\n')
end

local function ToggleHandleMain(_, res)
  local html = toggleMain.ToggleMain(todos)
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function ToggleHandleFooter(_, res)
  local html = todoFooter.TodoFooter(todos, filters)
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local function TodoHandleList(_, res)
  local html = todoList.TodoList(todos, filters)
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local charset = {}
do -- [0-9a-zA-Z]
  for c = 48, 57 do table.insert(charset, string.char(c)) end
  for c = 65, 90 do table.insert(charset, string.char(c)) end
  for c = 97, 122 do table.insert(charset, string.char(c)) end
end

local function randomString(length)
  if not length or length <= 0 then return '' end
  math.randomseed(os.time() * 10000)
  return randomString(length - 1) .. charset[math.random(1, #charset)]
end

local function Page(req, res)
  local cookieString = req.headers["cookie"]
  local sessionId = cookieString and cookieString:match("sessionId=([^;]+)")

  if not sessionId then
    local newCookieValue = randomString(32)
    res:setHeader("Set-Cookie",
      "sessionId="
      .. newCookieValue
      .. "; Expires="
      .. os.date("%a, %d %b %Y %X GMT", os.time() + 6000)
      .. "; HttpOnly")
    -- reset todos, counter
    todos = {}
    idCounter = 0
  end

  local html = page.Page(todos, filters)

  res:setHeader('Content-Type', 'text/html')
  res:setHeader('Content-Length', #html)
  res:finish(html)
end

local function NotFound(res)
  res.statusCode = 404
  res:setHeader('Content-Type', 'text/plain')
  res:finish('Not Found')
end

local function BadRequest(res)
  res.statusCode = 400
  res:setHeader('Content-Type', 'text/plain')
  res:finish('Bad Request')
end

http.createServer(function(req, res)
  -- p(req)
  local parsedUrl = url.parse(req.url, true)
  local path = parsedUrl.pathname
  if path == '/' then
    if req.method == 'GET' then
      Page(req, res)
    else
      BadRequest(res)
    end
  elseif path == '/set-hash' then
    SetHash(req, res)
    --
  elseif path == '/update-count' then
    UpdateCount(req, res)
  elseif path == '/toggle-all' then
    TodoToggleAll(req, res)
  elseif path == '/completed' then
    TodoCompleted(req, res)
  elseif path == '/footer' then
    Footer(req, res)
    --
  elseif path == '/add-todo' then
    AddTodo(req, res)
  elseif path == '/toggle-todo' then
    ToggleTodo(req, res)
  elseif path == '/edit-todo' then
    EditHandlerTodo(req, res)
  elseif path == '/update-todo' then
    UpdateTodo(req, res)
  elseif path == '/remove-todo' then
    RemoveTodo(req, res)
    --
  elseif path == '/toggle-main' then
    ToggleHandleMain(req, res)
  elseif path == '/toggle-footer' then
    ToggleHandleFooter(req, res)
  elseif path == '/todo-list' then
    TodoHandleList(req, res)
  elseif path == '/todo-json' then
    TodoJson(req, res)
  elseif path == '/swap-json' then
    SwapJson(req, res)
  elseif path == '/todo-item' then
    TodoHandleItem(req, res)
  else
    -- handle static files
    req.uri = url.parse(req.url)
    local filePath = '.' .. req.url
    local axecore = '.' .. '/cypress-example-todomvc' .. req.url
    fs.stat(filePath, function(err, stat)
      if err then
        -- handle axe core
        if filePath == './node_modules/axe-core/axe.min.js' then
          res:writeHead(200, {
            ["Content-Type"] = 'application/javascript',
          })

          return fs.createReadStream(axecore):pipe(res)
        elseif filePath == './learn.json' then
          res:writeHead(200, {
            ["Content-Type"] = 'application/json',
          })

          return fs.createReadStream(filePath):pipe(res)
        end
        return NotFound(res)
      end

      res:writeHead(200, {
        ["Content-Type"] = getType(filePath),
        ["Content-Length"] = stat.size
      })

      fs.createReadStream(filePath):pipe(res)
    end)
  end
end):listen(8888)

print('Server running at http://127.0.0.1:8888/\n Connect to server using a web browser.')
