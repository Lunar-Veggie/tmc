local RegenObserver = class()

function RegenObserver:initialize()
   self._sv.entity = nil
   self._sv.hour_listener = stonehearth.calendar:set_interval("RegenObserver on_hourly", '1h', function() self:_on_hourly() end)
end

function RegenObserver:create(entity)
   self._sv.entity = entity
end

function RegenObserver:restore()
end

function RegenObserver:activate()
   self._attributes_component = self._sv.entity:add_component('stonehearth:attributes')
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
