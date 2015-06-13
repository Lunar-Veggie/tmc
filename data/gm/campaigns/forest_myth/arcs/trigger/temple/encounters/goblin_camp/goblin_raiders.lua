local GoblinRaiders = class()

function GoblinRaiders:initialize(piece)
   self._sv.piece = piece
   self.__saved_variables:mark_changed()
end

function GoblinRaiders:start(ctx, info)
   --TODO: have the goblins choose the forest camp location for raids
   self._ctx = ctx
   self._info = info
   assert(ctx.npc_player_id and info.target_player_id)
   assert(info.ctx_entity_registration_path and info.entity_name, "missing encounter info")

   stonehearth.player:set_amenity(ctx.npc_player_id, info.target_player_id, 'hostile')

   --local size = self._sv.piece.info.script_info.stockpile_size
   --local stockpile_location=ctx.enemy_location+Point3(self._sv.piece.position.x-(size.w/2),1,self._sv.piece.position.y-(size.h/2))
   --local stockpile=self:_create_stockpile(stockpile_location,size.w,size.h)

   local ctx_encounter = ctx[info.ctx_entity_registration_path] or {}
   if not ctx_encounter.entities then
      ctx_encounter.entities = {}
   end
   --ctx_encounter.entities[info.entity_name] = stockpile
end

return GoblinRaiders