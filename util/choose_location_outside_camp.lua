--[[
This code were taken from Team Radient from their file choose_location_outside_town.lua,
there are only a few changes made to reflect what was needed for this mod.
--]]

local rng                       = _radiant.math.get_default_rng()
local Point3                    = _radiant.csg.Point3
local Cube3                     = _radiant.csg.Cube3
local Region2                   = _radiant.csg.Region2
local Region3                   = _radiant.csg.Region3
local ChooseLocationOutsideCamp = class()

function ChooseLocationOutsideCamp:initialize(camp_location, min_range, max_range, callback, target_region) checks('self', 'Point3', 'number', 'number', 'binding')
   self._sv.camp_location  = camp_location
   self._sv.min_range      = min_range
   self._sv.max_range      = max_range
   self._sv.target_region  = target_region
   self._sv.callback       = callback
   self._sv.slop_space     = 1
   self._sv.found_location = false
end

function ChooseLocationOutsideCamp:activate()
   self._log = radiant.log.create_logger('game_master.choose_location_outside_towns')
                              :set_prefix('choose loc outside cities and camps')

   self:_destroy_find_location_timer()

   if not self._sv.found_location then
      self:_try_finding_location()
   end
end

function ChooseLocationOutsideCamp:_try_finding_location()
   self._job = radiant.create_background_task('choose location outside town', function() self:_try_finding_location_thread() end)
end

function ChooseLocationOutsideCamp:_try_finding_location_thread()
   local camp_location = self._sv.camp_location
   local open          = {}
   local closed        = Region3()

   local function visit_point(pt, add_to_open) checks('Point3', 'boolean')

      local key = pt:key_value()

      if not closed:contains(pt) then
         closed:add_point(pt)
         closed:optimize_by_merge('choose location outside town closed set')
         if add_to_open then
            self._log:info('adding point %s as a location', radiant.util.tostring(pt))
            table.insert(open, {location=pt, distance=pt:distance_to(camp_location)})
            return true
         end
      end

      return false
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

function ChooseLocationOutsideCamp:_try_location(location)
   local camp_region

   if self._sv.target_region then
      camp_region        = self._sv.target_region:translated(location)
      local intersection = radiant.terrain.intersect_region(camp_region)

      if not intersection:empty() then
         self._log:info('location %s intersects terrain (intersection:%s).  trying again', location, intersection:get_bounds())
         return false
      end

      intersection = radiant.terrain.intersect_region(camp_region:translated(-Point3.unit_y))
      if intersection:get_area() ~= camp_region:get_area() then
         self._log:info('location %s not flat.  trying again (supported area:%d   test area:%d)', location, intersection:get_area(), camp_region:get_area())
         return false
      end

      if self._sv.callback then
         if not radiant.invoke(self._sv.callback, 'check_location', location, camp_region) then
            return false
         end
      end
   end

   self._log:info('found location %s', location)
   self:_finalize_location(location, camp_region)
   return true
end

function ChooseLocationOutsideCamp:_finalize_location(location, camp_region)
   self:_destroy_find_location_timer()
   self._sv.found_location = true
   self.__saved_variables:mark_changed()

   if self._sv.callback then
      radiant.invoke(self._sv.callback, 'set_location', location, camp_region)
      self._sv.callback = nil
   end
end

function ChooseLocationOutsideCamp:_destroy_find_location_timer()
   if self._find_location_timer then
      self._find_location_timer:destroy()
      self._find_location_timer = nil
   end
end

function ChooseLocationOutsideCamp:_try_later()
   self._sv.slop_space = self._sv.slop_space + 1
   self:_destroy_find_location_timer()

   self._find_location_timer = radiant.set_realtime_timer("ChooseLocationOutsideCamp try_later", 5000, function() self:_try_finding_location() end)
end

return ChooseLocationOutsideCamp