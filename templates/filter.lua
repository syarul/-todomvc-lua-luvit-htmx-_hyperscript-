local module = {}
local utility = require('utility')

function module.Filter(filters)
  return
      '<ul class="filters" _="on load set $filter to me">'
      .. table.concat(utility.map(filters, function(filter)
        return
          '<li>'
          ..  '<a '
          ..    (filter.selected and 'class="selected" ' or '')
          ..    'href="' .. filter.url .. '" '
          ..    '_="on click add .selected to me" '
          ..  '>'
          ..    filter.name
          ..  '</a>'
          ..'</li>'
      end), '\n')
      .. '</ul>'
end

return module