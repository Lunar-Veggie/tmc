--[[
This code were taken from Team Radient from their file "wait_encounter.lua",
there are only a few changes made to reflect what was needed for this mod.

The difference here is that we're listening in on the dryad;
if she dies then this stops prematurely.
--]]

local WaitToIssueQuest = class()

function WaitToIssueQuest:activate()
   self._log = radiant.log.create_logger('game_master.encounter.wait_to_issue_quest')

   if self._sv.timer then
      self._sv.timer:bind(
         function()
            self:_timer_callback()
         end)

      self._kill_listener = radiant.events.listen_once(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self.stop)
   end
end

function WaitToIssueQuest:start(ctx, info)
   assert(info.duration)

   local timeout  = info.duration
   local override = radiant.util.get_config('game_master.encounters.wait.duration')

   if override ~= nil then
      timeout = override
   end

   self._log:info('setting wait timer for %s', tostring(timeout))

   self._sv.ctx   = ctx
   self._sv.info  = info
   self._sv.timer = stonehearth.calendar:set_timer("WaitEncounterCustom wait timer", timeout, radiant.bind(self, '_timer_callback'))

   self._kill_listener = radiant.events.listen(ctx.forest_temple.boss, 'stonehearth:kill_event', self, self.stop)

   self._log:spam('Wait Encounter Custom: %s will expire at %s which is in %s', ctx.encounter_name, self._sv.timer:get_expire_time(), stonehearth.calendar:format_remaining_time(self._sv.timer))
   self._log:spam('It is currently %s', stonehearth.calendar:_debug_format_time())
end

function WaitToIssueQuest:_timer_callback()
   local ctx  = self._sv.ctx

   if self._sv.timer then
      self._sv.timer:destroy()
      self._sv.timer = nil
   end

   self._log:spam('Wait Encounter Custom: %s is now firing at %s', ctx.encounter_name, stonehearth.calendar:_debug_format_time())
   self.__saved_variables:mark_changed()

   -- Continue with the campaign
   local out_edge = self._sv.info.out_edge

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

function WaitToIssueQuest:stop()
   if self._kill_listener then
      self._kill_listener:destroy()
      self._kill_listener = nil
   end
   if self._sv.timer then
      self._sv.timer:destroy()
      self._sv.timer = nil
      self.__saved_variables:mark_changed()
   end
end

return WaitToIssueQuest
