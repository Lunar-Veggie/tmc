local init_fn = function(entity)
   entity:add_component('stonehearth:equipment')
            :equip_item('tmc:forest:mandragora:voice')
end

return init_fn