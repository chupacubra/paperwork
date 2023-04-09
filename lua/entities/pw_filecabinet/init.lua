AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props_lab/filecabinet02.mdl")
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS ) 
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:Wake()
    end
    self.docs = {}
end

function ENT:AddPaper(doc)
    self.docs[gentocken()] = doc
end

function ENT:Use(caller)
    local title = {}
    for k,v in pairs(self.docs) do
        table.insert(title,{k,v["name"]})
    end
    net.Start("pw_openfcab")
    net.WriteTable(title)
    net.WriteEntity(self)
    net.Send(caller) 
end

net.Receive("pw_getfcab",function(len,ply)
    local cab = net.ReadEntity()
    if not PW_CanUse(cab, ply) then return end

    local key = net.ReadString()
    if not cab.docs[key] then return end

    local paper = ents.Create( "pw_paper" )
    paper:SetPos( cab:GetPos() + Vector(0,0,25) )
    paper:Spawn()
    paper:SetData(cab.docs[key]["text"],cab.docs[key]["name"],cab.docs[key]["stamps"],cab.docs[key]["stampPos"], true)

    cab.docs[key] = nil 
end)