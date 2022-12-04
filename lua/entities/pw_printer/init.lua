AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function ENT:Initialize()
    self:SetModel("models/props/m5521cdn.mdl")
    self:PhysicsInit( SOLID_VPHYSICS )
    self:SetMoveType( MOVETYPE_VPHYSICS )
    self:SetSolid( SOLID_VPHYSICS )
    self:SetUseType(SIMPLE_USE)
    local phys = self:GetPhysicsObject()
    if (phys:IsValid()) then
        phys:Wake()
    end
    self.scandoc = {}
    self.CanPrint = true
end

function ENT:RemoveScanDoc(ply)
    if #self.scandoc == 0 then 
        return
    end

    local paper = ents.Create( "pw_paper" )
    paper:SetPos( self:GetPos() + Vector(0,0,40) )
    paper:Spawn()
    paper:SetData(self.scandoc[1]["text"],self.scandoc[1]["name"])

    self.scandoc = {}
end

function ENT:Use(caller)
    local name = ""
    if self.scandoc[1] then
        name = self.scandoc[1]["name"]
    end

    net.Start("pw_openprinter")
    net.WriteTable(TBLTITLEDOCS)
    net.WriteString(name)
    net.WriteEntity(self)
    net.Send(caller)
end

function ENT:PrintDoc(doc,scan,ply)
    if self.CanPrint != true then
        return
    end

    local paper = ents.Create( "pw_paper" )
    paper:SetPos( self:GetPos() + Vector(0,0,40) )
    paper:Spawn()
    if scan then
        if self.scandoc[1] then
            paper:SetData(self.scandoc[1]["text"],self.scandoc[1]["name"])
        end
    else
        if PRINTFORM[doc] then
            paper:SetData(MarkInp(PRINTFORM[doc],0),doc)
        end
    end

    EmitSound( Sound( "printer.wav" ), self:GetPos(), 1, CHAN_AUTO, 1, 75, 0, 100 + (math.random(-30, 30) ) )
    self.CanPrint = CurTime() + 4
end

net.Receive("pw_printdoc",function(len,ply)
    local printer = net.ReadEntity()
    local doc     = net.ReadString()
    
    printer:PrintDoc(doc,false,ply)
end)

net.Receive("pw_printscandoc", function(len,ply)
    local printer = net.ReadEntity()
    local int     = net.ReadInt(2)
    if int == 1 then
        printer:PrintDoc(_,true,ply)
    else
        printer:RemoveScanDoc(ply)
    end
end)

function ENT:Think()
    if type(self.CanPrint) == "number" then
        if self.CanPrint <= CurTime() then
            self.CanPrint = true
        end
    end
end
