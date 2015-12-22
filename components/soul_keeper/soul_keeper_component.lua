local SoulKeeperComponent = class()

function SoulKeeperComponent:initialize(entity, json)
   self._entity = entity
   self._sv = self.__saved_variables:get_data()

   self._kill_listener = radiant.events.listen_once(entity, 'stonehearth:kill_event', self, self._on_kill_event)
end

function SoulKeeperComponent:destroy()
   self._kill_listener:destroy()
   self._kill_listener = nil
end

function SoulKeeperComponent:set_id(id)
   self._sv.id = id
   self.__saved_variables:mark_changed()
end

function SoulKeeperComponent:_on_kill_event()
   radiant.events.trigger(self._entity, 'tmc:soul_keeper_destroyed', {id = self._sv.id})
end

return SoulKeeperComponent
