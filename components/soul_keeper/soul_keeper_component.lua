local SoulKeeperComponent = class()

function SoulKeeperComponent:initialize(entity, json)
   self._entity = entity
   self._sv = self.__saved_variables:get_data()

   self._kill_listener = radiant.events.listen_once(entity, 'stonehearth:kill_event', self, self._on_kill_event)
   if self._sv.soul_entity then
      self._soul_kill_listener = radiant.events.listen_once(self._sv.soul_entity, 'radiant:entity:pre_destroy', self, self._remove_target_soul)
   end
end

function SoulKeeperComponent:destroy()
   if self._kill_listener then
      self._kill_listener:destroy()
      self._kill_listener = nil
   end
   if self._soul_kill_listener then
      self._soul_kill_listener:destroy()
      self._soul_kill_listener = nil
   end
end

function SoulKeeperComponent:_on_kill_event()
   if self._sv.soul_entity then
      -- Destroy the listener; it's not needed now
      self._soul_kill_listener:destroy()
      self._soul_kill_listener = nil

      -- Setting the health of the entity to 0 will kill it and run the death effect
      self._sv.soul_entity:get_component('stonehearth:attributes'):set_attribute('health', 0)
   end
end

function SoulKeeperComponent:set_target_soul(entity)
   if entity then
      self._soul_kill_listener = radiant.events.listen_once(entity, 'radiant:entity:pre_destroy', self, self._remove_target_soul)
   end
   self._sv.soul_entity = entity
   self.__saved_variables:mark_changed()
end

function SoulKeeperComponent:_remove_target_soul()
   self:set_target_soul(nil)
end

return SoulKeeperComponent