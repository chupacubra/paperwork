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
    self:SetCollisionGroup( 15 )

    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:Wake()
    end

    self.data = [[]]
    self.name = "Paper"
    self.stamps = {}
    self.stampPos = {}
end

function ENT:SetData(text, name, stamps, stampsPos, drawStamp) -- printer,fcab or clipboard
    self.data = text
    self.name = name
    self.stamps = stamps or {}
    self.stampPos = stampsPos or {}

    if string.len(text) != 0 then
        self:SetSkin(1)
    end

    timer.Simple(1, function()
        if drawStamp then
            if self.stampPos then
                for k,v in pairs(self.stampPos) do
                    self:SendStamp(v.s, v.p) -- bruh
                end
            end
        end
    end)

end

function ENT:Use(caller)
    net.Start("pw_openpaper")
    net.WriteEntity(self)
    net.WriteString(self.data)
    net.WriteString(self.name)
    net.WriteTable(self.stamps)
    net.Send(caller)
end

function ENT:GetStamp(stamp,stamppos)
    table.insert(self.stamps, stamp)
    table.insert(self.stampPos, {s = stamp,p = self:WorldToLocal(stamppos)})

    self:SendStamp(stamp,self:WorldToLocal(stamppos))
    
end

function ENT:SendStamp(stamp,pos)
    net.Start("pw_decalstamp")
    net.WriteEntity(self)
    net.WriteInt(stamp,8)
    net.WriteVector(pos)
    net.Broadcast()
end


net.Receive("pw_updatetext", function(len,ply)
    local paper = net.ReadEntity()
    if not PW_CanUse(paper, ply) then return end

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
    net.WriteTable(paper.stamps)
    net.Send(ply)
end)
