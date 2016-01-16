--[[
This code were taken from Team Radiant from their file "wait_for_event_encounter.lua",
there are only a few changes made to reflect what was needed for this mod.

The difference here is that the ctx is updated to contain the camps created
for future quests.
--]]

local WaitForEventUpdater = class()

function WaitForEventUpdater:initialize()
   self._sv.source   = nil
   self._sv.ctx      = nil
   self._sv.event    = nil
   self._sv.out_edge = nil
end

function WaitForEventUpdater:activate()
   self._log = radiant.log.create_logger('game_master.wait_for_event_script')

   if self._sv.source then
      self:_listen_for_event()
   end
end

function WaitForEventUpdater:start(ctx, info)
   local event    = info.event
   local source   = info.source
   local out_edge = info.out_edge

   assert(source)
   assert(event)
   assert(out_edge)

   source = ctx:get(source)
   if source and source:is_valid() then
      self._sv.ctx      = ctx
      self._sv.source   = source
      self._sv.event    = event
      self._sv.out_edge = out_edge
      self.__saved_variables:mark_changed()
      self:_listen_for_event()
   end
end

function WaitForEventUpdater:_listen_for_event()
   local event  = self._sv.event
   local source = self._sv.source
   local ctx = self._sv.ctx

   self._listener = radiant.events.listen(source, event, function()
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
   end)

   self._update_listener = radiant.events.listen(ctx.forest_temple.boss, 'tmc:forest_gm:update_ctx', self, self._update_ctx)
end

function WaitForEventUpdater:stop()
   if self._listener then
      self._listener:destroy()
      self._listener = nil
   end
   if self._update_listener then
      self._update_listener:destroy()
      self._update_listener = nil
   end
end

function WaitForEventUpdater:_update_ctx(args)
   assert(args.quest_data, 'missing data on quest')

   self._sv.ctx.quest_data = args.quest_data
   self.__saved_variables:mark_changed()
end

return WaitForEventUpdater
