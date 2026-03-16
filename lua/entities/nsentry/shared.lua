ENT.Type = "anim"
ENT.Base = "base_anim"
ENT.PrintName = "#nsentry"
ENT.Author = "Intel"
ENT.Category = "Tactical RP"
ENT.Spawnable = true
ENT.AdminSpawnable = true
ENT.IconOverride = "materials/entities/nsentrygun.png"

ENT.STATE_BROKEN = -1
ENT.STATE_OFF = 0
ENT.STATE_WATCHING = 1
ENT.STATE_SEARCHING = 2
ENT.STATE_ENGAGING = 3
ENT.STATE_OVERHEATED = 4

function ENT:SetupDataTables()
    self:NetworkVar("Int", 0, "State")
    self:NetworkVar("Int", 1, "HP")
    self:NetworkVar("Float", 0, "AimPitch")
    self:NetworkVar("Float", 1, "AimYaw")
    self:NetworkVar("Float", 2, "Heat")
    self:NetworkVar("Float", 3, "BarrelSpin")
end

if CLIENT then
    ENT.Information = language.GetPhrase("nsentry.description") -- Why # didnt work
end