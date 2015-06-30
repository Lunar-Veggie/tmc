local rng = _radiant.csg.get_default_rng()
local ForestTempleScript = class()

function ForestTempleScript:start(ctx, info)
   self._sv.ctx = ctx
   assert(ctx.enemy_location and ctx.npc_player_id)
   ctx.forest_location = ctx.enemy_location
   ctx.forest_player_id = ctx.npc_player_id

   self:_setup_soul_connection(ctx)

   self.__saved_variables:mark_changed()
end

function ForestTempleScript:_setup_soul_connection(ctx)
   -- Get a hold of all the entities which has the soul keeper component attached to them
   local soul_keepers = {}
   for id,entity in pairs(ctx.forest_temple.entities) do

      if entity:get_component('tmc:soul_keeper') then
         entity:get_component('tmc:soul_keeper'):set_id(id)
         soul_keepers[id] = entity
      end
   end

   -- Set all the guards who have the animation component to be connected to every soul keeper
   for type,citizen_type in pairs(ctx.forest_temple.citizens) do

      for id,citizen in pairs(citizen_type) do

         local animation_comp = citizen:get_component('tmc:animation')
         if animation_comp then
            animation_comp:set_soul_keepers(soul_keepers)
         end
      end
   end
end

return ForestTempleScript