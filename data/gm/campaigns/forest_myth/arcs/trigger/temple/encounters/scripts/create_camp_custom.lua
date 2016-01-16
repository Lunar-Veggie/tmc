--[[
This code were taken from Team Radiant from their file "create_camp_encounter.lua",
there are only a few changes made to reflect what was needed for this mod.

The difference here is that we now create a camp relative to another camp
instead of relative to the player's location.
--]]

local build_util      = radiant.mods.require('stonehearth.lib.build_util')
local game_master_lib = radiant.mods.require('stonehearth.lib.game_master.game_master_lib')
local CreateCamp      = radiant.mods.require('stonehearth.services.server.game_master.controllers.encounters.create_camp_encounter')
local Point2          = _radiant.csg.Point2
local Point3          = _radiant.csg.Point3
local Rect2           = _radiant.csg.Rect2
local Cube3           = _radiant.csg.Cube3
local Region2         = _radiant.csg.Region2
local Region3         = _radiant.csg.Region3
local VISION_PADDING  = Point2(16, 16)
local log             = radiant.log.create_logger('game_master')

local CreateCampCustom = class()
radiant.mixin(CreateCampCustom, CreateCamp)

function CreateCampCustom:initialize()
   self._sv.ctx             = nil
   self._sv._info           = nil
   self._sv.camp_region     = nil
   self._sv.script          = nil
   self._sv.other_locations = nil
   self._sv.min_distance    = nil
   self._sv.out_edge        = nil
   self._sv.searcher        = nil
end

function CreateCampCustom:activate()
   self._log = radiant.log.create_logger('game_master.create_camp_script'):set_prefix('create camp')
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

   local min  = info.spawn_range.min
   local max  = info.spawn_range.max
   local cube = Cube3(Point3.zero, Point3.one)

   -- Get the location for the camp as the main location
   local camp_location = ctx:get(info.camp_location_ctx_path)

   -- Get the location for the player as the other location
   local player_banner   = stonehearth.town:get_town(ctx.player_id):get_banner()
   local banner_location = radiant.entities.get_world_grid_location(player_banner)
   local other_locations = {player_location = banner_location}

   cube = cube:inflated(Point3(info.radius, 0, info.radius))
   ctx.npc_player_id = info.npc_player_id

   self._sv.ctx             = ctx
   self._sv._info           = info
   self._sv.camp_region     = Region3(cube)
   self._sv.other_locations = other_locations
   self._sv.min_distance    = info.player_min_distance
   self._sv.out_edge        = info.out_edge
   self._sv.searcher        = radiant.create_controller('tmc:util:choose_location_outside_camp', camp_location, min, max, radiant.bind(self, '_choose_camp_cb'), self._sv.camp_region)
end

function CreateCampCustom:_test_camp(location, camp_region)
   -- First check if the location is at least the minimum distance from other_camps, return false if otherwise
   for _,other_location in pairs(self._sv.other_locations) do
      if location:distance_to(other_location) < self._sv.min_distance then
         return false
      end
   end

   -- check everything in the region and make sure we're ok to be here.
   -- we look 1 down, too, since we may end up sinking the camp.
   local query_region = Region3()
   query_region:copy_region(camp_region)
   query_region:add_region(camp_region:translated(-Point3.unit_y))

   local entities = radiant.terrain.get_entities_in_region(query_region)
   for id, entity in pairs(entities) do
      if self:_classify_entity_in_camp_region(id, entity) == 'invalid' then
         self._log:detail('%s inside potential camp location %s.  rejecting.', entity, location)
         return false
      end
   end
   return true
end

function CreateCampCustom:_create_camp(location, camp_region) checks('self', 'Point3', 'Region3')
   local ctx  = self._sv.ctx
   local info = self._sv._info
   assert(info.npc_player_id)

   ctx.enemy_location = location
   self._population   = stonehearth.population:get_population(info.npc_player_id)

   if info.amenity_with_player then
      stonehearth.player:set_amenity(info.npc_player_id, ctx.player_id, info.amenity_with_player)
   end

   local entities = radiant.terrain.get_entities_in_region(camp_region)
   for id, entity in pairs(entities) do
      if self:_classify_entity_in_camp_region(id, entity) == 'destroy' then
            radiant.entities.destroy_entity(entity)
      end
   end

   local kind = radiant.terrain.get_block_kind_at(location - Point3.unit_y)
   if kind == 'grass' and not self._sv._info.keep_grass then
      local terrain_region = camp_region:translated(-Point3.unit_y)
      radiant.terrain.subtract_region(terrain_region)
      location.y = location.y - Point3.unit_y.y
   end

   if info.created_bulletin then
      ctx.bulletin_data = info.created_bulletin
   end

   if info.boss then
      local members = game_master_lib.create_citizens(self._population, info.boss, ctx.enemy_location, ctx)

      if info.ctx_entity_registration_path then
         local boss_entity = members[1]
         if boss_entity then
            game_master_lib.register_entities(ctx, info.ctx_entity_registration_path, { boss=boss_entity })
         end
      end
   end

   local visible_rgn = Region2()
   for k, piece in pairs(info.pieces) do
      self:_add_piece(k, piece, visible_rgn)
   end

   stonehearth.terrain:get_explored_region(ctx.player_id)
                           :modify(function(cursor)
                                 cursor:add_region(visible_rgn)
                              end)

   if info.script then
      local script    = radiant.create_controller(info.script, ctx)
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

return CreateCampCustom
