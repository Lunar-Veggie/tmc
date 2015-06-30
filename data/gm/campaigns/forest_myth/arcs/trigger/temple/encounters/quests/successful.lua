local Successful = class()

function Successful:initialize()
end

function Successful:restore()
end

function Successful:start(ctx, data)
   radiant.events.trigger_async(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', {successful = true})
end

return Successful