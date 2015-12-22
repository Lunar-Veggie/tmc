local Point2 = _radiant.csg.Point2
local Point3 = _radiant.csg.Point3
local Stockpile = class()

function Stockpile:initialize(piece)
   self._sv.piece = piece
   self.__saved_variables:mark_changed()
end

function Stockpile:start(ctx, info)
   self._ctx  = ctx
   self._info = info

   assert(ctx.npc_player_id)
   assert(info.ctx_entity_registration_path and info.entity_name, "missing encounter info")

   local size = self._sv.piece.info.script_info.stockpile_size
   local stockpile_location = ctx.enemy_location + Point3(self._sv.piece.position.x-(size.w/2), 1, self._sv.piece.position.y-(size.h/2))
   local stockpile = self:_create_stockpile(stockpile_location, size.w, size.h)

   local ctx_encounter = ctx[info.ctx_entity_registration_path] or {}
   if not ctx_encounter.entities then
      ctx_encounter.entities = {}
   end

   ctx_encounter.entities[info.entity_name] = stockpile

   ctx[info.ctx_entity_registration_path] = ctx_encounter
end

function Stockpile:_create_stockpile(location, w, h)
   local stockpile = stonehearth.inventory:get_inventory(self._ctx.npc_player_id):create_stockpile(location, Point2(w,h))
   local contents = self._sv.piece.info.script_info.stockpile_contents

   if contents then
      local contents_amount = self._sv.piece.info.script_info.stockpile_contents_amount
      w = contents_amount and contents_amount.w or w-1
      h = contents_amount and contents_amount.h or h-1

      radiant.terrain.place_entity_cluster(contents, location, w, h)
   end
   return stockpile
end

return Stockpile
