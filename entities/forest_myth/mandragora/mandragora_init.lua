local init_fn = function(entity)
   entity:add_component('stonehearth:equipment'):equip_item('scenario_ex:mandragora:voice')
end

return init_fn