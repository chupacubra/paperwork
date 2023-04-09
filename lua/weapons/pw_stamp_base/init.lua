AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function SWEP:Initialize()
    self:SetHoldType( "slam" )

    self:InitStamp()
end

function SWEP:InitStamp()
    self.Stamp = STAMP_APPROVED
end

function SWEP:PrimaryAttack()
    local trace = {}

	trace.start = self.Owner:GetShootPos()
	trace.endpos = trace.start + (self.Owner:GetAimVector() * 500)

	trace.filter = function(ent)
        return !ent:IsPlayer()
	end
	
    trace = util.TraceLine(trace)
    if tostring(trace.Entity) == "[NULL Entity]" then
        return
    end
    
    if trace.Entity:GetClass() == "pw_paper" then
        self:StampingPaper(trace.Entity,trace.HitPos)
    end
end

function SWEP:StampingPaper(paper, pos)
    paper:GetStamp(self.Stamp, pos)
end

function SWEP:SecondaryAttack()

end