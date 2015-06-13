local GuardianClass = class()
local job_helper = radiant.mods.require('stonehearth.jobs.job_helper')

function GuardianClass:initialize(entity)
    job_helper.initialize(self._sv, entity)
    self:restore()
end

function GuardianClass:restore()
    self._job_component = self._sv._entity:get_component('stonehearth:job')
    if self._sv.is_current_class then
        self:_create_xp_listeners()
        self._sv.no_levels = true
    end

    self.__saved_variables:mark_changed()
end

function GuardianClass:promote(json, options)
    job_helper.promote(self._sv, json)
    self:_create_xp_listeners()

    self.__saved_variables:mark_changed()
end

function GuardianClass:demote()
    self:_remove_xp_listeners()
    self._sv.is_current_class = false

    self.__saved_variables:mark_changed()
end

function GuardianClass:get_job_level()
    return self._sv.last_gained_lv
end

function GuardianClass:is_max_level()
    return self._sv.is_max_level
end

function GuardianClass:get_level_data()
    return self._sv.level_data
end

function GuardianClass:unlock_perk(id)
    self._sv.attained_perks[id] = true

    self.__saved_variables:mark_changed()
end

function GuardianClass:get_worker_defense_participation()
    return self._sv.worker_defense_participant
end

function GuardianClass:has_perk(id)
    return self._sv.attained_perks[id]
end

function GuardianClass:level_up()
    job_helper.level_up(self._sv)

    self.__saved_variables:mark_changed()
end

function GuardianClass:_create_xp_listeners()
    --self._on_attack = radiant.events.listen(self._sv._entity, 'stonehearth:combat:begin_melee_attack', self, self._on_attack)
    --self._on_damage_dealt = radiant.events.listen(self._sv._entity, 'stonehearth:combat:melee_attack_connect', self, self._on_damage_dealt)
end

function GuardianClass:_remove_xp_listeners()
    --self._on_attack:destroy()
    --self._on_attack = nil
    --self._on_damage_dealt:destroy()
    --self._on_damage_dealt = nil
end

function GuardianClass:_on_attack(args)
end

function GuardianClass:_on_damage_dealt(args)
    local exp = 0
    if not args.target_exp then
        exp = self._sv.xp_rewards['base_exp_per_hit']
    else
        exp = args.target_exp
    end
    self._job_component:add_exp(exp)
end

function GuardianClass:apply_chained_buff(args)
    radiant.entities.remove_buff(self._sv._entity, args.last_buff)
    radiant.entities.add_buff(self._sv._entity, args.buff_name)
end

function GuardianClass:apply_buff(args)
    radiant.entities.add_buff(self._sv._entity, args.buff_name)
end

function GuardianClass:remove_buff(args)
    radiant.entities.remove_buff(self._sv._entity, args.buff_name)
end

function GuardianClass:add_combat_action(args)
    job_helper.add_equipment(self._sv, args)
    local combat_state = stonehearth.combat:get_combat_state(self._sv._entity)
    combat_state:recompile_combat_actions(args.action_type)
end

function GuardianClass:remove_combat_action(args)
    job_helper.remove_equipment(self._sv, args)
    local combat_state = stonehearth.combat:get_combat_state(self._sv._entity)
    combat_state:recompile_combat_actions(args.action_type)
end

function GuardianClass:set_guarded(guarded_entity)
    self._sv.guarded_entity = guarded_entity
end

function GuardianClass:get_guarded()
    return self._sv.guarded_entity
end

return GuardianClass