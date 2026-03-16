AddCSLuaFile("cl_init.lua")
AddCSLuaFile("shared.lua")
include("shared.lua")

local SCAN_RADIUS = 600
local SCAN_INTERVAL = 0.01 
local MIN_SPEED = 1100
local INTERCEPT_DELAY = 0.04 

local RADAR_LOOP = "npc/turret_floor/ping.wav"
local LOCK_SOUNDS = { "npc/turret_floor/active.wav", "npc/scanner/scanner_scan2.wav" }
local INTERCEPT_SOUNDS = { "ambient/explosions/explode_4.wav", "ambient/explosions/explode_5.wav", "weapons/stinger/fire.wav", "weapons/shotgun/shotgun_fire7.wav" }
local ELECTRONIC_DISRUPT = { "npc/roller/mine/rmine_blip3.wav", "npc/roller/mine/rmine_explode_shock1.wav" }

local INTERCEPT_TARGETS = {
    ["rpg_missile"] = true, ["grenade_ar2"] = true, ["npc_grenade_frag"] = true,
    ["prop_combine_ball"] = true, ["hunter_flechette"] = true, ["crossbow_bolt"] = true, 
    ["grenade_helicopter"] = true, ["combine_mine"] = true, ["npc_satchel"] = true, 
    ["satchel_charge"] = true, ["obj_vj_grenade"] = true, ["obj_vj_rocket"] = true, 
    ["obj_vj_flechette"] = true, ["sent_javelin_missile"] = true, ["sent_stinger_missile"] = true,
    ["neuro_missile"] = true, ["neuro_rocket"] = true, ["m9k_released_rpg"] = true, 
    ["m9k_davy_crockett_payload"] = true, ["m9k_40mm_grenade"] = true, ["m9k_mad_grenade"] = true,
    ["cw_grenade_thrown"] = true, ["fas2_thrown_m67"] = true, ["wac_hc_rocket"] = true, ["lvs_missile"] = true
}

function ENT:StartRadarLoop()
    if self.RadarSound then return end
    self.RadarSound = CreateSound(self, RADAR_LOOP)
    if self.RadarSound then self.RadarSound:PlayEx(0.6, 110) end
end
function ENT:StopRadarLoop()
    if self.RadarSound then self.RadarSound:Stop() self.RadarSound = nil end
end
function ENT:PlayLockSound()
    for _, snd in ipairs(LOCK_SOUNDS) do self:EmitSound(snd, 80, 120) end
end
function ENT:PlayInterceptSounds()
    for _, snd in ipairs(INTERCEPT_SOUNDS) do self:EmitSound(snd, 95, math.random(95,105)) end
    for _, snd in ipairs(ELECTRONIC_DISRUPT) do self:EmitSound(snd, 85, math.random(105,120)) end
end

function ENT:Initialize()
    self:SetModel("models/props_phx/gears/bevel90_24.mdl") 
    self:PhysicsInit(SOLID_VPHYSICS)
    self:SetMoveType(MOVETYPE_VPHYSICS)
    self:SetSolid(SOLID_VPHYSICS)
    self:SetUseType(SIMPLE_USE) 
    self:UseTriggerBounds(true, 24)
    
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        phys:Wake()
        phys:SetMass(150)
        phys:SetMaterial("metal")
    end

    self:SetColor(Color(255, 100, 0)) 
    self:SetMaxHealth(50)
    self:SetHealth(50)

    self.IsLocked = false
    self.LockedTarget = nil
    self.FireTime = 0

    self:StartRadarLoop()
end

function ENT:Use(activator, caller)
    if IsValid(activator) and activator:IsPlayer() then
        activator.APS_Queue = activator.APS_Queue or {}
        table.insert(activator.APS_Queue, "trophy_interceptor")
        
        activator:EmitSound("items/ammo_pickup.wav", 80, 100)
        activator:ChatPrint("Picked up Infinite APS. T" .. #activator.APS_Queue)
        
        self:Remove()
    end
end

function ENT:OnTakeDamage(dmginfo)
    self:TakePhysicsDamage(dmginfo)
    self:SetHealth(self:Health() - dmginfo:GetDamage())
    if self:Health() <= 0 then self:SelfDestruct(false) end
end

function ENT:Think()
    if self.RadarSound then self.RadarSound:ChangePitch(math.random(105, 115), 0) end

    if self.IsLocked then
        if not IsValid(self.LockedTarget) then
            self.IsLocked = false
            self.LockedTarget = nil
        elseif CurTime() >= self.FireTime then
            self:Intercept(self.LockedTarget)
        end
        self:NextThink(CurTime() + SCAN_INTERVAL)
        return true
    end

    local entities = ents.FindInSphere(self:GetPos(), SCAN_RADIUS)
    for _, ent in ipairs(entities) do
        if IsValid(ent) and ent != self and ent != self:GetOwner() and ent:GetClass() != self:GetClass() then
            local class = string.lower(ent:GetClass())
            local isThreat = false

            if INTERCEPT_TARGETS[class] then isThreat = true
            elseif string.find(class, "missile") or string.find(class, "rocket") or string.find(class, "grenade") then isThreat = true
            elseif ent.Base == "sent_neuro_missile_base" or ent.Base == "sent_neuro_missile" then isThreat = true
            else
                local vel = ent:GetVelocity()
                if vel:Length() > MIN_SPEED and not ent:IsPlayer() and not ent:IsVehicle() then
                    if (ent:GetPos() - self:GetPos()):GetNormalized():Dot(vel:GetNormalized()) < -0.1 then isThreat = true end
                end
            end

            if isThreat then
                self.IsLocked = true
                self.LockedTarget = ent
                self.FireTime = CurTime() + INTERCEPT_DELAY
                self:PlayLockSound()
                break 
            end
        end
    end
    self:NextThink(CurTime() + SCAN_INTERVAL)
    return true
end

function ENT:Intercept(target)
    local targetPos = target:GetPos()
    local myPos = self:GetPos()
    if target.Destroyed != nil then target.Destroyed = true end
    if target.ExplodeCallback then target.ExplodeCallback = nil end

    local dir = (targetPos - myPos):GetNormalized()
    local flash = EffectData() flash:SetOrigin(myPos) flash:SetNormal(dir) flash:SetScale(2) util.Effect("MuzzleEffect", flash)

    for i=1, 8 do
        local sparks = EffectData() sparks:SetOrigin(myPos + dir * 10) sparks:SetNormal(dir + VectorRand() * 0.1) sparks:SetMagnitude(2) sparks:SetScale(1) util.Effect("MetalSparks", sparks)
    end

    local tracer = EffectData() tracer:SetOrigin(targetPos) tracer:SetStart(myPos) util.Effect("ToolTracer", tracer)
    local explosion = EffectData() explosion:SetOrigin(targetPos) util.Effect("Explosion", explosion)

    self:PlayInterceptSounds()
    util.ScreenShake(myPos, 20, 250, 0.7, 1500)
    for _, ply in ipairs(player.GetAll()) do if ply:GetPos():Distance(myPos) < 500 then ply:SetVelocity(VectorRand() * 200) end end

    SafeRemoveEntity(target)
    
    self.IsLocked = false
    self.LockedTarget = nil
end

function ENT:SelfDestruct(success)
    local ed = EffectData() ed:SetOrigin(self:GetPos()) util.Effect("cball_explode", ed) self:Remove()
end
function ENT:OnRemove() self:StopRadarLoop() end
