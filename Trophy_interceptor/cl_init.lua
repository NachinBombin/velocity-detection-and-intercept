include("shared.lua")

function ENT:Draw()
    self:DrawModel()

    -- Optional: Add a small red glow to indicate it's active
    local dlight = DynamicLight(self:EntIndex())
    if dlight then
        dlight.pos = self:GetPos()
        dlight.r = 255
        dlight.g = 50
        dlight.b = 0
        dlight.brightness = 2
        dlight.Decay = 1000
        dlight.Size = 128
        dlight.DieTime = CurTime() + 1
    end
end
