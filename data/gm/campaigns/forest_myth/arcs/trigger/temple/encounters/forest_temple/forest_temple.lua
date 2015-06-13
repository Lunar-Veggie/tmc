local ForestTempleScript = class()

function ForestTempleScript:start(ctx, info)
	--error(string.format('encounter_name: %s', info.encounter_name or 'nil'))
	--local boss = ctx[info.encounter_name].npc_boss_entity
	--assert(boss and boss:is_valid())
end

function ForestTempleScript:_test()
end

return ForestTempleScript