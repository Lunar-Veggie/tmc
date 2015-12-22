local AnimationComponent = class()

function AnimationComponent:initialize(entity, json)
   self._entity = entity
   self._soul_kill_listeners = {}
   self._sv = self.__saved_variables:get_data()

   if self._sv.soul_keepers then
      for id,soul_keeper in pairs(self._sv.soul_keepers) do
         self._soul_kill_listeners[id] = radiant.events.listen_once(soul_keeper, 'tmc:soul_keeper_destroyed', self, self._remove_soul_keeper)
      end
   end
end

function AnimationComponent:destroy()
   if self._kill_listener then
      self._kill_listener:destroy()
      self._kill_listener = nil
   end
   if self._soul_kill_listeners then
      for id,soul_kill_listener in pairs(self._soul_kill_listeners) do
         if soul_kill_listener then
            soul_kill_listener:destroy()
            self._soul_kill_listeners[id] = nil
         end
      end
   end
end

function AnimationComponent:set_soul_keepers(soul_keepers)
   self._sv.soul_keepers = soul_keepers

   for id,soul_kill_listener in pairs(self._soul_kill_listeners) do
      soul_kill_listener:destroy()
      soul_kill_listener = nil
   end
   self._soul_kill_listeners = {}

   if soul_keepers then
      for id,soul_keeper in pairs(soul_keepers) do
         self._soul_kill_listeners[id] = radiant.events.listen_once(soul_keeper, 'tmc:soul_keeper_destroyed', self, self._remove_soul_keeper)
      end
   end

   self.__saved_variables:mark_changed()
end

function AnimationComponent:_remove_soul_keeper(args)
   self._sv.soul_keepers[args.id] = nil

   if not self:_are_soul_keepers_left() then
      -- Setting the health of the entity to 0 will kill it and run the death effect
      self._entity:get_component('stonehearth:attributes')
                     :set_attribute('health', 0)
   end
end

function AnimationComponent:_are_soul_keepers_left()
   for id,soul_keeper in pairs(self._sv.soul_keepers) do
      if soul_keeper then
         -- As long as there's at least one soul keeper left; return true
         return true
      end
   end
   -- At this point there are no soul keepers left attached to this component
   return false
end

return AnimationComponent
