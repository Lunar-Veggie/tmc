local game_master_lib = radiant.mods.require('stonehearth.lib.game_master.game_master_lib')
local Point3 = _radiant.csg.Point3
local GenerateCaptives = class()

function GenerateCaptives:create_piece(piece, ctx, info)
   self._ctx = ctx
   self._info = info

   local ctx_entity_registration_path = info.ctx_entity_registration_path
   local citizens_by_type = {}
   citizens_by_type[info.type] = {}
   local harpy_cages = {
      ctx[ctx_entity_registration_path].entities.harpy_cage_1,
      ctx[ctx_entity_registration_path].entities.harpy_cage_2,
      ctx[ctx_entity_registration_path].entities.harpy_cage_3
   }
   local location = info.from_population.location
   local population = stonehearth.population:get_population(info.captives_player_id)

   for id,harpy_cage in pairs(harpy_cages) do
      local cage_origin = radiant.entities.get_world_location(harpy_cage) + Point3(location.x, location.y, location.z)

      local harpies = game_master_lib.create_citizens(population, info, cage_origin, ctx)

      for _,harpy in pairs(harpies) do
         table.insert(citizens_by_type[info.type], harpy)

         if harpy and harpy:is_valid() then
            assert(harpy_cage and harpy_cage:is_valid())
            harpy:add_component('stonehearth:caged_entity'):set_cage(harpy_cage)
         end
      end
   end

   if ctx_entity_registration_path then
      game_master_lib.register_entities(ctx, ctx_entity_registration_path..'.citizens', citizens_by_type)
   end
end

return GenerateCaptives
