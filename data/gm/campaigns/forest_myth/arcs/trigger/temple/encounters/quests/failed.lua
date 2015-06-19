local Failed = class()

function Failed:initialize()
end

function Failed:restore()
end

function Failed:start(ctx, data)
   radiant.events.trigger_async(ctx.forest_temple.boss, 'tmc:quest:finished', {successful = false})
end

return Failed