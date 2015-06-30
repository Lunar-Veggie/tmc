--[[
This code were taken from Team Radient from their file wait_for_event_encounter.lua,
there are only a few changes made to reflect what was needed for this mod.
--]]

local WaitForEvents = class()

function WaitForEvents:initialize()
   if self._sv.sources then
      self:_listen_for_events()
   end
end

function WaitForEvents:restore()
   if self._sv.sources then
      self:_listen_for_events()
   end
end

function WaitForEvents:start(ctx, info)
   local event    = info.event
   local out_edge = info.out_edge
   assert(info.sources)
   assert(event)
   assert(out_edge)

   local sources  = {}
   local is_valid = true

   for _,source in pairs(info.sources) do
      source = ctx:get(source)
      if not (source and source:is_valid()) then
         is_valid = false
      end
      table.insert(sources, source)
   end

   if is_valid then
      self._sv.ctx       = ctx
      self._sv.sources   = sources
      self._sv.event     = event
      self._sv.events_nr = #sources
      self._sv.out_edge  = out_edge
      self.__saved_variables:mark_changed()

      self:_listen_for_events()
   end
end

function WaitForEvents:_listen_for_events()
   local event   = self._sv.event
   local sources = self._sv.sources

   self._listeners = {}
   for _,source in pairs(sources) do
      table.insert(self._listeners, radiant.events.listen(source, event, self, self._event_sprung))
   end

   self._quest_listener = radiant.events.listen(self._sv.ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self._quest_done)
end

function WaitForEvents:_event_sprung()
   self._sv.events_nr = self._sv.events_nr - 1

   if self._sv.events_nr == 0 then
      -- Continue with the campaign
      local ctx = self._sv.ctx
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
   end

   self.__saved_variables:mark_changed()
end

function WaitForEvents:stop()
   if self._listeners then
      for id,listener in pairs(self._listeners) do
         listener:destroy()
         self._listeners[id] = nil
      end
   end
   if self._quest_listener then
      self._quest_listener:destroy()
      self._quest_listener = nil
   end
end

function WaitForEvents:_quest_done(args)
   if args.dryad_death then
      self:stop()
   end
end

return WaitForEvents