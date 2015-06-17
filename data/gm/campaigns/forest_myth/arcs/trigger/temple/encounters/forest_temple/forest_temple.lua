local rng = _radiant.csg.get_default_rng()
local ForestTempleScript = class()

function ForestTempleScript:start(ctx, info)
   assert(ctx.enemy_location and ctx.npc_player_id)
   ctx.forest_location = ctx.enemy_location
   ctx.forest_player_id = ctx.npc_player_id

   self:_setup_soul_connection(ctx)
end

function ForestTempleScript:_setup_soul_connection(ctx)
   -- Get a hold of all the entities which has the soul keeper component attached to them
   local soul_keepers = {}
   local index = 1
   for id,entity in pairs(ctx.forest_temple.entities) do

      if entity:get_component('tmc:soul_keeper') then
         soul_keepers[index] = entity
         index = index + 1
      end
   end

   -- Set all the guards to be connected to each soul keeper
   --TODO: perhaps some check to see if there are too many guards to assign to soul keepers, not needed now though.
   index = rng:get_int(1, #soul_keepers)
   for id,guard_entity in pairs(ctx.forest_temple.citizens.guards) do

      while not soul_keepers[index] do
         index = rng:get_int(1, #soul_keepers)
      end
      soul_keepers[index]:get_component('tmc:soul_keeper'):set_target_soul(guard_entity)
      soul_keepers[index] = nil
   end
end

return ForestTempleScript