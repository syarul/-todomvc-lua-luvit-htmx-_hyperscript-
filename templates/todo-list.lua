local module = {}
local utility = require('utility')
local todoItem = require('templates.todo-item')

function module.TodoList(todos, filters)
  if #todos ~= 0 then
    local filterName = utility.selectedFilter(filters)
    return
        '<ul class="todo-list" _="on load set $todo to me">'
        .. table.concat(utility.map(todos, function(todo)
          return todoItem.TodoItem(todo, filterName)
        end), '\n')
        .. '</ul>'
  else
    return '\n'
  end
end

return module