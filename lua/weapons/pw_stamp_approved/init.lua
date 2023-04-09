AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")


function SWEP:InitStamp()
    self.Stamp = STAMP_APPROVED
end
