local module = {}
local utility = require('utility')

function module.ClearCompleted(todos)
  local ct = utility.hasCompleteTask(todos)
  if ct then
    return
        '<button class="clear-completed" '
        .. '_="install ClearCompleted"'
        .. '>Clear completed</button>'
  end
  return '\n'
end

return module