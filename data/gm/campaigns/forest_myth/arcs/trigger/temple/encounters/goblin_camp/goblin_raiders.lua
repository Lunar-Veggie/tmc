local GoblinRaiders = class()

function GoblinRaiders:initialize(piece)
   self._sv.piece = piece
   self.__saved_variables:mark_changed()
end

function GoblinRaiders:start(ctx, info)
   self._ctx = ctx
   self._info = info
   assert(ctx.npc_player_id and info.target_player_id)

   stonehearth.player:set_amenity(ctx.npc_player_id, info.target_player_id, 'hostile')
end

return GoblinRaiders