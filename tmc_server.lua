tmc = {constants = require('constants')}
local tmc_campaigns = {{type='mythologies', has_combat=true}}

local function start_campaign(campaign)
   if campaign.has_combat then
      -- This is a pretty ugly way to disable the campaign, but until Stonehearth makes it easier this will have to do.
      -- Could use Jelly, but should it be required just for this?
      radiant.events.listen_once(stonehearth.personality, 'stonehearth:journal_event', function(args)
         stonehearth.game_master:enable_campaign_type(campaign.type, not stonehearth.game_master._sv.disabled['combat'])
         stonehearth.game_master:_start_campaign(campaign.type)
      end)
   else
      stonehearth.game_master:_start_campaign(campaign.type)
   end
end

local function set_amenities(data)
   for first_player_id, amenities in pairs(data) do

      for amenity, second_player_ids in pairs(amenities) do

         for _, second_player_id in pairs(second_player_ids) do

            stonehearth.player:set_amenity(first_player_id, second_player_id, amenity)
         end
      end
   end
end

function tmc:_on_init()
   for _,campaign in pairs(tmc_campaigns) do
      start_campaign(campaign)
   end
   set_amenities(radiant.resources.load_json('tmc:kingdoms:amenities'))
end

radiant.events.listen_once(tmc, 'radiant:init', tmc, tmc._on_init)

return tmc
