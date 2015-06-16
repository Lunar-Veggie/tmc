local SetAmenities = class()

function SetAmenities:start(ctx, data)
   if data.friendly_to then
      for id,val in pairs(data.friendly_to) do
         stonehearth.player:set_amenity(data.npc_player_id, val, 'friendly')
      end
   end
   if data.neutral_to then
      for id,val in pairs(data.neutral_to) do
         stonehearth.player:set_amenity(data.npc_player_id, val, 'neutral')
      end
   end
   if data.hostile_to then
      for id,val in pairs(data.hostile_to) do
         stonehearth.player:set_amenity(data.npc_player_id, val, 'hostile')
      end
   end
end

return SetAmenities