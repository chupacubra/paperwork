AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function SWEP:SetupDataTables()
    self:NetworkVar("Int",0,"PaperCount")
end

function SWEP:Initialize()
    self.AllPapers = {}
    self:SetHoldType( "slam" )
end

function SWEP:PrimaryAttack()
    local trace = {}

	trace.start = self.Owner:GetShootPos()
	trace.endpos = trace.start + (self.Owner:GetAimVector() * 150)
	trace.filter = function(ent)
        return !ent:IsPlayer()
	end
	
    trace = util.TraceLine(trace)

    if not trace.Entity:IsValid() then
        return
    end
    
    if trace.Entity:GetClass() == "pw_paper" then
        local doc = {
            text = trace.Entity.data,
            name = trace.Entity.name
        }
        trace.Entity:Remove()
        self:AddPaper(doc)
    end
end

function SWEP:AddPaper(doc)
    table.insert(self.AllPapers,doc)
    self:SetPaperCount(#self.AllPapers)
    self:SendCountPaper()
end

function SWEP:RemovePaper(num)
    if !self.AllPapers[num] then 
        return
    end

    local paper = self.AllPapers[num]
    table.remove(self.AllPapers, num)
    self:SetPaperCount(#self.AllPapers)
    local trace = {}

	trace.start = self.Owner:GetShootPos()
	trace.endpos = trace.start + (self.Owner:GetAimVector() * 75)
	trace.filter = function(ent)
        return !ent:IsPlayer()
	end
	
    trace = util.TraceLine(trace)
    local pos = trace.HitPos
    local ent = trace.Entity

    if ent == Entity(-1) then
        local papr = ents.Create( "pw_paper" )
        papr:SetPos( pos )
        papr:Spawn()
        papr:SetData(paper["text"],paper["name"])
    else
        local doc = {
            text = paper["text"],
            name = paper["name"],
        }
        if ent:GetClass() == "pw_filecabinet" then
            ent:AddPaper(doc)     
        elseif ent:GetClass() == "pw_printer" then
            if #ent.scandoc == 1 then
                local papr = ents.Create( "pw_paper" )
                papr:SetPos( pos )
                papr:Spawn()
                papr:SetData(paper["text"],paper["name"])
            else
                ent.scandoc[1] = doc
            end
        else
            local papr = ents.Create( "pw_paper" )
            papr:SetPos( pos )
            papr:Spawn()
            papr:SetData(paper["text"],paper["name"])
        end
    end
    self:SendCountPaper()
end

function SWEP:SecondaryAttack()
    net.Start("pw_openclipboard")
        net.WriteEntity(self)
        net.WriteTable(self.AllPapers)
    net.Send(self.Owner)
end

function SWEP:SendCountPaper()
    local int
    if #self.AllPapers >= 3 then
        int = 3
    else
        int = #self.AllPapers
    end
    net.Start("pw_cbpapcount")
    net.WriteEntity(self)
    net.WriteInt(int,3)
    net.Broadcast()
end

net.Receive("pw_updatepaper", function(len,ply)
    local cb   = net.ReadEntity()
    local num  = net.ReadInt(8)
    local text = net.ReadString()
    local int  = net.ReadString()

    if int == "-1" then
        local text, inp = MarkInp(text,ply)
        cb.AllPapers[num]["inp"] = inp
        cb.AllPapers[num]["text"] = cb.AllPapers[num]["text"]..text
    else
        local text, inp = MarkInp(text,ply)
        cb.AllPapers[num]["inp"] = inp
        cb.AllPapers[num]["text"] = string.Replace(cb.AllPapers[num]["text"],[[<a href="javascript:paper.luaprint(']]..int..[[')">Write</a>]],text)
    end

    net.Start("pw_updateclip")
        net.WriteEntity(cb)
        net.WriteInt(num,8)
        net.WriteString(cb.AllPapers[num]["text"])
    net.Send(ply)
end)

net.Receive("pw_renamep", function (len,ply)
    local cb = net.ReadEntity()
    local name = net.ReadString()
    local num = net.ReadInt(8)

    cb.AllPapers[num]["name"] = name
end)

net.Receive("pw_cbrempaper", function()
    local cb = net.ReadEntity()
    local num = net.ReadInt(8)
    cb:RemovePaper(num)
end)