AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")

include("shared.lua")

function SWEP:SetupDataTables()
    self:NetworkVar("Int",0,"PaperCount")
    self:NetworkVar("Bool",0,"Attaching")
end

function SWEP:Initialize()
    self.AllPapers = {}
    self:SetHoldType( "slam" )
    self.attaching = false

end


function SWEP:AttachingToWall()
    local trace = {}

	trace.start = self.Owner:GetShootPos()
	trace.endpos = trace.start + (self.Owner:GetAimVector() * 150)
	trace.filter = function(ent)
        return !ent:IsPlayer()
	end
	
    trace = util.TraceLine(trace)
    if trace.Entity == Entity(0) then

        net.Receive("pw_cbattachpaper",function()
            local cb  = net.ReadEntity()
            local num = net.ReadInt(8)

            if cb == self then

                local pos = trace.HitPos
                local ang = trace.HitNormal:AngleEx(Vector(0,0,0))

                local doc = {
                    text = self.AllPapers[num].text,
                    name = self.AllPapers[num].name,
                    stamps = self.AllPapers[num].stamps,
                    stampPos = self.AllPapers[num].stampPos
                }

                table.remove(self.AllPapers, num)
                
                local papr = ents.Create( "pw_paper" )
                papr:SetPos( pos )
                papr:SetAngles(ang)
                papr:Spawn()
                gamemode.Call("OnPhysgunFreeze", self, papr:GetPhysicsObject(), papr, self.Owner)
                papr:SetData(doc.text, doc.name, doc.stamps, doc.stampPos, true )

                self.attaching = false

                self:SetPaperCount(#self.AllPapers)
                self:SendCountPaper()
            end
        end)
    end
end

function SWEP:PrimaryAttack()
    if ( game.SinglePlayer() ) then self:CallOnClient( "PrimaryAttack" ) end

    if self.attaching then
        self:AttachingToWall()
        return
    end

    local trace = {}

	trace.start = self.Owner:GetShootPos()
	trace.endpos = trace.start + (self.Owner:GetAimVector() * 150)
	trace.filter = function(ent)
        return !ent:IsPlayer()
	end
	
    trace = util.TraceLine(trace)

    if tostring(trace.Entity) == "[NULL Entity]" then
        return
    end
    
    if trace.Entity:GetClass() == "pw_paper" then
        local doc = {
            text = trace.Entity.data,
            name = trace.Entity.name,
            stamps = trace.Entity.stamps,
            stampPos = trace.Entity.stampPos,
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

    local doc = {
        text = paper.text,
        name = paper.name,
        stamps = paper.stamps,
        stampPos = paper.stampPos
    }

    if ent == Entity(-1) then
        local papr = ents.Create( "pw_paper" )
        papr:SetPos( pos )
        papr:Spawn()
        papr:SetData(doc.text, doc.name, doc.stamps, doc.stampPos, true )
    else
        if ent:GetClass() == "pw_filecabinet" then
            ent:AddPaper(doc)     
        elseif ent:GetClass() == "pw_printer" then
            if #ent.scandoc == 1 then
                local papr = ents.Create( "pw_paper" )
                papr:SetPos( pos )
                papr:Spawn()
                papr:SetData(doc.text, doc.name, doc.stamps, doc.stampPos, true)
            else
                ent.scandoc[1] = doc
            end
        else
            local papr = ents.Create( "pw_paper" )
            papr:SetPos( pos )
            papr:Spawn()
            papr:SetData(doc.text, doc.name, doc.stamps, doc.stampPos, true)
        end
    end
    self:SendCountPaper()
end

function SWEP:SecondaryAttack()
    if ( game.SinglePlayer() ) then self:CallOnClient( "SecondaryAttack" ) end

    if self.attaching then
        self.attaching = false
        return
    end

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

net.Receive("pw_cbattaching", function()
    local cb = net.ReadEntity()
    cb.attaching = true
end)
