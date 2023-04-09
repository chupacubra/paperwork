AddCSLuaFile("cl_pwinit.lua")
AddCSLuaFile("sh_pwshared.lua")
AddCSLuaFile("cl_markdown.lua")
AddCSLuaFile("cl_pw_config.lua")

include("sv_netstr.lua")
include("sv_listdocs.lua")


sound.Add( {
	name = "paperwork.printer",
	channel = CHAN_STATIC,
	volume = 1.0,
	level = 80,
	pitch = {95, 110},
	sound = "printer.wav"
} )
 
function TableTitleDocs()
    local tbl = {}
    for k,v in pairs(PRINTFORM) do
        table.insert(tbl,k)
    end
    return tbl
end

coolchar = {
    sign = function(p,ply)
        if ply == 0 then return end
        return "<span style='font-size:125%;font-family: Bell MT,serif;'>***"..ply:Nick().."***</span>"
    end,
    time = function(p,ply)
        return util.DateStamp()
    end,
    write = function(p,ply)
        local tocken = gentocken()
        return [[<a href="javascript:paper.luaprint(']]..tocken..[[')">Write</a>]]
    end
}

function MarkInp(text,ply)
    for k,v in pairs(BLOCK_TAG) do
        text = string.Replace(text,v,"")
    end
    for k,v in pairs(coolchar) do
        if k == "write" then
            local fstr = "%["..k.."%]"
            while string.find(text,fstr) do
                text = string.gsub(text, fstr, v(),1)
            end
        else
            local fstr = "["..k.."]"
            if string.find(text,fstr) then
                text = string.Replace(text,fstr,v(paper,ply))
            end
        end
    end
    return text
end

local dist = 100
dist = dist * dist

function PW_CanUse(ent, ply)
    if ent:GetPos():DistToSqr(ply:GetPos()) > dist then return false end -- F*ck motherhackers
    if CPPI and not ent:CPPICanUse(ply) then return false end -- Prop protect support

    return true
end