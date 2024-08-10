local module = {}

function module.EditTodo(todo)
  return
    '<input '
    .. 'class="edit" '
    .. 'name="title" '
    .. (todo.editing and string.format('value="%s" ', todo.title) or ' ')
    .. 'todo-id="' .. todo.id .. '" '
    .. '_="install TodoEdit"'
    .. '/>'
end

return module