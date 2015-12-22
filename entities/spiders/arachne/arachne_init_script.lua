local init_fn = function(entity)
   entity:add_component('stonehearth:equipment')
            :equip_item('tmc:spiders:arachne:scythe')
end

return init_fn
