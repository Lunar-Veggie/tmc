local IsHostile = class()

function IsHostile:initialize(piece)
   self._sv.piece = piece
   self.__saved_variables:mark_changed()
end

function IsHostile:start(ctx, data)
   assert(data.npc_player_id)
   assert(data.out_edge)

   if stonehearth.player:are_players_hostile(ctx.player_id, data.npc_player_id) then
      -- Continue with the campaign
      local out_edge = data.out_edge

      if out_edge == 'arc:finish' then
         ctx.campaign:finish_arc(ctx)
         return
      end
      if type(out_edge) == 'string' then
         out_edge = {out_edge}
      end
      
      for _,edge in pairs(out_edge) do
         ctx.arc:spawn_encounter(ctx, edge)
      end
   end
end

return IsHostile
