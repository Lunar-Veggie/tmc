local init_fn = function(entity)
   entity:add_component('stonehearth:equipment')
            :equip_item('tmc:air:harpy:talons')
end

return init_fn
