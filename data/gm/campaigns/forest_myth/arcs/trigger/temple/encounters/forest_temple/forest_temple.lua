local ForestTempleScript = class()

function ForestTempleScript:start(ctx, info)
   assert(ctx.enemy_location)
   ctx.forest_location = ctx.enemy_location
end

return ForestTempleScript