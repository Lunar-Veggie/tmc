local NpcSpiritClass = class()
local job_helper = radiant.mods.require('stonehearth.jobs.job_helper')
local BaseJob = radiant.mods.require('stonehearth.jobs.base_job')
radiant.mixin(NpcSpiritClass, BaseJob)

function NpcSpiritClass:initialize(entity)
   job_helper.initialize(self._sv, nil)
   self._sv.no_levels = true
   self._sv.is_max_level = true
end

function NpcSpiritClass:create(entity)
   job_helper.initialize(self._sv, entity)
end

function NpcSpiritClass:restore()
end

function NpcSpiritClass:promote(json, options)
   job_helper.promote(self._sv, json)
   
   local player_id = radiant.entities.get_player_id(self._sv._entity)
   local population = stonehearth.population:get_population(player_id)
   -- upon promotion to worker, add to militia
   population:update_militia_command({}, {}, self._sv._entity:get_id(), true)

   self.__saved_variables:mark_changed()
end

function NpcSpiritClass:demote()
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

function NpcSpiritClass:has_perk(id)
   return false
end

return NpcSpiritClass
