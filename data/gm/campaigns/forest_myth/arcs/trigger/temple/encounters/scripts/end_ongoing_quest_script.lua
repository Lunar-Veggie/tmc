--[[
This code were taken from Team Radient from their file "destroy_entity_encounter.lua",
there are only a few changes made to reflect what was needed for this mod.

The difference here is that we're also triggering the event which ends any ongoing quest.
--]]

local Entity = _radiant.om.Entity
local rng    = _radiant.csg.get_default_rng()
local DestroyEntityCustom = class()

function DestroyEntityCustom:restore()
   radiant.events.listen_once(radiant, 'radiant:game_loaded',
      function(e)
         if self._sv.ctx and self._sv.info then
            self:_delete_everything(self._sv.ctx, self._sv.info)
         end
      end)
end

function DestroyEntityCustom:activate()
end

function DestroyEntityCustom:start(ctx, info)
   assert(info.target_entities)
   self._sv.num_destroyed = 0
   self._sv.ctx           = ctx
   self._sv.info          = info

   self:_delete_everything(ctx, info)

   if (info.continue_always or self._sv.num_destroyed > 0) and info.out_edge then
      -- Continue with the campaign
      local out_edge = info.out_edge

      if out_edge == 'arc:finish' then
         ctx.campaign:finish_arc(ctx)
         return
      end
      if type(out_edge) == 'string' then
         out_edge = {out_edge}
      end

      for _,edge in pairs(out_edge) do
         ctx.arc:spawn_encounter(ctx, edge)
      end
   end
end

function DestroyEntityCustom:_delete_everything(ctx, info)
   radiant.events.trigger(ctx.forest_temple.boss, 'tmc:forest_gm:quest:finished', {successful = false})

   for i,entity_name in ipairs(info.target_entities) do
      local delete_target = ctx:get(entity_name)
      self:_recursive_delete(delete_target, info)
   end
end

function DestroyEntityCustom:_recursive_delete(delete_target, info)
   if delete_target then
      if radiant.util.is_a(delete_target, Entity) then

         return self:_destroy_entity_with_effect(delete_target, info)
      elseif type(delete_target) == 'table' then

         for key, value in pairs(delete_target) do
            self:_recursive_delete(value, info)
         end
      end
   end
end

function DestroyEntityCustom:_destroy_entity_with_effect(entity, info)
   if entity:is_valid() then
      if info.effect then
         local proxy    = radiant.entities.create_entity(nil, {debug_text = 'running death effect'})
         local location = radiant.entities.get_world_grid_location(entity)

         radiant.terrain.place_entity(proxy, location)

         local effect = radiant.effects.run_effect(proxy, info.effect)
         effect:set_finished_cb(
            function()
               radiant.entities.destroy_entity(proxy)
               effect:set_finished_cb(nil)
               effect = nil
            end)
      end
      if info.random_delay then
         local delay = rng:get_int(info.random_delay.min, info.random_delay.min)

         stonehearth.calendar:set_timer(delay,
            function()
               if entity and entity:is_valid() then
                  radiant.entities.destroy_entity(entity)
               end
            end)
      else
         radiant.entities.destroy_entity(entity)
      end

      self._sv.num_destroyed = self._sv.num_destroyed + 1
   end
end

function DestroyEntityCustom:stop()
end

return DestroyEntityCustom
