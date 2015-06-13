local DefenseQuest = class()

function DefenseQuest:initialize()
end

function DefenseQuest:restore()
end

function DefenseQuest:start(ctx, data)
   self._sv.player_id = ctx.player_id
   self._sv.defend_data = data

   self._sv.quest_complete_listener = radiant.events.listen_once(self ,'tmc:defense_quest:finished', self, self._quest_finished)
end

function DefenseQuest:_quest_finished(args)
   --args = {success = BOOLEAN}
   --if succeeded; get reward
end

return DefenseQuest