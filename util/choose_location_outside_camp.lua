--[[
This code were taken from Team Radiant from their file "choose_location_outside_town.lua",
there are only a few changes made to reflect what was needed for this mod.

The differences are that instead of searching for a location relative to the player's location;
it attempts to find a location relative to a camp's location.
--]]

local rng     = _radiant.math.get_default_rng()
local Point3  = _radiant.csg.Point3
local Cube3   = _radiant.csg.Cube3
local Region2 = _radiant.csg.Region2
local Region3 = _radiant.csg.Region3

local ChooseLocationOutsideTown = radiant.mods.require('stonehearth.services.server.game_master.controllers.util.choose_location_outside_town')
local ChooseLocationOutsideCamp = class()
radiant.mixin(ChooseLocationOutsideCamp, ChooseLocationOutsideTown)

function ChooseLocationOutsideCamp:initialize()
   self._sv.camp_location  = nil
   self._sv.min_range      = nil
   self._sv.max_range      = nil
   self._sv.target_region  = nil
   self._sv.callback       = nil
   self._sv.slop_space     = 1
   self._sv.found_location = false
end

function ChooseLocationOutsideCamp:create(camp_location, min_range, max_range, callback, target_region) checks('self', 'Point3', 'number', 'number', 'binding')
   self._sv.camp_location = camp_location
   self._sv.min_range     = min_range
   self._sv.max_range     = max_range
   self._sv.target_region = target_region
   self._sv.callback      = callback
end

function ChooseLocationOutsideCamp:activate()
   self._log = radiant.log.create_logger('game_master.choose_location_outside_camp')
                              :set_prefix('choose loc outside cities and camps')

   self:_destroy_find_location_timer()

   if not self._sv.found_location then
      self._log:info('On Activate, try to find a location outside town!')
      self:_try_finding_location()
   end
end

function ChooseLocationOutsideCamp:_try_finding_location_thread()
   local camp_location = self._sv.camp_location

   local open   = {}
   local closed = Region3()

   local function visit_point(pt, add_to_open) checks('Point3', 'boolean')
      local key = pt:key_value()
      if not closed:contains(pt) then
         closed:add_point(pt)
         closed:optimize_by_merge('choose location outside town closed set')
         if add_to_open then
            self._log:info('adding point %s as a location', radiant.util.tostring(pt))
            table.insert(open, { location=pt, distance=pt:distance_to(camp_location) })
         end
      end
   end

   local function get_first_open_node()
      local best_id, best_node, best_distance

      for id, node in pairs(open) do
         if not best_distance or node.distance > best_distance then
            best_id, best_node, best_distance = id, node, node.distance
         end
      end

      if best_id then
         table.remove(open, best_id)
         return best_node
      end
   end

   -- Find a point differently here, since radiant's own method attempted to find a point relating to the player's position
   local point, found = radiant.terrain.find_placement_point(self._sv.camp_location, self._sv.min_range, self._sv.max_range)

   if found then
      visit_point(point, true)
   else
      visit_point(camp_location, true)
   end

   local d               = rng:get_int(self._sv.min_range, self._sv.max_range)
   local min_range       = d - self._sv.slop_space
   local max_range       = d + self._sv.slop_space
   local nodes_per_loop  = 10
   local nodes_processed = 0

   while #open > 0 do
      if nodes_processed >= nodes_per_loop then
         nodes_processed = 0
         coroutine.yield()
      end

      nodes_processed = nodes_processed + 1
      local node = get_first_open_node()

      if node.distance >= min_range then
         if self:_try_location(node.location) then
            return
         end
      end

      for y=-1, 1 do
         for x=-1, 1 do
            for z=-1, 1 do
               local next_pt = node.location + Point3(x,y,z)
               local add_to_open = false

               if node.distance < self._sv.max_range then
                  add_to_open = radiant.terrain.is_standable(next_pt)
               end

               visit_point(next_pt, add_to_open)
            end
         end
      end
   end

   self._log:info('failed to find location.  trying again')
   self:_try_later()
end

function ChooseLocationOutsideCamp:_try_later()
   self._sv.slop_space = self._sv.slop_space + 1
   self:_destroy_find_location_timer()

   self._find_location_timer = radiant.set_realtime_timer("ChooseLocationOutsideCamp try_later", 5000, function()
         self:_try_finding_location()
      end)
end

return ChooseLocationOutsideCamp
