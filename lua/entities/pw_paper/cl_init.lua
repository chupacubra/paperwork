include("shared.lua")

PW_size_frame = PW_size_frame or {x = 350, y = 500}


net.Receive( "pw_updatepaper2", function()
    local paper1 = net.ReadEntity()
    local text = net.ReadString()
    
    if paper1 == paper then
        paper:SetPaperText(text)
        if HTML then
            HTML:SetHTML( STYLE..markdown([[]]..text..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a>]] )
        end
    end
end)

function ENT:SetupDataTables()
    self:NetworkVar("String",0,"PaperText")
end

function ENT:Draw()
    self:DrawModel()
end

net.Receive("pw_openpaper",function()
    paper = net.ReadEntity()
    ptext = net.ReadString()
    pname = net.ReadString()

    local Frame = vgui.Create( "DFrame" )
    Frame:SetSize( PW_size_frame.x, PW_size_frame.y ) 
    Frame:SetTitle( pname )
    Frame:SetVisible( true )
    Frame:SetDraggable( true )
    Frame:ShowCloseButton( true )
    Frame:SetSizable( true )
    Frame:SetMinWidth(350)
    Frame:SetMinHeight(500)
    Frame:Center()
    Frame:MakePopup()

    local DPanel = vgui.Create( "DPanel",Frame )
    DPanel:SetPos( 1, 25 )
    DPanel:SetSize( PW_size_frame.x - 2, PW_size_frame.y - 26 )
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
        INPB:SetText( "Write" )
        INPB:SetPos( 125, 360 )
        INPB:SetSize( 100, 30 )
        INPB.DoClick = function()
            paper:SendUpdate(int,INP:GetValue())
            INPFrame:Close()
        end
    end)

    function Frame:OnSizeChanged( w, h )
        PW_size_frame.x = w
        PW_size_frame.y = h

        HTML:SetSize( PW_size_frame.x - 2, PW_size_frame.y - 26 )
        DPanel:SetSize( PW_size_frame.x - 2, PW_size_frame.y - 26 )
    end

    HTML:SetHTML( STYLE..markdown([[]]..ptext..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a>]] )
    HTML:SetSize( PW_size_frame.x - 2, PW_size_frame.y - 26 )

    
end)

function ENT:SendUpdate(int,text)
    net.Start("pw_updatetext")
        net.WriteEntity(self)
        net.WriteString(tostring(int))
        net.WriteString(text)
    net.SendToServer()
end


hook.Add( "PW_sizefontchanged" , "UpdatePaper" , function()
    if HTML == nil then return end

    if HTML:IsValid() and ptext != nil then
        HTML:SetHTML( STYLE..markdown([[]]..ptext..[[]])..[[<a href="javascript:paper.luaprint(-1)">Write</a>]] )
    end
end)
