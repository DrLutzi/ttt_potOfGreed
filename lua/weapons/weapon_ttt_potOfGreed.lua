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
SWEP.LimitedStock = false

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
	--		0 - do nothing. The new item is lost.
	--		1 - override the current item. The user may still lose items if several items taking the same slot are obtained.
	--		2 - override the current item, and prevent next given items from overriding this new item.
	-- 	Changing this ConVar might be a way to balance the item if it is judged too weak or too strong:
	--	Using either 0 or 1 may result in players sometimes getting less items from the pot of greed;
	--	however, this can result in a frustrating outcome for players and severly penalize them over "bad RNG".
	conVars.conflictPolicy = CreateConVar(	"ttt_potOfGreed_conflictPolicy", "2", {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 
											"Determines the policy of the item ttt_potOfGreed when conflicts happen.",
											0, 2)
end

-- Function of the item
function SWEP:WasBought(buyer)
	if not IsValid(buyer) then return end
	local subrole=buyer:GetSubRole()
	buyer:StripWeapon(self:GetClass())
	if SERVER then
		local conVarValues = {}
		conVarValues.nbItemsToGive = 	GetConVar("ttt_potOfGreed_nbItemsToGive"):GetInt()
		conVarValues.conflictPolicy = 	GetConVar("ttt_potOfGreed_conflictPolicy"):GetInt()
		
		local rd = roles.GetByIndex(subrole)
		local equipmentTable=rd.fallbackTable
		local buyableItemTable = {}
--		PrintMessage(HUD_PRINTTALK, tostring(#equipmentTable))
		for i = 1, #equipmentTable do
			if not 	equipmentTable[i].notBuyable and equipmentTable[i].id ~= "weapon_ttt_potofgreed" then
				table.insert(buyableItemTable, equipmentTable[i])
			end
		end
--		PrintMessage(HUD_PRINTTALK, tostring(#buyableItemTable))
		for i=1, conVarValues.nbItemsToGive do
			if #buyableItemTable ~= 0 then
				local itemIndex = math.random(1, #buyableItemTable)
--				PrintMessage(HUD_PRINTTALK, tostring(buyableItemTable[itemIndex].id))
				local itemToGiveClass = buyableItemTable[itemIndex].ClassName
				if conVarValues.conflictPolicy == 0 then --"do nothing" case...
					buyer:Give(itemToGiveClass)
				elseif conVarValues.conflictPolicy == 1 then --"override" case...
					local newSlot = buyableItemTable[itemIndex].kind
					if newSlot < 7 then --I think all items under 7 are unique?
						local inventoryTable=buyer:GetWeapons()
						for k, inventoryItem in pairs(inventoryTable) do
							if inventoryItem:GetSlot() == newSlot then 
								buyer:StripWeapon(inventoryItem:GetClass())
							end
						end
					end -- TODO: case for newSlot >= 7
					buyer:Give(itemToGiveClass)
				elseif conVarValues.conflictPolicy == 2 then
					local newSlot = buyableItemTable[itemIndex].kind
					if newSlot < 7 then --I think all items under 7 are unique?
						local inventoryTable=buyer:GetWeapons()
						for k, inventoryItem in pairs(inventoryTable) do
							if inventoryItem:GetSlot() == newSlot then 
								buyer:StripWeapon(inventoryItem:GetClass())
							end
							buyer:Give(itemToGiveClass)
							local updatedBuyableItemTable = {}
							for k2, buyableItem in pairs(buyableItemTable) do
								if buyableItem:GetSlot() ~= newSlot then
									table.insert(updatedBuyableItemTable, buyableItem)
								end
							end
							buyableItemTable = updatedBuyableItemTable
						end
					else
						buyer:Give(itemToGiveClass)
					end -- TODO: case for newSlot >= 7
				end
				table.remove(buyableItemTable, itemIndex)
			end
		end
	end
end