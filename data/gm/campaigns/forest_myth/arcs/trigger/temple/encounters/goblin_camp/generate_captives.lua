local game_master_lib = radiant.mods.require('stonehearth.lib.game_master.game_master_lib')
local Point3 = _radiant.csg.Point3
local GenerateCaptives = class()

function GenerateCaptives:initialize(piece)
   self._sv.piece = piece
   self.__saved_variables:mark_changed()
end

function GenerateCaptives:start(ctx, info)
   self._ctx = ctx
   self._info = info

   local citizens_by_type = {}

   local player_id = info.captives_player_id
   local piece_pos = self._sv.piece.position
   local location = info.from_population.location
   local population = stonehearth.population:get_population(player_id)
   local cage_origin = ctx.enemy_location + Point3(piece_pos.x, 0, piece_pos.y) + Point3(location.x, location.y, location.z)
   local ctx_entity_registration_path = info.ctx_entity_registration_path

   local harpies = game_master_lib.create_citizens(population, info, cage_origin, ctx)

   citizens_by_type[info.type] = harpies

   for _,harpy in pairs(harpies) do
      if harpy and harpy:is_valid() then
         assert(ctx.harpy_captives_camp.entities.harpy_cage and ctx.harpy_captives_camp.entities.harpy_cage:is_valid())
         harpy:add_component('stonehearth:caged_entity'):set_cage(ctx.harpy_captives_camp.entities.harpy_cage)
      end
   end

   if ctx_entity_registration_path then
      game_master_lib.register_entities(ctx, ctx_entity_registration_path..'.citizens', citizens_by_type)
   end
end

return GenerateCaptives