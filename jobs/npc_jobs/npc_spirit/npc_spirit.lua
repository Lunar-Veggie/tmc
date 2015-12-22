local NpcSpiritClass = class()
local job_helper = radiant.mods.require('stonehearth.jobs.job_helper')

function NpcSpiritClass:initialize(entity)
   job_helper.initialize(self._sv, entity)
   self:restore()
end

function NpcSpiritClass:restore()
   self._job_component = self._sv._entity:get_component('stonehearth:job')
   if self._sv.is_current_class then
      self:_create_xp_listeners()
      self._sv.no_levels = true
   end

   self.__saved_variables:mark_changed()
end

function NpcSpiritClass:promote(json, options)
   job_helper.promote(self._sv, json)
   self:_create_xp_listeners()

   self.__saved_variables:mark_changed()
end

function NpcSpiritClass:demote()
   self:_remove_xp_listeners()
   self._sv.is_current_class = false

   self.__saved_variables:mark_changed()
end

function NpcSpiritClass:get_job_level()
   return self._sv.last_gained_lv
end

function NpcSpiritClass:is_max_level()
   return self._sv.is_max_level
end

function NpcSpiritClass:get_level_data()
   return nil
end

function NpcSpiritClass:unlock_perk(id)
   --self._sv.attained_perks[id] = true

   self.__saved_variables:mark_changed()
end

function NpcSpiritClass:has_perk(id)
   return false
end

function NpcSpiritClass:level_up()
   job_helper.level_up(self._sv)

   self.__saved_variables:mark_changed()
end

function NpcSpiritClass:get_worker_defense_participation()
   return self._sv.worker_defense_participant
end

function NpcSpiritClass:_create_xp_listeners()
end

function NpcSpiritClass:_remove_xp_listeners()
end

return NpcSpiritClass