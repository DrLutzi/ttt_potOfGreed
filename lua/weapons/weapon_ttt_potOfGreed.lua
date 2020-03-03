if SERVER then
   AddCSLuaFile( "weapon_ttt_potOfGreed.lua" )
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

function SWEP:WasBought(buyer)
	if not IsValid(buyer) then return end
	local nbItemsToGet = 2
	local subrole=buyer:GetSubRole()
	buyer:StripWeapon(self:GetClass())
	if SERVER then
		local equipmentTable=GetShopFallbackTable(subrole)
		local buyableEquipmentTable = {}
--		PrintMessage(HUD_PRINTTALK, tostring(#equipmentTable))
		for i = 1, #equipmentTable do
			if not equipmentTable[i].notBuyable and equipmentTable[i].id ~= "weapon_ttt_potofgreed" then
				table.insert(buyableEquipmentTable, equipmentTable[i])
			end
		end
--		PrintMessage(HUD_PRINTTALK, tostring(#buyableEquipmentTable))
		for i=1, nbItemsToGet do
			if #buyableEquipmentTable ~= 0 then
--				math.randomseed(SysTime()) --probably unnecessary
				itemIndex = math.random(1, #buyableEquipmentTable)
				PrintMessage(HUD_PRINTTALK, tostring(buyableEquipmentTable[itemIndex].id))
				buyer:Give(buyableEquipmentTable[itemIndex].ClassName)
				table.remove(buyableEquipmentTable, itemIndex)
			end
		end
	end
end