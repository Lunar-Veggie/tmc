local Point3 = _radiant.csg.Point3
local rng = _radiant.csg.get_default_rng()
local Mission = radiant.mods.require('stonehearth.services.server.game_master.controllers.missions.mission')
local PillageTarget = class()
radiant.mixin(PillageTarget, Mission)

function PillageTarget:initialize()
end

function PillageTarget:restore()
end

function PillageTarget:activate()
   Mission.activate(self)
   local party = self._sv.party
   if party then
      self._arrive_listener = radiant.events.listen(party, 'stonehearth:party:arrived_at_banner', function() self:_change_pillage_location() end)
   end
end

function PillageTarget:start(ctx, info)
   Mission.start(self, ctx, info)

   local party = self._sv.party
   assert(info.pillage_radius)
   assert(info.pillage_radius.min)
   assert(info.pillage_radius.max)
   assert(not self._arrive_listener)
   self._arrive_listener = radiant.events.listen(party, 'stonehearth:party:arrived_at_banner', function() self:_change_pillage_location() end)
   self:_change_pillage_location()
end

function PillageTarget:stop()
   Mission.stop(self)
   if self._arrive_listener then
      self._arrive_listener:destroy()
      self._arrive_listener = nil
   end
end

function PillageTarget:_change_pillage_location()
   local party = self._sv.party
   local origin = self._sv.ctx.forest_location
   local location, found
   local pillage_radius = self._sv.info.pillage_radius
   for i=1,10 do
      location, found = radiant.terrain.find_placement_point(origin, pillage_radius.min, pillage_radius.max)
      if found then
         break
      end
   end
   party:attack_move_to(location)
end

return PillageTarget