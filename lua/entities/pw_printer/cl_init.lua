include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

net.Receive("pw_openprinter", function()
    local TitleTbl = net.ReadTable()
    local TitleScan = net.ReadString()
    local printer  = net.ReadEntity()
    local DList = {}
    local canScan = true
    if TitleScan == "" or TitleScan == nil then
        TitleScan = "NONE"
        canScan = false
    end

    local Frame = vgui.Create( "DFrame" )
    Frame:SetSize( 500, 500 )
    Frame:Center()
    Frame:MakePopup()
    Frame:Center()
    
    local DocList = vgui.Create( "DCategoryList", Frame )
    DocList:SetPos(5,25)
    DocList:SetSize(490,350)

    local Doc = DocList:Add( "All form" )
    
    for k,v in pairs(TitleTbl) do
        local button = Doc:Add( v )
        button.DoClick = function()
            net.Start("pw_printdoc")
                net.WriteEntity(printer)
                net.WriteString(v)
            net.SendToServer()
        end
    end

    local SPButton = vgui.Create( "DButton", Frame )
    SPButton:SetText( "Scan and print" )	
    SPButton:SetPos( 35, 400 )
    SPButton:SetSize( 100, 30 )
    SPButton:SetEnabled(canScan)

    SPButton.DoClick = function()
        net.Start("pw_printscandoc")
        net.WriteEntity(printer)
        net.WriteInt(1,2)
        net.SendToServer()
    end

    local SRButton = vgui.Create( "DButton", Frame )
    SRButton:SetText( "Remove scan paper" )	
    SRButton:SetPos( 35, 440 )
    SRButton:SetSize( 100, 30 )
    SRButton:SetEnabled(canScan)
    
    local Label = vgui.Create("DLabel",Frame)
    Label:SetPos(150,400)
    Label:SetSize(160,30)
    Label:SetText("Current scanning paper: "..TitleScan)
    
    SRButton.DoClick = function()
        net.Start("pw_printscandoc")
        net.WriteEntity(printer)
        net.WriteInt(0,2)
        net.SendToServer()

        SRButton:SetEnabled(false)
        SPButton:SetEnabled(false)
        TitleScan = "NONE"
        Label:SetText("Current scanning paper: "..TitleScan)
    end

end)