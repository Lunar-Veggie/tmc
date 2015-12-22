local init_fn = function(entity)
   entity:add_component('stonehearth:equipment')
            :equip_item('tmc:forest:golem:stone_hands')
end

return init_fn
