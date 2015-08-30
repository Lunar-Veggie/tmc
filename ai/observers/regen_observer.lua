local RegenObserver = class()

function RegenObserver:__init(entity)
end

function RegenObserver:initialize(entity)
   self._sv.entity = entity
   self._sv.hour_listener = stonehearth.calendar:set_interval("RegenObserver on_hourly", '1h', radiant.bind(self, '_on_hourly'))
end

function RegenObserver:restore()
end

function RegenObserver:activate()
   self._entity = self._sv.entity
   self._attributes_component = self._entity:add_component('stonehearth:attributes')
end

function RegenObserver:destroy()
   if self._sv.hour_listener then
      self._sv.hour_listener:destroy()
      self._sv.hour_listener = nil
   end
end

function RegenObserver:_on_hourly()
   local hp     = self._attributes_component:get_attribute('health')
   local max_hp = self._attributes_component:get_attribute('max_health')

   if hp == max_hp then
      return
   end

   hp = hp + tmc.constants.regen.HOURLY_HP_GAIN
   if hp > max_hp then
      hp = max_hp
   end

   self._attributes_component:set_attribute('health', hp)
end

return RegenObserver
