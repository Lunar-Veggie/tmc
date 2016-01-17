--[[
This script reflects Team Radiant's "destroy_entity_encounter.lua",
The difference here is that we're also triggering the event which ends any ongoing quest.
--]]

local Entity = _radiant.om.Entity
local rng    = _radiant.math.get_default_rng()
local log    = radiant.log.create_logger('game_master.end_ongoing_quest')

local DestroyEntityEncounter = radiant.mods.require('stonehearth.services.server.game_master.controllers.encounters.destroy_entity_encounter')
local DestroyEntityCustom = class()
radiant.mixin(DestroyEntityCustom, DestroyEntityEncounter)

local _old_delete_everything = DestroyEntityEncounter._delete_everything
function DestroyEntityCustom:_delete_everything(ctx, info)
   radiant.events.trigger(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', { successful = false })

   _old_delete_everything(self, ctx, info)
end

return DestroyEntityCustom
