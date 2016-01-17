local Successful = class()

function Successful:start(ctx, data)
   radiant.events.trigger_async(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', {successful = true})
end

return Successful
