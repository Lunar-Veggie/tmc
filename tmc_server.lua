tmc = {}

radiant.events.listen_once(tmc, 'radiant:init', function()
   stonehearth.game_master:_start_campaign('mythologies')
end)

return tmc