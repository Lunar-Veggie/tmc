local entity_forms = radiant.mods.require('stonehearth.lib.entity_forms.entity_forms_lib')
local RescueHarpiesQuest = class()

function RescueHarpiesQuest:initialize()
end

function RescueHarpiesQuest:restore()
   self._quest_complete_listener = radiant.events.listen_once(self._sv.ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self._quest_finished)
end

function RescueHarpiesQuest:start(ctx, data)
   self._sv.ctx = ctx
   self._sv.quest_data = data

   self._sv.prev_captive_and_player_amenity = self:_get_amenity(data.captives_player_id, ctx.player_id)

   stonehearth.player:set_amenity(data.captives_player_id, data.npc_player_id, 'neutral')
   stonehearth.player:set_amenity(data.captives_player_id, ctx.player_id,      'neutral')

   self._quest_complete_listener = radiant.events.listen_once(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', self, self._quest_finished)

   self.__saved_variables:mark_changed()
end

function RescueHarpiesQuest:stop()
   if self._quest_complete_listener then
      self._quest_complete_listener:destroy()
      self._quest_complete_listener = nil
   end
end

function RescueHarpiesQuest:_get_amenity(player_id_a, player_id_b)
   local player_service = stonehearth.player

   if player_service:are_players_hostile(player_id_a, player_id_b) then
      return 'hostile'
   elseif player_service:are_players_friendly(player_id_a, player_id_b) then
      return 'friendly'
   else
      return 'neutral'
   end
end

function RescueHarpiesQuest:_quest_finished(args)
   local ctx  = self._sv.ctx
   local data = self._sv.quest_data

   if args.successful then
      self:_get_rewards(data.rewards)
      stonehearth.player:set_amenity(data.captives_player_id, ctx.player_id, 'neutral')
   else
      stonehearth.player:set_amenity(data.captives_player_id, ctx.player_id, self._sv.prev_captive_and_player_amenity)
   end
   stonehearth.player:set_amenity(data.captives_player_id, data.npc_player_id, 'hostile')
end

function RescueHarpiesQuest:_get_rewards(rewards)
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

return RescueHarpiesQuest
