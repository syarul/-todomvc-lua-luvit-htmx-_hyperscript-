local module = {}
local utility = require('utility')

function module.ToggleMain(todos)
  local checked = utility.defChecked(todos)
  if #todos ~= 0 then
    return
      '<section class="main" _="on load set $sectionMain to me">'
      ..  '<input id="toggle-all" class="toggle-all" type="checkbox" '
      ..    (checked and 'checked ' or '')
      ..    '_="install ToggleAll"'
      ..  '/>'
      ..  '<label for="toggle-all">'
      ..    'Mark all as complete'
      ..  '</label>'
      ..'</section>'
  else
    return '\n'
  end
end

return module