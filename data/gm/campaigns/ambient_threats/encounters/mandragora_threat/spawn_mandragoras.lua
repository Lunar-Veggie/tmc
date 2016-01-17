local rng = _radiant.math.get_default_rng()
local Point3 = _radiant.csg.Point3
local SpawnMandragoras = class()

function SpawnMandragoras:initialize()
   self._sv.data     = nil
   self._sv.searcher = nil
end

function SpawnMandragoras:start(ctx, data)
   self._sv.data = data

   local min = data.spawn_range.min
   local max = data.spawn_range.max
   self._sv.searcher = radiant.create_controller('stonehearth:game_master:util:choose_location_outside_town', ctx.player_id, min, max, radiant.bind(self,'_spawn_mandragoras'))
end

local function _create_mandragoras(data)
   local min = data.spawn_amount.min or 1
   local max = data.spawn_amount.max or 1
   local num = rng:get_int(min, max)
   local mandragoras = {}

   for i=1, num do
      local mandragora = radiant.entities.create_entity(data.entity_uri, {owner=data.npc_player_id})
      table.insert(mandragoras, mandragora)
   end

   return mandragoras
end

function SpawnMandragoras:_spawn_mandragoras(op, location)
   local data = self._sv.data
   local mandragoras = _create_mandragoras(data)

   for id, mandragora in pairs(mandragoras) do

      -- Equip the mandragora
      if data.equipment then
         local ec = mandragora:add_component('stonehearth:equipment')
         for _,piece in pairs(data.equipment) do
            if type(piece) == 'table' then
               piece = piece[rng:get_int(1, #piece)]
            end
            ec:equip_item(piece)
         end
      end

      -- Add loot drops
      if data.loot_drops then
         mandragora:add_component('stonehearth:loot_drops'):set_loot_table(data.loot_drops)
      end
      -- Add combat leash range
      if data.combat_leash_range then
         mandragora:add_component('stonehearth:combat_state'):set_attack_leash(location, data.combat_leash_range)
      end
      -- Add some extra attributes
      if data.attributes then
         local attrib_component = mandragora:add_component('stonehearth:attributes')
         for name, value in pairs(data.attributes) do
            attrib_component:set_attribute(name, value)
         end
      end

      -- Set the location
      if data.location then
         local x = data.location.x or 0
         local y = data.location.y or 0
         local z = data.location.z or 0
         location = location + Point3(x, y, z)
         if data.range then
            location = radiant.terrain.find_placement_point(location, 1, data.range)
         end
      end
      -- Place the mandragora on the world
      radiant.terrain.place_entity(mandragora, location)
   end
end

return SpawnMandragoras
