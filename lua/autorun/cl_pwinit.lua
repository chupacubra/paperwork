include("sh_pwshared.lua")
include("cl_markdown.lua")
include("cl_pw_config.lua")


if CLIENT then
    pw_sizefont = CreateClientConVar( "pw_sizefont", 20, true,false, "The size of font in papers", 5, 50 )

    local PW_size_frame = PW_size_frame or {x = 350, y = 500}

    cvars.AddChangeCallback("pw_sizefont", function(n, old, new)
        STYLE =[[
            <style type="text/css">
            table {
                border-collapse: collapse;
            }
            td {
                border: 1px solid black;
                padding: 4px;
            }
            
            html {
                font-size: ]]..new..[[px;
            }
            </style>
        ]]
        hook.Run( "PW_sizefontchanged" )
    end)

    function HTMLStamp(tbl)
        local str = ""
    
        for k,v in pairs(tbl) do
            str = str .. "<img src='"..STAMPS_PNG[v] .."'>"
        end
    
        return str
    end
end
