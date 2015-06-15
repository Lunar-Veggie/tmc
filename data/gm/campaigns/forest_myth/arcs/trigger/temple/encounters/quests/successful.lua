local Successful = class()

function Successful:initialize()
end

function Successful:restore()
end

function Successful:start(ctx, data)
   radiant.events.trigger_async(ctx.forest_temple.boss, 'tmc:quest:finished', {successful = true})
end

return Successful