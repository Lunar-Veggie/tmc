local GoblinRaiders = class()

function GoblinRaiders:start(ctx, info)
   assert(ctx.npc_player_id and ctx.forest_player_id)

   stonehearth.player:set_amenity(ctx.npc_player_id, ctx.forest_player_id, 'hostile')
end

return GoblinRaiders