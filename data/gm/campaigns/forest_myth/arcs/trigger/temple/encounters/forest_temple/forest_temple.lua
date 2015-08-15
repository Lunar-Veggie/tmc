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
   -- Cache all of the entities that has a soul keeper component attached to them
   local soul_keepers = {}
   for _,forest_entities in pairs(ctx.forest_temple.entities) do

      -- We need to make sure that we're working with a table
      if type(forest_entities) ~= "table" then
         forest_entities = {forest_entities}
      end

      for id, entity in pairs(forest_entities) do

         local soul_keeper_comp = entity:get_component('tmc:soul_keeper')
         if soul_keeper_comp then
            soul_keeper_comp:set_id(id)
            soul_keepers[id] = entity
         end
      end
   end

   -- Set all the guards who have the animation component to be connected to every soul keeper
   for _,forest_citizens in pairs(ctx.forest_temple.citizens) do

      for _,citizens_type in pairs(forest_citizens) do

         for _,citizen in pairs(citizens_type) do

            local animation_comp = citizen:get_component('tmc:animation')
            if animation_comp then
               animation_comp:set_soul_keepers(soul_keepers)
            end
         end
      end
   end
end

return ForestTempleScript
