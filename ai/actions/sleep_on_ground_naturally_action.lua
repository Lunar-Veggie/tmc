local SleepOnGroundNaturally = class()
SleepOnGroundNaturally.name = 'sleep on the ground just as well as anywhere else'
SleepOnGroundNaturally.does = 'stonehearth:sleep_exhausted'
SleepOnGroundNaturally.args = {}
SleepOnGroundNaturally.version = 2
SleepOnGroundNaturally.priority = 1

function SleepOnGroundNaturally:run(ai, entity)
   ai:execute('stonehearth:drop_carrying_now')
   ai:execute('stonehearth:run_effect', {effect='yawn'})
   ai:execute('stonehearth:run_effect', {effect='sit_on_ground'})
   radiant.entities.add_buff(entity, 'stonehearth:buffs:sleeping');
   ai:execute('stonehearth:run_effect_timed', {effect='sleep', duration='2h'})
   radiant.entities.set_attribute(entity, 'sleepiness', stonehearth.constants.sleep.MIN_SLEEPINESS)
   radiant.events.trigger_async(entity, 'stonehearth:sleep_on_ground')
end

function SleepOnGroundNaturally:stop(ai, entity)
   local name = radiant.entities.get_display_name(entity)
   stonehearth.events:add_entry(name..' awakes from sleeping on the earth.', 'warning')
   radiant.entities.remove_buff(entity, 'stonehearth:buffs:sleeping');
end

return SleepOnGroundNaturally