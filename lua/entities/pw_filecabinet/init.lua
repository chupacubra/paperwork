AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function MarkInp(text,ply)
    for k,v in pairs(BLOCK_TAG) do
        text = string.Replace(text,v,"")
    end
    for k,v in pairs(coolchar) do
        if k == "write" then
            local fstr = "%["..k.."%]"
            while string.find(text,fstr) do
                text = string.gsub(text, fstr, v(),1)
            end
        else
            local fstr = "["..k.."]"
            if string.find(text,fstr) then
                text = string.Replace(text,fstr,v(paper,ply))
            end
        end
    end
    return text
end

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
    local key = net.ReadString()

    local paper = ents.Create( "pw_paper" )
    paper:SetPos( cab:GetPos() + Vector(0,0,25) )
    paper:Spawn()
    paper:SetData(cab.docs[key]["text"],cab.docs[key]["name"])

    cab.docs[key] = nil 
end)