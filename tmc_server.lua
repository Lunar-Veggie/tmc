tmc = {}

local function _set_amenities(data)

   for first_player_id, amenities in pairs(data) do

      for amenity, second_player_ids in pairs(amenities) do

         for _, second_player_id in pairs(second_player_ids) do

            stonehearth.player:set_amenity(first_player_id, second_player_id, amenity)
         end
      end
   end
end

radiant.events.listen_once(tmc, 'radiant:init', function()
   stonehearth.game_master:_start_campaign('mythologies')
   _set_amenities(radiant.resources.load_json('tmc:amenities'))
end)

return tmc