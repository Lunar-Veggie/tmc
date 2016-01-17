local AreHostile = class()

function AreHostile:start(ctx, data)
   assert(data.npc_player_id)
   assert(data.out_edge)

   if stonehearth.player:are_player_ids_hostile(ctx.player_id, data.npc_player_id) then
      -- Continue with the campaign
      local out_edge = data.out_edge

      if out_edge == 'arc:finish' then
         ctx.campaign:finish_arc(ctx)
         return
      end
      if type(out_edge) == 'string' then
         out_edge = { out_edge }
      end
      
      for _,edge in pairs(out_edge) do
         ctx.arc:spawn_encounter(ctx, edge)
      end
   end
end

return AreHostile
