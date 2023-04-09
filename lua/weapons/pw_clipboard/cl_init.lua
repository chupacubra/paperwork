include('shared.lua')

PW_size_frame = PW_size_frame or {x = 350, y = 500}


SWEP.PrintName        = "Clipboard"			
SWEP.Slot		= 0
SWEP.SlotPos		= 0
SWEP.DrawAmmo		= false
SWEP.DrawCrosshair	= false
SWEP.HoldType 			= "slam"

net.Receive("pw_cbpapcount",function()
    local cb = net.ReadEntity()
    local int = net.ReadInt(3)

    cb.VData.p_count = int
end)

function SWEP:SetupDataTables()
    self:NetworkVar("Int",0,"PaperCount")
    self:NetworkVar("Bool",0,"Attaching")
end

function SWEP:GetViewModelPosition( pos , ang)
	pos,ang = LocalToWorld(Vector(20,-10,-10),Angle(0,180,0),pos,ang)
	self:SetBodygroup(1,3)
	return pos, ang
end

function SWEP:PreDrawViewModel( vm, weapon, ply )
    if vm:GetBodygroup( 1 ) != self.VData.p_count then
        vm:SetBodygroup( 1, self.VData.p_count)
        vm:SetSkin(1)
    end
end

local WorldModel = ClientsideModel(SWEP.WorldModel)
WorldModel:SetSkin(1)
WorldModel:SetNoDraw(true)


function SWEP:ChangeVModel(id)
    WorldModel:SetModel(modellist[id])
end

net.Receive( "pw_updateclip", function()
    local cb1 = net.ReadEntity()
    local num = net.ReadInt(8)
    local text = net.ReadString()
    if clipboard == cb1 then
        if AllPapers[num] then
            AllPapers[num]["text"] = text
            if HTML and activelist == num then
                HTML:SetHTML(STYLE..markdown([[]]..text..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
            end
        end
    end
end)

function SWEP:Initialize()
    self:SetHoldType( "slam" )
    self.VData = {
        p_count = 0 -- 0 = no paper, 1 = 1 paper, 2 = 2 paper, 3 = >= 3 (lot)
    }
    self.cl_attaching = false
end

function SWEP:AttachPoint()
    self.cl_attaching = true
    local x = Vector( 5, 5, 5 )

    hook.Add( "PostDrawTranslucentRenderables", "ClipboardHolo", function()
        if self.cl_attaching == false then
            hook.Remove("PostDrawTranslucentRenderables", "ClipboardHolo")
            return
        end

        local trace = {}

        trace.start = self.Owner:GetShootPos()
        trace.endpos = trace.start + (self.Owner:GetAimVector() * 150)
        trace.filter = function(ent)
            return !ent:IsPlayer()
        end
        
        trace = util.TraceLine(trace)
        local pos = trace.HitPos

        local color_box = Color(255,70,70,155)

        if trace.Entity == Entity(0) then
            color_box = Color(70,255,70,155)
        end

        render.SetColorMaterial()
    
        cam.IgnoreZ( true )
        render.DrawBox( pos, angle_zero, x, -x, color_box )
        cam.IgnoreZ( false )
    end )
end

function SWEP:DrawHUD()
    if self.cl_attaching then
        local x, y = (ScrW() / 2.0) - 128, (ScrH() / 3.0) * 2
        surface.SetFont( "DermaLarge" )
        surface.SetTextColor( 255, 255, 255 )
        surface.SetTextPos( x, y ) 
        surface.DrawText( "To STOP press RMB" )
    end
end

function SWEP:PrimaryAttack()
    if self.cl_attaching then
        local trace = {}

        trace.start = self.Owner:GetShootPos()
        trace.endpos = trace.start + (self.Owner:GetAimVector() * 150)
        trace.filter = function(ent)
            return !ent:IsPlayer()
        end
        
        trace = util.TraceLine(trace)
        local pos = trace.HitPos

        if trace.Entity == Entity(0) then 
            self.cl_attaching = false
            net.Start("pw_cbattachpaper")
            net.WriteEntity(self)
            net.WriteInt(activelist,8)
            net.SendToServer()
        end

    end
end

function SWEP:SecondaryAttack()
    if self.cl_attaching then
        self.cl_attaching = false
        hook.Remove("PostDrawTranslucentRenderables", "ClipboardHolo")
    end
end

function SWEP:DrawWorldModel()
    local _Owner = self:GetOwner()

    if (IsValid(_Owner)) then
        local offsetVec = Vector(4, -5, 0)
        local offsetAng = Angle(0, 180, 180)
        
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
    WorldModel:SetBodygroup( 1, self.VData.p_count)
    WorldModel:DrawModel()
end

function GetPaperStamp()
    if AllPapers[activelist].stamps then
        local allpstams = HTMLStamp(AllPapers[activelist].stamps)
        return allpstams
    end
    return ""
end

net.Receive("pw_openclipboard", function()
    clipboard = net.ReadEntity()
    AllPapers = net.ReadTable()

    if #AllPapers == 0 then return end  
    activelist = #AllPapers


    local Frame = vgui.Create( "DFrame" ) 
    Frame:SetSize( PW_size_frame.x, PW_size_frame.y + 60) 
    Frame:SetTitle( "Clipboard ("..#AllPapers..") - "..activelist.." - "..AllPapers[activelist]["name"] )
    Frame:SetVisible( true )
    Frame:SetDraggable( true )
    Frame:ShowCloseButton( true )
    Frame:SetSizable( true )
    Frame:SetMinWidth(350)
    Frame:SetMinHeight(560)
    Frame:Center()
    Frame:MakePopup()


    local AttachB = vgui.Create( "DButton", Frame )
    AttachB:SetText( "Attach to wall" )
    AttachB:SetPos( PW_size_frame.x - 180, 3 )
    AttachB:SetSize( 75, 20 )
    AttachB.DoClick = function()
        Frame:Close()
        net.Start("pw_cbattaching")
        net.WriteEntity(clipboard)
        net.SendToServer()
        clipboard:AttachPoint()
    end


    local BNEXT = vgui.Create( "DButton", Frame )
    BNEXT.nump = activelist
    BNEXT:SetText( "->" )
    BNEXT:SetPos( PW_size_frame.x - 90, (PW_size_frame.y + 60) - 45 )
    BNEXT:SetSize( 80, 30 )
    BNEXT.DoClick = function()
        if activelist < #AllPapers then
            activelist = activelist + 1
            HTML:SetHTML( STYLE..markdown([[]]..AllPapers[activelist]["text"]..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
            Frame:SetTitle( "Clipboard ("..#AllPapers..") - "..activelist.." - "..AllPapers[activelist]["name"])
        end
    end

    local BREN = vgui.Create( "DButton", Frame )
    BREN.nump = activelist
    BREN:SetText( "Rename list" )
    BREN:SetPos( PW_size_frame.x - 258 , (PW_size_frame.y + 60) - 45 )
    BREN:SetSize( 80, 30 )
    BREN.DoClick = function()
        if #AllPapers < 1 then
            return
        end
        Derma_StringRequest(
            "Name?", 
            "",
            "",
            function(text) 
                AllPapers[activelist]["name"] = text
                net.Start("pw_renamep")
                net.WriteEntity(clipboard)
                net.WriteString(text)
                net.WriteInt(activelist,8)
                net.SendToServer()
            
                if #AllPapers > 0 then
                    HTML:SetHTML( STYLE..markdown([[]]..AllPapers[activelist]["text"]..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
                    Frame:SetTitle( "Clipboard ("..#AllPapers..") - "..activelist.." - "..AllPapers[activelist]["name"])
                else
                    Frame:Close()
                end
            end,
            function(text)  end
        )
    end

    local BREM = vgui.Create( "DButton", Frame )
    BREM.nump = activelist
    BREM:SetText( "Remove list" )
    BREM:SetPos( PW_size_frame.x - 172 , (PW_size_frame.y + 60) - 45 )
    BREM:SetSize( 80, 30 )
    BREM.DoClick = function()
        if #AllPapers < 1 then
            return
        end
        net.Start("pw_cbrempaper")
        net.WriteEntity(clipboard)
        net.WriteInt(activelist,8)
        net.SendToServer()
        
        if activelist > 1 then
            table.remove(AllPapers, activelist)
            activelist = activelist - 1
        else
            table.remove(AllPapers, activelist)
        end
        if #AllPapers > 0 then
            HTML:SetHTML( STYLE..markdown([[]]..AllPapers[activelist]["text"]..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
            Frame:SetTitle( "Clipboard ("..#AllPapers..") - "..activelist.." - "..AllPapers[activelist]["name"])
        else
            Frame:Close()
        end
    end

    local BBACK = vgui.Create( "DButton", Frame )
    BBACK.nump = activelist
    BBACK:SetText( "<-" )
    BBACK:SetPos( PW_size_frame.x - 340, (PW_size_frame.y + 60) - 45 )
    BBACK:SetSize( 80, 30 )
    BBACK.DoClick = function()
        if activelist < 2 then 
            return
        end
        activelist = activelist - 1
        HTML:SetHTML(STYLE..markdown([[]]..AllPapers[activelist]["text"]..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
        Frame:SetTitle( "Clipboard ("..#AllPapers..") - "..activelist.." - "..AllPapers[activelist]["name"])
    end


    local DPanel = vgui.Create( "DPanel",Frame )
    DPanel:SetPos( 1, 25 )
    DPanel:SetSize( PW_size_frame.x - 2, (PW_size_frame.y + 60) - 90 )
    DPanel:SetBackgroundColor(Color(256,256,256))

    HTML = vgui.Create( "DHTML", DPanel )

    HTML:AddFunction( "paper", "luaprint", function(int)
        INPFrame = vgui.Create( "DFrame" )
        INPFrame:SetSize( 350, 400 ) 
        INPFrame:SetTitle( "Write" )
        INPFrame:SetVisible( true ) 
        INPFrame:SetDraggable( true ) 
        INPFrame:ShowCloseButton( true )
        INPFrame:Center()
        INPFrame:MakePopup()

        local INP = vgui.Create( "DTextEntry", INPFrame )
        INP:Dock( TOP )
        INP:SetHeight(325)
        INP:SetMultiline( true )

        local INPB = vgui.Create( "DButton", INPFrame )
        INPB.nump = activelist
        INPB:SetText( "Write" )
        INPB:SetPos( 125, 360 )
        INPB:SetSize( 100, 30 )
        INPB.DoClick = function()
            clipboard:UpdateList(INPB.nump, INP:GetValue(), int)

            INPFrame:Close()
            if HTML then
                HTML:SetHTML( STYLE..markdown([[]]..AllPapers[activelist]["text"]..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
            end
        end
    end)

    function Frame:OnSizeChanged( w, h )
        PW_size_frame.x = w
        PW_size_frame.y = h - 60

        HTML:SetSize(PW_size_frame.x - 2, (PW_size_frame.y + 60) - 90 )
        DPanel:SetSize(PW_size_frame.x - 2, (PW_size_frame.y + 60) - 90  )

        BNEXT:SetPos( PW_size_frame.x - 90, (PW_size_frame.y + 60) - 45 )
        BREM:SetPos( PW_size_frame.x - 172 , (PW_size_frame.y + 60) - 45 )
        BBACK:SetPos( PW_size_frame.x - 340, (PW_size_frame.y + 60) - 45 )
        BREN:SetPos( PW_size_frame.x - 258 , (PW_size_frame.y + 60) - 45 )
        AttachB:SetPos( PW_size_frame.x - 180, 3 )
    end

    HTML:SetHTML( STYLE..markdown([[]]..AllPapers[activelist]["text"]..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
    HTML:SetSize( PW_size_frame.x - 2, (PW_size_frame.y + 60) - 90 )
end)

function SWEP:UpdateList(num,text,int)
    net.Start("pw_updatepaper")
    net.WriteEntity(self)
    net.WriteInt(num,8)
    net.WriteString(text)
    net.WriteString(tostring(int))
    net.SendToServer()
end

hook.Add( "PW_sizefontchanged" , "UpdateClip" , function()
    if HTML == nil then return end

    if HTML:IsValid() and AllPapers != nil then
        HTML:SetHTML( STYLE..markdown([[]]..AllPapers[activelist]["text"]..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a><br><hr>]]..GetPaperStamp() )
    end

end)
