local module = {}
local todoCheck = require('templates.todo-check')
local todoEdit = require('templates.todo-edit')

function module.TodoItem(todo, filterName)
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
      ..  '<div class="view">'
      ..     '%s'
      ..     '<label '
      ..       'hx-trigger="dblclick" '
      ..       'hx-patch="/edit-todo?id=%s" '
      ..       'hx-target="next input" '
      ..       'hx-swap="outerHTML" '
      ..       '_="install TodoDblclick"'
      ..     '>'
      ..       '%s'
      ..     '</label>'
      ..     '<button '
      ..       'class="destroy" '
      ..       'hx-delete="/remove-todo?id=%s" '
      ..       'hx-trigger="click" '
      ..       'hx-target="closest <li/>" '
      ..       'hx-swap="outerHTML" '
      ..       '_="install Destroy"'
      ..     '/>'
      ..  '</div>'
      ..  '%s'
      ..'</li>',
      id, table.concat(classes, " "), todoCheck.TodoCheck(todo), todo.id, todo.title, todo.id, todoEdit.EditTodo(todo)
    )
  end
  return '\n'
end

return module