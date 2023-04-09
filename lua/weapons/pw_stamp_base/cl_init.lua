include('shared.lua')

SWEP.PrintName        = "Stamp"			
SWEP.Slot		= 0
SWEP.SlotPos		= 0
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= false
SWEP.HoldType 			= "slam"

function SWEP:Initialize()
    self:SetHoldType( "slam" )
end

function SWEP:GetViewModelPosition( pos , ang)
	pos,ang = LocalToWorld(Vector(20,-10,-0),Angle(0,180,0),pos,ang)
	
	return pos, ang
end

local WorldModel = ClientsideModel(SWEP.WorldModel)
WorldModel:SetNoDraw(true)

function SWEP:DrawWorldModel()
    local _Owner = self:GetOwner()

    if (IsValid(_Owner)) then
        local offsetVec = Vector(3, -3, -1)
        local offsetAng = Angle(0, 0, 180)
        
        local boneid = _Owner:LookupBone("ValveBiped.Bip01_R_Hand")
        if !boneid then return end

        local matrix = _Owner:GetBoneMatrix(boneid)
        if !matrix then return end

        local newPos, newAng = LocalToWorld(offsetVec, offsetAng, matrix:GetTranslation(), matrix:GetAngles())

        WorldModel:SetPos(newPos)
        WorldModel:SetAngles(newAng)

        WorldModel:SetupBones()
    else
        WorldModel:SetPos(self:GetPos())
        WorldModel:SetAngles(self:GetAngles())
    end
    --WorldModel:SetBodygroup( 1, self.VData.p_count)
    WorldModel:DrawModel()
end