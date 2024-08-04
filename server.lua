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

local todos = {}

local idCounter = #todos

local filters = {
  { url = "#/",          name = "All",       selected = true },
  { url = "#/active",    name = "Active",    selected = false },
  { url = "#/completed", name = "Completed", selected = false },
}

local function map(a, fcn)
  local b = {}
  for _, v in ipairs(a) do
    table.insert(b, fcn(v))
  end
  return b
end

local function selectedFilter()
  for _, filter in ipairs(filters) do
    if filter.selected then
      return filter.name
    end
  end
  return 'All'
end

local function hasCompleteTask()
  for _, todo in ipairs(todos) do
    if todo.done then
      return true
    end
  end
  return false
end

local function countNotDone()
  local count = 0
  for _, todo in pairs(todos) do
    if not todo.done then
      count = count + 1
    end
  end
  return count
end

local function defChecked()
  local uncompletedCount = countNotDone()
  local defaultChecked = false
  if uncompletedCount == 0 and #todos > 0 then
    defaultChecked = true
  end
  return defaultChecked
end


local function unescape(str)
  return string.gsub(str, '^%s*(.-)%s*$', '%1')
end

function SetHash(req, res)
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

function AddTodo(req, res)
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
    html = TodoList()
  else
    local filterName = selectedFilter()
    html = TodoItem(newTodo, filterName)
  end

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function ToggleTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)
  local done = parsedUrl.query.done == 'true'

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      todo.done = not done
      local filterName = selectedFilter()
      html = TodoItem(todo, filterName)
      break
    end
  end

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function Footer(_, res)
  local completeTask = hasCompleteTask()
  local html = TodoFooter(completeTask)

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function UpdateCount(_, res)
  local uncompletedCount = countNotDone()
  local plural = ''
  if uncompletedCount ~= 1 then
    plural = 's'
  end

  local str = string.format('<strong>%s</strong> item%s left', uncompletedCount, plural)

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(str)
end

function TodoJson(_, res)
  res.statusCode = 200
  res:setHeader('Content-Type', 'application/json')
  res:finish(json.encode(todos))
end

function SwapJson(req, res)
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

function TodoCompleted(_, res)
  local hasCompleted = hasCompleteTask()
  local html = '\n' -- luvit won't send empty string to client which needed by htmx:afterRequest or /fetch
  if hasCompleted then
    html = ClearCompleted(hasCompleted)
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function TodoToggleAll(_, res)
  local checked = defChecked()

  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(tostring(checked))
end

function TodoHandleItem(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      local filterName = selectedFilter()
      html = TodoItem(todo, filterName)
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function EditHandlerTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)

  local html
  for _, todo in ipairs(todos) do
    if todo.id == id then
      html = EditTodo({ id = id, title = todo.title, done = false, editing = true })
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function UpdateTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)
  local title = parsedUrl.query.title

  local html = '\n' -- luvit won't send empty string to client which needed by htmx:afterRequest or /fetch
  for index, todo in ipairs(todos) do
    if todo.id == id then
      if title and title ~= '' then
        todo.title = unescape(title)
        local filterName = selectedFilter()
        html = TodoItem(todo, filterName)
      else
        table.remove(todos, index)
        index = index - 1 -- adjust index
      end
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function RemoveTodo(req, res)
  local parsedUrl = url.parse(req.url, true)
  local id = tonumber(parsedUrl.query.id)

  for index, todo in ipairs(todos) do
    if todo.id == id then
      table.remove(todos, index)
      index = index - 1 -- adjust index
      break
    end
  end
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish('\n')
end

function ToggleHandleMain(_, res)
  local html = ToggleMain()
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function ToggleHandleFooter(_, res)
  local ct = hasCompleteTask()
  local html = TodoFooter(ct)
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

function TodoHandleList(_, res)
  local html = TodoList()
  res.statusCode = 200
  res:setHeader('Content-Type', 'text/html')
  res:finish(html)
end

local completeTask = hasCompleteTask()

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

function Page(req, res)
  local cookieString = req.headers["cookie"]
  local sessionId = cookieString and cookieString:match("sessionId=(.-);")

  if not sessionId then
    local newCookieValue = randomString(32)
    res:setHeader("Set-Cookie",
      "sessionId=" .. newCookieValue .. "; Expires=" .. os.date("%a, %d %b %Y %X GMT", os.time() + 6000) .. "; HttpOnly")
    -- reset todos, counter
    todos = {}
    idCounter = 0
  end

  local html =
      '<html lang="en" data-framework="htmx">'
      .. '<head>'
      .. '  <meta charSet="utf-8" />'
      .. '  <title>HTMX • TodoMVC</title>'
      .. '  <link rel="stylesheet" href="https://unpkg.com/todomvc-common@1.0.5/base.css" type="text/css" />'
      .. '  <link rel="stylesheet" href="https://unpkg.com/todomvc-app-css/index.css" type="text/css" />'
      .. '  <script type="text/hyperscript" src="/hs/start-me-up._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/main._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/toggle-main._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/toggle-footer._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/toggle-show._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/add-todo._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/footer._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/toggle-all._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/clear-completed._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/destroy._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/todo-count._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/todo-dblclick._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/todo-check._hs"></script>'
      .. '  <script type="text/hyperscript" src="/hs/behaviors/todo-edit._hs"></script>'
      .. '</head>'
      .. '<body>'
      .. '  <section class="todoapp"'
      .. '    _="'
      .. '      install ToggleMain end\n'
      .. '      install ToggleFooter end\n'
      .. '      install ToggleShow end\n'
      .. '  ">'
      .. '    <header class="header">'
      .. '      <h1>todos</h1>'
      .. '      <input'
      .. '        id="add-todo"'
      .. '        name="title"'
      .. '        class="new-todo"'
      .. '        placeholder="What needs to be done?"'
      .. '        _="install AddTodo"'
      .. '      />'
      .. '    </header>'
      .. '' .. ToggleMain()
      .. '' .. TodoList()
      .. '' .. TodoFooter(completeTask)
      .. '  </section>'
      .. '  <footer class="info" '
      .. '     _="\n'
      .. '       on load debounced at 10ms\n'
      .. '          call startMeUp()\n'
      .. '          hashCache()\n'
      .. '  ">'
      .. '    <p>Double-click to edit a todo</p>'
      .. '    <p>Created by <a href="http://github.com/syarul/">syarul</a></p>'
      .. '    <p>Part of <a href="http://todomvc.com">TodoMVC</a></p>'
      .. '    <img src="https://htmx.org/img/createdwith.jpeg" width="250" height="auto" />'
      .. '  </footer>'
      .. '</body>'
      .. '<script src="https://unpkg.com/todomvc-common@1.0.5/base.js"></script>'
      .. '<script src="https://unpkg.com/htmx.org@1.9.10"></script>'
      .. '<script src="https://unpkg.com/hyperscript.org/dist/_hyperscript.js"></script>'
      .. '</html>'


  res:setHeader('Content-Type', 'text/html')
  res:setHeader('Content-Length', #html)
  res:finish(html)
end

function Filters()
  return
      '<ul class="filters" _="on load set $filter to me">'
      .. table.concat(map(filters, function(filter)
        return
            '<li>'
            .. '<a ' .. (filter.selected and 'class="selected" ' or '')
            .. 'href="' .. filter.url .. '" '
            .. '_="on click add .selected to me" '
            .. '>'
            .. filter.name
            .. '</a>'
            .. '</li>'
      end), '\n')
      .. '</ul>'
end

function ClearCompleted(ct)
  if ct then
    return
        '<button class="clear-completed" '
        .. '_="install ClearCompleted"'
        .. '>Clear completed</button>'
  end
  return '\n'
end

function TodoFooter(ct)
  if #todos ~= 0 then
    return
        '<footer class="footer" '
        .. '_="install Footer"'
        .. '>'
        .. '<span '
        .. '  class="todo-count"  '
        .. '  hx-trigger="load" '
        .. '  _="install TodoCount"'
        .. '></span>'
        .. Filters()
        .. ClearCompleted(ct)
        .. '</footer>'
  else
    return '\n'
  end
end

function TodoList()
  if #todos ~= 0 then
    local filterName = selectedFilter()
    return
        '<ul class="todo-list" _="on load set $todo to me">'
        .. table.concat(map(todos, function(todo)
          return TodoItem(todo, filterName)
        end), '\n')
        .. '</ul>'
  else
    return '\n'
  end
end

function TodoCheck(todo)
  return
      '<input '
      .. 'class="toggle" '
      .. 'type="checkbox" '
      .. (todo.done and 'checked ' or '')
      .. 'hx-patch="' .. string.format('/toggle-todo?id=%s&done=%s', todo.id, todo.done) .. '" '
      .. 'hx-target="closest <li/>" '
      .. 'hx-swap="outerHTML" '
      .. '_="install TodoCheck"'
      .. '/>'
end

function EditTodo(todo)
  return
      '<input '
      .. 'class="edit" '
      .. 'name="title" '
      .. (todo.editing and string.format('value="%s" ', todo.title) or ' ')
      .. 'todo-id="' .. todo.id .. '" '
      .. '_="install TodoEdit"'
      .. '/>'
end

function TodoItem(todo, filterName)
  if (not todo.done and filterName == "Active") or (todo.done and filterName == "Completed") or filterName == "All" then
    local id = string.format('todo-%s', todo.id)
    local classes = { "" }

    if todo.done then
      table.insert(classes, "completed")
    end

    if todo.editing then
      table.insert(classes, "editing")
    end

    return string.format(
      '<li id="%s" class="%s" _="on destroy my.querySelector(\'button\').click()">'
      .. '<div class="view">'
      .. '%s'
      ..
      '<label hx-trigger="dblclick" hx-patch="/edit-todo?id=%s" hx-target="next input" hx-swap="outerHTML" _="install TodoDblclick">%s</label>'
      ..
      '<button class="destroy" hx-delete="/remove-todo?id=%s" hx-trigger="click" hx-target="closest <li/>" hx-swap="outerHTML" _="install Destroy"/>'
      .. '</div>'
      .. '%s'
      .. '</li>',
      id, table.concat(classes, " "), TodoCheck(todo), todo.id, todo.title, todo.id, EditTodo(todo)
    )
  end
  return '\n'
end

function ToggleMain()
  local checked = defChecked()
  if #todos ~= 0 then
    return
        '   <section class="main" _="on load set $sectionMain to me">'
        .. '  <input id="toggle-all" class="toggle-all" type="checkbox"'
        .. '' .. (checked and ' checked' or '')
        .. '    _="install ToggleAll"'
        .. '  />'
        .. '  <label for="toggle-all">'
        .. '    Mark all as complete'
        .. '  </label>'
        .. '</section>'
  else
    return '\n'
  end
end

function NotFound(res)
  res.statusCode = 404
  res:setHeader('Content-Type', 'text/plain')
  res:finish('Not Found')
end

function BadRequest(res)
  res.statusCode = 400
  res:setHeader('Content-Type', 'text/plain')
  res:finish('Bad Request')
end

print('Server running at http://127.0.0.1:8888/\n Connect to server using a web browser.')
