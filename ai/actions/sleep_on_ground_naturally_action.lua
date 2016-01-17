local SleepLib = radiant.mods.require('stonehearth.ai.lib.sleep_lib')

local SleepOnGroundNaturallyAction = class()

SleepOnGroundNaturallyAction.name = 'sleep on the ground just as well as anywhere else'
SleepOnGroundNaturallyAction.status_text_key = 'stonehearth:ai.actions.status_text.sleep_on_ground'
SleepOnGroundNaturallyAction.does = 'stonehearth:sleep_exhausted'
SleepOnGroundNaturallyAction.args = {}
SleepOnGroundNaturallyAction.version = 2
SleepOnGroundNaturallyAction.priority = 1

function SleepOnGroundNaturallyAction:run(ai, entity, args)
   ai:execute('stonehearth:drop_carrying_now')
   ai:execute('stonehearth:run_effect', { effect = 'yawn' })
   ai:execute('stonehearth:run_effect', { effect = 'sit_on_ground' })

   local sleep_duration, rested_sleepiness = SleepLib.get_sleep_parameters(entity, nil)
   ai:execute('stonehearth:run_sleep_effect', { duration_string = sleep_duration })
   radiant.entities.set_attribute(entity, 'sleepiness', rested_sleepiness)

   radiant.events.trigger_async(entity, 'stonehearth:sleep_on_ground')
end

return SleepOnGroundNaturallyAction
