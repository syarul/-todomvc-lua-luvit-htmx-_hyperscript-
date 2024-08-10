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

function utility.count(todos)
  local count = 0
  for _, todo in pairs(todos) do
      count = count + 1
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

return utility