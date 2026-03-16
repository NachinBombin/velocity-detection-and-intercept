local Colors = {
    Dark = Color(20, 20, 20, 240),
    Panel = Color(30, 30, 30, 200),
    PanelHover = Color(40, 40, 40, 220),
    Accent = Color(100, 180, 255, 200),
    ButtonNeutral = Color(100, 100, 100, 180),
    ButtonDanger = Color(160, 60, 60, 200),
    ButtonSuccess = Color(70, 160, 90, 200),
    TextPrimary = Color(220, 220, 220),
    TextSecondary = Color(150, 150, 150),
}

local Fonts = {
    Title = "DermaLarge",
    SectionHeader = "DermaDefaultBold",
    PlayerName = "DermaDefaultBold",
    Normal = "DermaDefault",
    Button = "DermaDefaultBold",
    IconLarge = "DermaLarge",
}

local PANEL = {}
function PANEL:Init()
    self:SetTitle("")
    self:SetDraggable(true)
    self:ShowCloseButton(false)
    self.StartTime = SysTime() - 1
end

function PANEL:SetSentry(sentry, data)
    self.Sentry = sentry
    self.Data = data
    self:BuildMenu()
end

function PANEL:Paint(w, h)
    Derma_DrawBackgroundBlur(self, self.StartTime)
    draw.RoundedBox(8, 0, 0, w, h, Colors.Dark)
    draw.RoundedBoxEx(8, 0, 0, w, 50, Colors.Panel, true, true, false, false)
    draw.SimpleText("#nsentry.whitelist.title", Fonts.Title, w / 2, 25, Colors.TextPrimary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    surface.SetDrawColor(Colors.PanelHover)
    surface.DrawLine(10, 50, w - 10, 50)
end

function PANEL:BuildMenu()
    local w, h = self:GetSize()
    local closeBtn = vgui.Create("DButton", self) -- Close Button
    closeBtn:SetText("")
    closeBtn:SetSize(40, 40)
    closeBtn:SetPos(w - 45, 5)
    closeBtn.Paint = function(btn, bw, bh)
        local col = btn:IsHovered() and Colors.ButtonDanger or Colors.ButtonNeutral
        draw.RoundedBox(6, 0, 0, bw, bh, col)
        surface.SetDrawColor(255, 255, 255, btn:IsHovered() and 255 or 180)
        surface.DrawLine(12, 12, bw - 12, bh - 12)
        surface.DrawLine(bw - 12, 12, 12, bh - 12)
    end

    closeBtn.DoClick = function() self:Remove() end
    local scroll = vgui.Create("DScrollPanel", self) -- Scroll Panel
    scroll:SetPos(10, 60)
    scroll:SetSize(w - 20, h - 130)
    local sbar = scroll:GetVBar()
    sbar:SetHideButtons(true)
    sbar.Paint = function(sb, sbw, sbh) draw.RoundedBox(4, sbw - 6, 0, 6, sbh, Colors.Panel) end
    sbar.btnGrip.Paint = function(sb, sbw, sbh) draw.RoundedBox(3, sbw - 6, 0, 6, sbh, Colors.ButtonNeutral) end
    self:BuildContent(scroll, w)
    local infoPanel = vgui.Create("DPanel", self) -- Info Panel
    infoPanel:SetPos(10, h - 60)
    infoPanel:SetSize(w - 20, 50)
    infoPanel.Paint = function(ip, ipw, iph)
        draw.RoundedBoxEx(6, 0, 0, ipw, iph, Colors.Panel, false, false, true, true)
        draw.SimpleText("#nsentry.whitelist.tip", Fonts.Normal, ipw / 2, iph / 2, Colors.TextSecondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end
end

function PANEL:BuildContent(scroll, panelW)
    local yOffset = 0
    local isOwner = self.Data.ownerID == LocalPlayer():SteamID64()
    yOffset = self:BuildPlayersSection(scroll, panelW, yOffset, isOwner)
    yOffset = yOffset + 15
    yOffset = self:BuildEntitiesSection(scroll, panelW, yOffset, isOwner)
    if isOwner then
        yOffset = yOffset + 15
        self:BuildAddSection(scroll, panelW, yOffset)
    end
end

function PANEL:BuildPlayersSection(scroll, panelW, yOffset, isOwner)
    local label = vgui.Create("DLabel", scroll)
    label:SetPos(10, yOffset)
    label:SetSize(panelW - 40, 30)
    label:SetFont(Fonts.SectionHeader)
    label:SetText("#nsentry.whitelist.players.title")
    label:SetTextColor(Colors.TextSecondary)
    yOffset = yOffset + 35
    if #self.Data.players == 0 then
        local noPlayers = vgui.Create("DLabel", scroll)
        noPlayers:SetPos(20, yOffset)
        noPlayers:SetSize(panelW - 60, 25)
        noPlayers:SetFont(Fonts.Normal)
        noPlayers:SetText("#nsentry.whitelist.players.empty")
        noPlayers:SetTextColor(Colors.TextSecondary)
        return yOffset + 30
    end

    for _, playerData in ipairs(self.Data.players) do
        yOffset = self:CreatePlayerPanel(scroll, panelW, yOffset, playerData, isOwner)
    end
    return yOffset
end

function PANEL:CreatePlayerPanel(scroll, panelW, yOffset, playerData, isOwner)
    local playerPanel = vgui.Create("DPanel", scroll)
    playerPanel:SetPos(10, yOffset)
    playerPanel:SetSize(panelW - 40, 60)
    playerPanel.Paint = function(pp, ppw, pph)
        local col = pp:IsHovered() and Colors.PanelHover or Colors.Panel
        draw.RoundedBox(6, 0, 0, ppw, pph, col)
        if playerData.isOwner then draw.RoundedBox(6, 0, 0, 4, pph, Colors.Accent) end
    end

    local avatar = vgui.Create("AvatarImage", playerPanel)
    avatar:SetPos(8, 8)
    avatar:SetSize(44, 44)
    avatar:SetSteamID(playerData.steamid, 64)
    local nameLabel = vgui.Create("DLabel", playerPanel)
    nameLabel:SetPos(60, 20)
    nameLabel:SetSize(panelW - 200, 20)
    nameLabel:SetFont(Fonts.PlayerName)
    nameLabel:SetText(playerData.name)
    nameLabel:SetTextColor(Colors.TextPrimary)
    if isOwner then
        local removeBtn = vgui.Create("DButton", playerPanel)
        removeBtn:SetText("#nsentry.whitelist.button.remove")
        removeBtn:SetPos(panelW - 140, 15)
        removeBtn:SetSize(90, 30)
        removeBtn:SetFont(Fonts.Button)
        removeBtn:SetTextColor(color_white)
        removeBtn.Paint = function(btn, bw, bh)
            local col = btn:IsHovered() and Color(200, 80, 80, 220) or Colors.ButtonDanger
            draw.RoundedBox(4, 0, 0, bw, bh, col)
        end

        removeBtn.DoClick = function() self:RemovePlayer(playerData.steamid) end
    end
    return yOffset + 65
end

function PANEL:BuildEntitiesSection(scroll, panelW, yOffset, isOwner)
    local label = vgui.Create("DLabel", scroll)
    label:SetPos(10, yOffset)
    label:SetSize(panelW - 40, 30)
    label:SetFont(Fonts.SectionHeader)
    label:SetText("#nsentry.whitelist.entities.title")
    label:SetTextColor(Colors.TextSecondary)
    yOffset = yOffset + 35
    if #self.Data.classes == 0 then
        local noClasses = vgui.Create("DLabel", scroll)
        noClasses:SetPos(20, yOffset)
        noClasses:SetSize(panelW - 60, 25)
        noClasses:SetFont(Fonts.Normal)
        noClasses:SetText("#nsentry.whitelist.entities.empty")
        noClasses:SetTextColor(Colors.TextSecondary)
        return yOffset + 30
    end

    for _, class in ipairs(self.Data.classes) do
        yOffset = self:CreateEntityPanel(scroll, panelW, yOffset, class, isOwner)
    end
    return yOffset
end

function PANEL:CreateEntityPanel(scroll, panelW, yOffset, class, isOwner)
    local classPanel = vgui.Create("DPanel", scroll)
    classPanel:SetPos(10, yOffset)
    classPanel:SetSize(panelW - 40, 60)
    classPanel.Paint = function(cp, cpw, cph)
        local col = cp:IsHovered() and Colors.PanelHover or Colors.Panel
        draw.RoundedBox(6, 0, 0, cpw, cph, col)
    end

    local modelIcon, printName = self:GetEntityInfo(class)
    local modelMat = modelIcon and Material(modelIcon) or nil
    local iconPanel = vgui.Create("DPanel", classPanel)
    iconPanel:SetPos(8, 8)
    iconPanel:SetSize(44, 44)
    iconPanel.Paint = function(ic, icw, ich)
        draw.RoundedBox(4, 0, 0, icw, ich, Colors.Dark)
        if modelMat and not modelMat:IsError() then
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(modelMat)
            local matW, matH = modelMat:Width(), modelMat:Height()
            local scale = math.min((icw - 4) / matW, (ich - 4) / matH)
            local drawW, drawH = matW * scale, matH * scale
            local offsetX, offsetY = (icw - drawW) / 2, (ich - drawH) / 2
            surface.DrawTexturedRect(offsetX, offsetY, drawW, drawH)
        else
            draw.SimpleText("?", Fonts.IconLarge, icw / 2, ich / 2, Colors.TextSecondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        end
    end

    local nameLabel = vgui.Create("DLabel", classPanel)
    nameLabel:SetPos(60, 12)
    nameLabel:SetSize(panelW - 220, 20)
    nameLabel:SetFont(Fonts.Normal)
    nameLabel:SetText(printName and printName ~= "" and printName or class)
    nameLabel:SetTextColor(Colors.TextPrimary)
    local classLabel = vgui.Create("DLabel", classPanel)
    classLabel:SetPos(60, 32)
    classLabel:SetSize(panelW - 220, 20)
    classLabel:SetFont(Fonts.Normal)
    classLabel:SetText(class)
    classLabel:SetTextColor(Colors.TextSecondary)
    if isOwner then
        local removeBtn = vgui.Create("DButton", classPanel)
        removeBtn:SetText("#nsentry.whitelist.button.remove")
        removeBtn:SetPos(panelW - 140, 15)
        removeBtn:SetSize(90, 30)
        removeBtn:SetFont(Fonts.Button)
        removeBtn:SetTextColor(color_white)
        removeBtn.Paint = function(btn, bw, bh)
            local col = btn:IsHovered() and Color(200, 80, 80, 220) or Colors.ButtonDanger
            draw.RoundedBox(4, 0, 0, bw, bh, col)
        end

        removeBtn.DoClick = function() self:RemoveClass(class) end
    end
    return yOffset + 65
end

function PANEL:GetEntityInfo(class)
    local modelIcon = nil
    local printName = nil
    local modelPath = nil
    local npcData = list.Get("NPC")[class] -- Check NPC list
    if npcData then
        printName = npcData.Name
        modelPath = npcData.Model
    end

    local entList = list.Get("SpawnableEntities")[class] -- Check SpawnableEntities list
    if entList then
        printName = printName or entList.PrintName
        modelPath = modelPath or entList.Model
    end

    local sentData = scripted_ents.GetList()[class] -- Check scripted entities
    if sentData and sentData.t then
        printName = printName or sentData.t.PrintName
        modelPath = modelPath or sentData.t.Model
    end

    if modelPath then -- Generate spawnicon path from model
        local processedPath = string.lower(modelPath)
        processedPath = string.gsub(processedPath, "\\", "/")
        processedPath = string.gsub(processedPath, "%.mdl$", "")
        local spawnIconPath = "spawnicons/" .. processedPath .. ".png"
        if not Material(spawnIconPath):IsError() then modelIcon = spawnIconPath end
    end
    return modelIcon, printName
end

function PANEL:BuildAddSection(scroll, panelW, yOffset)
    local addPanel = vgui.Create("DPanel", scroll)
    addPanel:SetPos(10, yOffset)
    addPanel:SetSize(panelW - 40, 50)
    addPanel.Paint = function(ap, apw, aph) draw.RoundedBox(6, 0, 0, apw, aph, Colors.Panel) end
    local addEntry = vgui.Create("DTextEntry", addPanel)
    addEntry:SetPos(10, 10)
    addEntry:SetSize(addPanel:GetWide() - 110, 30)
    addEntry:SetFont(Fonts.Normal)
    addEntry:SetPlaceholderText("#nsentry.whitelist.input.placeholder")
    addEntry:SetDrawLanguageID(false)
    addEntry.Paint = function(ae, aew, aeh)
        draw.RoundedBox(4, 0, 0, aew, aeh, Colors.Dark)
        ae:DrawTextEntryText(Colors.TextPrimary, Colors.Accent, Colors.TextPrimary)
    end

    local addBtn = vgui.Create("DButton", addPanel)
    addBtn:SetText("#nsentry.whitelist.button.add")
    addBtn:SetPos(addPanel:GetWide() - 90, 10)
    addBtn:SetSize(80, 30)
    addBtn:SetFont(Fonts.Button)
    addBtn:SetTextColor(color_white)
    addBtn.Paint = function(btn, bw, bh)
        local col = btn:IsHovered() and Color(90, 200, 110, 220) or Colors.ButtonSuccess
        draw.RoundedBox(4, 0, 0, bw, bh, col)
    end

    addBtn.DoClick = function()
        local class = string.Trim(addEntry:GetValue())
        if class and class ~= "" then
            self:AddClass(class)
            addEntry:SetValue("")
            addEntry:KillFocus()
        end
    end

    addEntry.OnEnter = function() addBtn:DoClick() end
end

function PANEL:AddClass(class)
    if not IsValid(self.Sentry) then return end
    net.Start("NSentryWhitelistAdd")
    net.WriteEntity(self.Sentry)
    net.WriteString(class)
    net.SendToServer()
end

function PANEL:RemovePlayer(steamid)
    if not IsValid(self.Sentry) then return end
    net.Start("NSentryWhitelistRemove")
    net.WriteEntity(self.Sentry)
    net.WriteString("player")
    net.WriteString(steamid)
    net.SendToServer()
end

function PANEL:RemoveClass(class)
    if not IsValid(self.Sentry) then return end
    net.Start("NSentryWhitelistRemove")
    net.WriteEntity(self.Sentry)
    net.WriteString("class")
    net.WriteString(class)
    net.SendToServer()
end

vgui.Register("NNSentryWhitelist", PANEL, "DFrame")