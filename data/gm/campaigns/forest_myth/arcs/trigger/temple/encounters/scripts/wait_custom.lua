--[[
This code were taken from Team Radient from their file "wait_encounter.lua",
there are only a few changes made to reflect what was needed for this mod.
--]]

local WaitCustom = class()

function WaitCustom:activate()
   self._log = radiant.log.create_logger('game_master_encounter')

   if self._sv.timer then
      self._sv.timer:bind(
         function()
            self:_timer_callback()
         end)

      self._quest_listener = radiant.events.listen_once(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self.stop)
   end
end

function WaitCustom:start(ctx, info)
   assert(info.duration)
   local timeout  = info.duration
   local override = radiant.util.get_config('game_master.encounters.wait.duration')

   if override ~= nil then
      timeout = override
   end

   self._log:info('setting wait timer for %s', tostring(timeout))

   self._sv.ctx   = ctx
   self._sv.info  = info
   self._sv.timer = stonehearth.calendar:set_timer(timeout,
      function()
         self:_timer_callback()
      end)

   self._quest_listener = radiant.events.listen(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self._quest_done)

   self._log:spam('Wait Encounter: %s will expire at %s which is in %s', ctx.encounter_name, self._sv.timer:get_expire_time(), stonehearth.calendar:format_remaining_time(self._sv.timer))
   self._log:spam('It is currently %s', stonehearth.calendar:format_time())
end

function WaitCustom:_timer_callback()
   local ctx  = self._sv.ctx

   if self._sv.timer then
      self._sv.timer:destroy()
      self._sv.timer = nil
   end

   self._log:spam('Wait Encounter: %s is now firing at %s', ctx.encounter_name, stonehearth.calendar:format_time())
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

function WaitCustom:stop()
   if self._quest_listener then
      self._quest_listener:destroy()
      self._quest_listener = nil
   end
   if self._sv.timer then
      self._sv.timer:destroy()
      self._sv.timer = nil
      self.__saved_variables:mark_changed()
   end
end

function WaitCustom:_quest_done(args)
   if args.dryad_death then
      self:stop()
   end
end

function WaitCustom:get_progress_cmd(session, response)
   local progress = {}
   if self._sv.timer then
      progress.time_left = stonehearth.calendar:format_remaining_time(self._sv.timer)
   end
   return progress;
end

function WaitCustom:trigger_now_cmd(session, response)
   local ctx = self._sv.ctx
   self._log:info('triggering now as requested by ui')

   if self._sv.timer then
      self._sv.timer:destroy()
      self._sv.timer = nil
      self.__saved_variables:mark_changed()
   end

   ctx.arc:trigger_next_encounter(ctx)

   return true
end

return WaitCustom