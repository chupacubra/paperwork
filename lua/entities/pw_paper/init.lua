AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")



function ENT:SetupDataTables()
    self:NetworkVar("String",0,"PaperText")
end

function ENT:Initialize()
    self:SetModel("models/conred/office/clipboard_paper.mdl")
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:Wake()
    end
    self.data = [[]]
    self.name = "Paper"
end

function ENT:SetData(text,name) -- printer,fcab or clipboard
    self.data = text
    self.name = name
    if string.len(text) != 0 then
        self:SetSkin(1)
    end
end

function ENT:Use(caller)
    net.Start("pw_openpaper")
      net.WriteEntity(self)
      net.WriteString(self.data)
      net.WriteString(self.name)
    net.Send(caller)
end

net.Receive("pw_updatetext", function(len,ply)
    local paper = net.ReadEntity()
    local int   = net.ReadString()
    local text  = net.ReadString()
    if string.len(paper.data) == 0 and (text != "" or text != nil) then
        paper:SetSkin(1)
    end
    if int == "-1" then
        paper.data = paper.data .. MarkInp(text,ply)
    else
        paper.data = string.Replace(paper.data,[[<a href="javascript:paper.luaprint(']]..int..[[')">Write</a>]],MarkInp(text,ply))
    end
    
    net.Start("pw_updatepaper2")
    net.WriteEntity(paper)
    net.WriteString(paper.data)
    net.Send(ply)
end)