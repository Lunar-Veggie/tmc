--[[
This code were taken from Team Radient from their file create_camp_encounter.lua,
there are only a few changes made to reflect what was needed for this mod.
--]]

local build_util       = radiant.mods.require('stonehearth.lib.build_util')
local game_master_lib  = radiant.mods.require('stonehearth.lib.game_master.game_master_lib')
local CreateCamp       = radiant.mods.require('stonehearth.services.server.game_master.controllers.encounters.create_camp_encounter')
local Point2           = _radiant.csg.Point2
local Point3           = _radiant.csg.Point3
local Rect2            = _radiant.csg.Rect2
local Cube3            = _radiant.csg.Cube3
local Region2          = _radiant.csg.Region2
local Region3          = _radiant.csg.Region3
local VISION_PADDING   = Point2(16, 16)
local log              = radiant.log.create_logger('game_master')
local CreateCampCustom = class()
radiant.mixin(CreateCampCustom, CreateCamp)

function CreateCampCustom:activate()
   self._log = radiant.log.create_logger('game_master.create_camp'):set_prefix('create camp')
end

function CreateCampCustom:initialize()
   self._log = radiant.log.create_logger('game_master.create_camp'):set_prefix('create camp')
end

function CreateCampCustom:restore()
end

function CreateCampCustom:start(ctx, info)
   assert(ctx)
   assert(info)
   assert(info.pieces)
   assert(info.npc_player_id)
   assert(info.camp_location_ctx_path)
   assert(info.spawn_range)
   assert(info.spawn_range.min)
   assert(info.spawn_range.max)
   assert(info.player_min_distance)

   local min                = info.spawn_range.min
   local max                = info.spawn_range.max
   local cube               = Cube3(Point3.zero, Point3.one)

   -- Get the location for the camp as the main location
   local camp_location      = ctx:get(info.camp_location_ctx_path)

   -- Get the location for the player as the other location
   local player_banner      = stonehearth.town:get_town(ctx.player_id):get_banner()
   local banner_location    = radiant.entities.get_world_grid_location(player_banner)
   local other_locations    = {player_location = banner_location}

   ctx.npc_player_id        = info.npc_player_id
   self._sv.ctx             = ctx
   self._sv.info            = info
   cube                     = cube:inflated(Point3(info.radius, 0, info.radius))
   self._sv.camp_region     = Region3(cube)
   self._sv.other_locations = other_locations
   self._sv.min_distance    = info.player_min_distance
   self._sv.out_edge        = info.out_edge

   self._sv.searcher        = radiant.create_controller('tmc:util:choose_location_outside_camp', camp_location, min, max, radiant.bind(self,'_choose_camp_cb'), self._sv.camp_region)
end

function CreateCampCustom:stop()
   if self._sv.searcher then
      self._sv.searcher:destroy()
      self._sv.searcher = nil
   end
end

function CreateCampCustom:_choose_camp_cb(op, location, camp_region) checks('self', 'string', 'Point3', 'Region3')
   if op == 'check_location' then
      return self:_test_camp(location, camp_region)
   elseif op == 'set_location' then
      return self:_create_camp(location, camp_region)
   else
      radiant.error('unknown op "%s" in choose camp callback', op)
   end
end

function CreateCampCustom:_test_camp(location, camp_region)
   -- First check if the location is at least the minimum distance from other_camps, return false if otherwise
   for _,other_location in pairs(self._sv.other_locations) do
      if location:distance_to(other_location) < self._sv.min_distance then
         return false
      end
   end

   -- Check if the position is valid and return that
   local query_region = Region3()
   query_region:copy_region(camp_region)
   query_region:add_region(camp_region:translated(-Point3.unit_y))

   local entities = radiant.terrain.get_entities_in_region(query_region)
   for id,entity in pairs(entities) do
      if self:_classify_entity_in_camp_region(id,entity) == 'invalid' then
         self._log:detail('%s inside potential camp location %s.  rejecting.', entity, location)
         return false
      end
   end
   return true
end

function CreateCampCustom:_classify_entity_in_camp_region(id, entity)
   if id == 1 then
      return 'ok'
   end
   if entity:get_component('item')
   or entity:get_component('stonehearth:resource_node')
   or entity:get_component('stonehearth:renewable_resource_node') then
      return 'destroy'
   end
   if entity:get_component('stonehearth:water')
   or entity:get_component('stonehearth:waterfall')
   or entity:get_component('stonehearth:mining_zone') then
      return 'invalid'
   end
   if build_util.get_building_for(entity) then
      return 'invalid'
   end
   if radiant.entities.is_solid_entity(entity) then
      return 'invalid'
   end
   return 'ok'
end

function CreateCampCustom:_create_camp(location, camp_region)
   checks('self', 'Point3', 'Region3')
   local ctx  = self._sv.ctx
   local info = self._sv.info
   assert(info.npc_player_id)

   ctx.enemy_location = location
   self._population   = stonehearth.population:get_population(info.npc_player_id)

   if info.amenity_with_player then
      stonehearth.player:set_amenity(info.npc_player_id,ctx.player_id,info.amenity_with_player)
   end

   local entities = radiant.terrain.get_entities_in_region(camp_region)
   for id,entity in pairs(entities) do
      if self:_classify_entity_in_camp_region(id, entity) == 'destroy' then
            radiant.entities.destroy_entity(entity)
      end
   end

   local kind = radiant.terrain.get_block_kind_at(location - Point3.unit_y)
   if kind == 'grass' and not self._sv.info.keep_grass then
      local terrain_region = camp_region:translated(-Point3.unit_y)
      radiant.terrain.subtract_region(terrain_region)
      location.y = location.y - Point3.unit_y.y
   end

   if info.boss then
      local members = game_master_lib.create_citizens(self._population, info.boss, ctx.enemy_location, ctx)

      if info.ctx_entity_registration_path then
         local boss_entity = members[1]
         if boss_entity then
            game_master_lib.register_entities(ctx, info.ctx_entity_registration_path, {boss=boss_entity})
         end
      end
   end

   local visible_rgn = Region2()
   for k,piece in pairs(info.pieces) do
      local uri  = piece.info
      piece.info = radiant.resources.load_json(uri)
      assert(piece.info.type == 'camp_piece', string.format('camp piece at "%s" does not have type == camp_piece', uri))

      self:_add_piece(piece,visible_rgn)
   end

   stonehearth.terrain:get_explored_region(ctx.player_id)
                        :modify(function(cursor)
      cursor:add_region(visible_rgn)
   end)

   if info.script then
      local script    = radiant.create_controller(info.script,ctx)
      self._sv.script = script
      script:start(ctx, info)
   end

   -- Continue with the campaign
   local out_edge = self._sv.out_edge

   if out_edge == 'arc:finish' then
      ctx.campaign:finish_arc(ctx)
      return
   end
   if type(out_edge) == 'string' then
      out_edge = {out_edge}
   end

   for _,edge in pairs(out_edge) do
      ctx.arc:spawn_encounter(ctx, edge)
   end

   radiant.events.trigger_async(ctx.encounter_name, 'stonehearth:create_camp_complete', {})

   radiant.events.trigger_async(ctx.forest_temple.boss, 'tmc:forest_gm:update_ctx', {quest_data = ctx[info.ctx_entity_registration_path]})
end

function CreateCampCustom:_add_piece(piece, visible_rgn)
   local x                            = piece.position.x
   local z                            = piece.position.y
   local rot                          = piece.rotation
   local ctx                          = self._sv.ctx
   local info                         = self._sv.info
   local player_id                    = info.npc_player_id
   local origin                       = ctx.enemy_location + Point3(x,0,z)
   local ctx_entity_registration_path = info.ctx_entity_registration_path
   local entities                     = {}

   if piece.info.entities then
      for name,info in pairs(piece.info.entities) do
         local entity = game_master_lib.create_entity(info, player_id)
         local offset = Point3(info.location.x, info.location.y, info.location.z)
         radiant.terrain.place_entity(entity, origin+offset, {force_iconic=info.force_iconic})
         if rot then
            radiant.entities.turn_to(entity,rot)
         end
         self:_add_entity_to_visible_rgn(entity,visible_rgn)
         entities[name] = entity
      end
   end

   if ctx_entity_registration_path then
      game_master_lib.register_entities(ctx, ctx_entity_registration_path..'.entities', entities)
   end

   local citizens_by_type = {}

   if piece.info.citizens then
      for type,info in pairs(piece.info.citizens) do
         local citizens = game_master_lib.create_citizens(self._population,info,origin,ctx)
         citizens_by_type[type] = citizens
         for i,citizen in ipairs(citizens) do
            self:_add_entity_to_visible_rgn(citizen,visible_rgn)
         end
      end
      if ctx_entity_registration_path then
         game_master_lib.register_entities(ctx, ctx_entity_registration_path..'.citizens', citizens_by_type)
      end
   end

   if piece.info.script then
      local script = radiant.create_controller(piece.info.script, piece)
      script:start(self._sv.ctx, piece.info.script_info)
   end
end

function CreateCampCustom:_add_entity_to_visible_rgn(entity, visble_rgn)
   local location = radiant.entities.get_world_grid_location(entity)
   local pt       = Point2(location.x, location.z)

   visble_rgn:add_cube(Rect2(pt-VISION_PADDING, pt+VISION_PADDING))

   local dst = entity:get_component('destination')
   if dst then
      self:_add_region_to_visble_rgn(entity, dst:get_region(), visble_rgn)
   end

   local rcs = entity:get_component('region_collision_shape')
   if rcs then
      self:_add_region_to_visble_rgn(entity, rcs:get_region(), visble_rgn)
   end

   local stockpile = entity:get_component('stockpile')
   if stockpile then
      local size = stockpile:get_size()
      visble_rgn:add_cube(Rect2(size-VISION_PADDING, size+VISION_PADDING))
   end
end

function CreateCampCustom:_add_region_to_visble_rgn(entity,rgn,visble_rgn)
   if not rgn then
      return
   end

   local world_rgn = radiant.entities.local_to_world(rgn:get(), entity)

   for cube in world_rgn:each_cube() do
      local min = Point2(cube.min.x, cube.min.z) - VISION_PADDING
      local max = Point2(cube.max.x, cube.max.z) + VISION_PADDING
      visble_rgn:add_cube(Rect2(min, max))
   end
end

return CreateCampCustom