--[[
This code were taken from Team Radiant from their file "wait_for_event_encounter.lua",
there are only a few changes made to reflect what was needed for this mod.

The difference here is that instead of waiting forever for the event(s) to occur,
it has a timer that, if expired, triggers different encounters instead.
--]]

local WaitForEventEncounter = radiant.mods.require('stonehearth.services.server.game_master.controllers.encounters.wait_for_event_encounter')
local WaitForEventTimed = class()
radiant.mixin(WaitForEventTimed, WaitForEventEncounter)

function WaitForEventTimed:initialize()
   self._sv.ctx        = nil
   self._sv.info       = nil
   self._sv.time_limit = nil
   self._sv.event      = nil
   self._sv.source     = nil
   self._sv.timer      = nil
   self._log = radiant.log.create_logger('game_master.wait_for_event_timed')
end

function WaitForEventTimed:start(ctx, info)
   local time_limit = info.time_limit
   local event      = info.event
   local source     = info.source

   assert(time_limit, '"time_limit" is not defined, consider using the provided "wait_for_event" encounter type instead')
   assert(event)
   assert(source)

   source = ctx:get(source)

   if type(source) == 'table' then
      if self:_check_sources_are_valid(source) then
         self._sv.ctx        = ctx
         self._sv.info       = info
         self._sv.time_limit = time_limit
         self._sv.source     = source
         self._sv.event      = event

         self:_listen_on_multiple_sources()
      end
   elseif source and source:is_valid() then
      self._sv.ctx        = ctx
      self._sv.info       = info
      self._sv.time_limit = time_limit
      self._sv.source     = source
      self._sv.event      = event

      self:_listen_for_event()
   end

   self._sv.timer = stonehearth.calendar:set_timer('WaitForEventTimed time_out', time_limit, function()
         self._sv.timer = nil
         self:_trigger_next_encounter(ctx, info.time_out_out_edge)
      end)

   self.__saved_variables:mark_changed()
end

local _old_stop = WaitForEventEncounter.stop
function WaitForEventTimed:stop()
   _old_stop(self)

   if self._sv.timer then
      self._sv.timer:destroy()
      self._sv.timer = nil
   end
end

function WaitForEventTimed:_listen_for_event()
   local event = self._sv.event
   local source = self._sv.source

   self._log:debug('listening for "%s" event on "%s"', event, tostring(source))
   self._listener = radiant.events.listen(source, event, function()
         local ctx = self._sv.ctx
         -- save location of the source when event occured
         ctx.source_location = source and radiant.entities.get_world_grid_location(source)
         self._log:debug('"%s" event on "%s" triggered!', tostring(source), event)
         self:_trigger_next_encounter(ctx, self._sv.info.events_met_out_edge)
      end)
end

function WaitForEventTimed:_listen_on_multiple_sources()
   local event = self._sv.event
   local sources = self._sv.source
   local num_sources = radiant.size(sources)
   local listeners_triggered = 0
   self._listeners = {}

   for _,source in pairs(sources) do
      self._log:debug('listening for "%s" event on "%s"', event, tostring(source))
      table.insert(self._listeners, radiant.events.listen(source, event, function()
         local ctx = self._sv.ctx
         self._log:debug('"%s" event on "%s" triggered!', tostring(source), event)
         listeners_triggered = listeners_triggered + 1
         if listeners_triggered == num_sources then
            self:_trigger_next_encounter(ctx, self._sv.info.events_met_out_edge)
         end
      end))
   end
end

function WaitForEventTimed:_trigger_next_encounter(ctx, out_edge)
   self:stop()
   self:_set_out_edge(ctx, out_edge)
   ctx.arc:trigger_next_encounter(ctx)
   self:_set_out_edge(ctx, nil)
end

function WaitForEventTimed:_set_out_edge(ctx, out_edge)
   ctx.encounter._sv._info.out_edge = out_edge
end

return WaitForEventTimed
