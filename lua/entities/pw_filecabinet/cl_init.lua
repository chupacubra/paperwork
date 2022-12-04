include("shared.lua")

function ENT:Draw()
    self:DrawModel()
end

net.Receive("pw_openfcab", function()
    local doctbl = net.ReadTable()
    local cab  = net.ReadEntity()

    local Frame = vgui.Create( "DFrame" )
    Frame:SetSize( 500, 500 )
    Frame:Center()
    Frame:MakePopup()
    Frame:Center()
    local DocList = vgui.Create( "DCategoryList", Frame )
    DocList:Dock( FILL )
    
    local Doc = DocList:Add( "All documents" )
    
    for k,v in pairs(doctbl) do
        local button = Doc:Add( v[2] )
        button.DoClick = function()
            net.Start("pw_getfcab")
                net.WriteEntity(cab)
                net.WriteString(v[1])
            net.SendToServer()
            doctbl[k] = nil
            button:Remove()
        end
    end
end)