local entity_forms = radiant.mods.require('stonehearth.lib.entity_forms.entity_forms_lib')
local GoblinRaidersQuest = class()

function GoblinRaidersQuest:initialize()
end

function GoblinRaidersQuest:restore()
   self._quest_complete_listener = radiant.events.listen_once(self._sv.ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self._quest_finished)
end

function GoblinRaidersQuest:start(ctx, data)
   self._sv.ctx = ctx
   self._sv.quest_data = data

   self._quest_complete_listener = radiant.events.listen_once(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self._quest_finished)
end

function GoblinRaidersQuest:_quest_finished(args)
   if args.successful then
      self:_get_rewards(self._sv.quest_data.rewards)
   end
end

function GoblinRaidersQuest:_get_rewards(rewards)
   local ctx = self._sv.ctx
   local town = stonehearth.town:get_town(ctx.player_id)
   local inventory = stonehearth.inventory:get_inventory(ctx.player_id)
   local banner = town:get_banner()
   local drop_origin = banner and radiant.entities.get_world_grid_location(banner)
   if not drop_origin then
      return false
   end

   local items = radiant.entities.spawn_items(rewards, drop_origin, 1, 3, {owner=ctx.player_id})

   for _,item in pairs(items) do
      local root, iconic, _ = entity_forms.get_forms(item)
      if iconic then
         inventory:add_item(iconic)
      elseif root then
         inventory:add_item(root)
      end
   end
end

return GoblinRaidersQuest