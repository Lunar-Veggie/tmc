local SpiritClass = class()
local job_helper = radiant.mods.require('stonehearth.jobs.job_helper')

function SpiritClass:initialize(entity)
    job_helper.initialize(self._sv, entity)
    self:restore()
end

function SpiritClass:restore()
    self._job_component = self._sv._entity:get_component('stonehearth:job')
    if self._sv.is_current_class then
        self:_create_xp_listeners()
        self._sv.no_levels = true
    end

    self.__saved_variables:mark_changed()
end

function SpiritClass:promote(json, options)
    job_helper.promote(self._sv, json)
    self:_create_xp_listeners()

    self.__saved_variables:mark_changed()
end

function SpiritClass:demote()
    self:_remove_xp_listeners()
    self._sv.is_current_class = false

    self.__saved_variables:mark_changed()
end

function SpiritClass:get_job_level()
    return self._sv.last_gained_lv
end

function SpiritClass:is_max_level()
    return self._sv.is_max_level
end

function SpiritClass:get_level_data()
    return nil
end

function SpiritClass:unlock_perk(id)
    --self._sv.attained_perks[id] = true

    self.__saved_variables:mark_changed()
end

function SpiritClass:has_perk(id)
    return false
end

function SpiritClass:level_up()
    job_helper.level_up(self._sv)

    self.__saved_variables:mark_changed()
end

function SpiritClass:get_worker_defense_participation()
    return self._sv.worker_defense_participant
end

function SpiritClass:get_guardian_alias()
    return 'tmc:forest:golem'
end

function SpiritClass:has_guardian()
    --TODO: make better
    if not self._has_guardian then
        self._has_guardian = true
        return false
    end
    return true
end

function SpiritClass:_create_xp_listeners()
end

function SpiritClass:_remove_xp_listeners()
end

return SpiritClass