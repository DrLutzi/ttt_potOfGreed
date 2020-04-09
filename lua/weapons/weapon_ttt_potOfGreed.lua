if SERVER then
   AddCSLuaFile()
end

if CLIENT then
   SWEP.PrintName = "Pot of greed"
   SWEP.Slot      = 7 -- add 1 to get the slot number key
end

SWEP.Base				= "weapon_tttbase"

SWEP.Kind = WEAPON_EQUIP1

SWEP.CanBuy = { ROLE_TRAITOR, ROLE_DETECTIVE }
SWEP.InLoadoutFor = nil
SWEP.LimitedStock = true

if CLIENT then
   -- Path to the icon material
   SWEP.Icon = "vgui/ttt/icon_ttt_potOfGreed"

   -- Text shown in the equip menu
   SWEP.EquipMenuData = {
      type = "RNG item",
      desc = "This traitor item allows you to draw two random traitor items. Make sure to empty your pockets before using this item, or you might not get everything!"
   };
end

-- Tell the server that it should download our icon to clients.
if SERVER then
   -- It's important to give your icon a unique name. GMod does NOT check for
   -- file differences, it only looks at the name. This means that if you have
   -- an icon_ak47, and another server also has one, then players might see the
   -- other server's dumb icon. Avoid this by using a unique name.
   resource.AddFile("materials/vgui/ttt/icon_ttt_potOfGreed.vmt")
end

-- ConVar stuff
if SERVER then
	local conVars = {}
	conVars.nbItemsToGive = CreateConVar(	"ttt_potOfGreed_nbItemsToGive", "2", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 
											"Determines the number of random items given by the item ttt_potOfGreed.",
											1, nil)
	--	Conflict policy: determines what to do when an item received takes the same slot as an item is already in the inventory.
	--	So far, the conflict policy for items of slot number >6 is 0 unless specified otherwise. 
	--	The ideal is to buy the pot of greed first if you want it, so you don't lose items!
	--		0 - do nothing. The new item is lost.
	--		1 - override the current item. The user may still lose items if several items taking the same slot are obtained.
	--		2 - override the current item, and prevent next given items from overriding this new item.
	--		3 - avoid needing to override the current item by preventing the pot from giving the same kind (not recommended).
	-- 	Changing this ConVar might be a way to balance the item if it is judged too weak or too strong:
	--	Using either 0 or 1 may result in players sometimes getting less items from the pot of greed;
	--	however, this can result in a frustrating outcome for players and severly penalize them over "bad RNG".
	--	On the other hand, using 3 enables users to manipulate what items they will not get.
	conVars.conflictPolicy = CreateConVar(	"ttt_potOfGreed_conflictPolicy", "2", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 
											"Determines the policy of the item ttt_potOfGreed when conflicts happen.",
											0, 3)
end

local function GetSubRoleEquipment(subrole)
	local equipmentTable = {}

	local itms = items.GetList()

	for i = 1, #itms do
		local equip = itms[i]

		if not equip.CanBuy or not equip.CanBuy[subrole] then continue end

		equipmentTable[#equipmentTable + 1] = equip
	end

	local weps = weapons.GetList()

	for i = 1, #weps do
		local equip = weps[i]

		if not equip.CanBuy or not equip.CanBuy[subrole] then continue end

		equipmentTable[#equipmentTable + 1] = equip
	end

	return equipmentTable
end

---
-- Attempt to give a player an equipment and mark it as bought if successful
local function Give(player, equipmentClassName)
	local is_item = items.IsItem(equipmentClassName)
	if is_item then
		local item = player:GiveEquipmentItem(equipmentClassName)

		if item then
			if isfunction(item.Bought) then
				item:Bought(player)
			end
			player:AddBought(equipmentClassName)
		end
	else
		player:GiveEquipmentWeapon(equipmentClassName, function(p, c, w)
				if isfunction(w.WasBought) then
					w:WasBought(p)
				end
				p:AddBought(c)
			end)
	end
end

local function UpdateEquipmentTable(equipmentTable, func_update)
	if isfunction(func_update) then
		newEquipmentTable = {}
		for i = 1, #equipmentTable do
			if func_update(equipmentTable[i]) then
				table.insert(newEquipmentTable, equipmentTable[i])
			end
		end
		return newEquipmentTable
	end
end

local function StripOldWeapon(buyer, newItemKind)
	if newItemKind < 7 then --I think all items under 7 are unique?
		local inventoryTable=buyer:GetWeapons()
		for k, inventoryItem in pairs(inventoryTable) do
			if inventoryItem.kind == newItemKind then 
				buyer:StripWeapon(inventoryItem:GetClass())
			end
		end
	end
end

-- Function of the item
function SWEP:WasBought(buyer)
	if not IsValid(buyer) then return end
	-- Gets the first role ID with a valid shop up the inheritance tree
	local subrole=GetShopFallback(buyer:GetSubRole())
	buyer:StripWeapon(self:GetClass())
	if SERVER then
		local conVarValues = {}
		conVarValues.nbItemsToGive = 	GetConVar("ttt_potOfGreed_nbItemsToGive"):GetInt()
		conVarValues.conflictPolicy = 	GetConVar("ttt_potOfGreed_conflictPolicy"):GetInt()
		
		local equipmentTable = GetSubRoleEquipment(subrole)
		if(conVarValues.conflictPolicy == 3) then
			local inventoryTable=buyer:GetWeapons()
			equipmentTable = UpdateEquipmentTable(equipmentTable, function(equipment)
					for k, inventoryItem in pairs(inventoryTable) do
						if inventoryItem.kind == equipment.kind then 
							return false
						end
					end
					local buyable, _, _ = EquipmentIsBuyable(equipment, buyer)
					return buyable and equipment.id ~= "weapon_ttt_potofgreed"
				end)
		else
			equipmentTable = UpdateEquipmentTable(equipmentTable, function(equipment)
					local buyable, _, _ = EquipmentIsBuyable(equipment, buyer)
					return buyable and equipment.id ~= "weapon_ttt_potofgreed"
				end)
		end
		for i=1, conVarValues.nbItemsToGive do
			if #equipmentTable ~= 0 then
				local itemIndex = math.random(1, #equipmentTable)
				local itemClassName = equipmentTable[itemIndex].ClassName
				
				if conVarValues.conflictPolicy == 0 then --"do nothing" case...
					Give(buyer, itemClassName)
					table.remove(equipmentTable, itemIndex)
					
				elseif conVarValues.conflictPolicy == 1 then --"override" case...
					local newItemKind = equipmentTable[itemIndex].kind
					StripOldWeapon(buyer, newItemKind)
					Give(buyer, itemClassName)
					table.remove(equipmentTable, itemIndex)
					
				elseif conVarValues.conflictPolicy >= 2 then --"override" case w/ table update...
					local newItemKind = equipmentTable[itemIndex].kind
					StripOldWeapon(buyer, newItemKind)
					Give(buyer, itemClassName)
					table.remove(equipmentTable, itemIndex)
					if newItemKind < 7 then
						equipmentTable = UpdateEquipmentTable(equipmentTable, function(equipment)
							return equipment.kind ~= newItemKind
						end)
					end
				end
			end
		end
	end
end