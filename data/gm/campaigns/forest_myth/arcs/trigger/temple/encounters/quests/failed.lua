local Failed = class()

function Failed:initialize()
end

function Failed:restore()
end

function Failed:start(ctx, data)
   radiant.events.trigger_async(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', {successful = false})
end

return Failed
