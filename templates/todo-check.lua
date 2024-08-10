local module = {}

function module.TodoCheck(todo)
  return
    '<input class="toggle" type="checkbox" '
    ..  (todo.done and 'checked ' or '')
    ..  'hx-patch="' .. string.format('/toggle-todo?id=%s&done=%s', todo.id, todo.done) .. '" '
    ..  'hx-target="closest <li/>" '
    ..  'hx-swap="outerHTML" '
    ..  '_="install TodoCheck"'
    ..'/>'
end

return module