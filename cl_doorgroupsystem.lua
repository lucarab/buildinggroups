if not CLIENT or not DarkRP then return end

local cachedPlayer = nil
local function GetCachedPlayer()
    if not IsValid(cachedPlayer) then
        cachedPlayer = LocalPlayer()
    end
    return cachedPlayer
end

-------------------------------------------------------------------------------
-- Schriftdefinitionen
-------------------------------------------------------------------------------
surface.CreateFont("DGSTitleFont", {
    font = "Roboto",
    size = 20,
    weight = 600,
    extended = true
})

surface.CreateFont("DGSPriceFont", {
    font = "Derma",
    size = 18,
    weight = 600
})

surface.CreateFont("DGSTextFont", {
    font = "Derma",
    size = 17,
})

-------------------------------------------------------------------------------
-- Gebäudedaten, Cache und Lookup-Tabelle
-------------------------------------------------------------------------------
local ClientBuildings = {}
local CachedBuildingDoorEntities = {}
local DoorIDToBuilding = {}

net.Receive("DoorGroupSystem_Buildings", function()
    local data = net.ReadTable()
    ClientBuildings = data.buildings or {}

    for bName, building in pairs(ClientBuildings) do
        CachedBuildingDoorEntities[bName] = {}
        for _, doorID in ipairs(building.doors or {}) do
            DoorIDToBuilding[doorID] = bName
            local doorEnt = ents.GetMapCreatedEntity(doorID)
            if IsValid(doorEnt) and doorEnt:isDoor() then
                table.insert(CachedBuildingDoorEntities[bName], doorEnt)
            end
        end
    end
end)

local function GetBuildingNameByDoor(doorEnt)
    if not IsValid(doorEnt) then return nil end
    return DoorIDToBuilding[doorEnt:MapCreationID()]
end

-------------------------------------------------------------------------------
-- Zeichnen eines Textfeldes
-------------------------------------------------------------------------------
local function drawTextBox(x, y, w, h, lines)
    local bgColor = Color(20, 20, 20, 220)
    draw.RoundedBox(8, x, y, w, h, bgColor)
    local centerX = x + w / 2
    local offsetY = 20
    for _, line in ipairs(lines) do
        draw.SimpleText(line.text, line.font, centerX, y + offsetY, line.color, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
        offsetY = offsetY + (line.spacing or 20)
    end
end

-------------------------------------------------------------------------------
-- HUD-Überschreibung für Gebäude
-------------------------------------------------------------------------------
hook.Add("HUDDrawDoorData", "CustomHUDDrawDoorData", function(ent)
    if not (IsValid(ent) and ent:isDoor()) then return end

    local ply = GetCachedPlayer()
    if ply:InVehicle() and not ply:GetAllowWeaponsInVehicle() then return end

    local bName = GetBuildingNameByDoor(ent)
    local doorGroup    = ent:getKeysDoorGroup()
    local doorTeams    = ent:getKeysDoorTeams()
    local coOwners     = ent:getKeysCoOwners() or {}
    local allowedCoOwn = ent:getKeysAllowedToOwn() or {}
    local doorOwner    = ent:getDoorOwner()
    local isPlayerOwned = ent:isKeysOwned() or next(coOwners) ~= nil
    local isOwned      = isPlayerOwned or doorGroup or doorTeams

    local mainW   = 300
    local mainX   = (ScrW() - mainW) / 2
    local mainY   = (ScrH() / 2) - 50
    local spacing = 10

    local currentY = mainY
    local bData    = ClientBuildings[bName]
    local price    = bData and DoorGroupSystem:CalculateBuildingPrice(bData) or 0
    local doorCount = bData and ((#(bData.doors or {}) > 0 and #bData.doors) or 1) or 1

    if not (doorGroup or doorTeams) then
        if not bName then return end

        local doorTitle   = ent:getKeysTitle()
        local displayText = doorTitle or bName
        local maxWidth    = mainW - 20

        surface.SetFont("DGSTitleFont")
        local textWidth = surface.GetTextSize(displayText)
        if textWidth > maxWidth then
            local ellipsis = "..."
            local ellipsisWidth = surface.GetTextSize(ellipsis)
            local trimmedText = displayText
            while surface.GetTextSize(trimmedText) + ellipsisWidth > maxWidth and #trimmedText > 0 do
                trimmedText = string.sub(trimmedText, 1, #trimmedText - 1)
            end
            displayText = trimmedText .. ellipsis
        end

        drawTextBox(mainX, currentY, mainW, 40, {
            { text = displayText, font = "DGSTitleFont", color = Color(220, 220, 220) }
        })
        currentY = currentY + 40 + spacing

        if not isOwned then
            drawTextBox(mainX, currentY, mainW, 60, {
                { text = "Preis: $" .. price, font = "DGSPriceFont", color = Color(100, 220, 100) },
                { text = "Anzahl der Türen: " .. doorCount, font = "DGSPriceFont", color = Color(70, 130, 180) }
            })
            currentY = currentY + 60 + spacing
            drawTextBox(mainX, currentY, mainW, 40, {
                { text = "Drücke (F2), um dieses Gebäude zu kaufen", font = "DGSTextFont", color = Color(220, 220, 220) }
            })
            currentY = currentY + 40 + spacing
        elseif isPlayerOwned then
            local ownerLines = {
                { text = "Besitzer:", font = "DGSPriceFont", color = Color(220, 220, 220) }
            }
            if IsValid(doorOwner) then
                table.insert(ownerLines, { text = doorOwner:Nick(), font = "DGSTextFont", color = Color(220, 220, 220) })
            end
            for steamID in pairs(coOwners) do
                local coPly = Player(steamID)
                if IsValid(coPly) then
                    table.insert(ownerLines, { text = coPly:Nick(), font = "DGSTextFont", color = Color(220, 220, 220) })
                end
            end
            if next(allowedCoOwn) then
                table.insert(ownerLines, { text = "Erlaubte Mitbesitzer:", font = "DGSPriceFont", color = Color(220, 220, 220) })
                for steamID in pairs(allowedCoOwn) do
                    local allowPly = Player(steamID)
                    if IsValid(allowPly) then
                        table.insert(ownerLines, { text = allowPly:Nick(), font = "DGSTextFont", color = Color(220, 220, 220) })
                    end
                end
            end
            local ownerBoxHeight = (#ownerLines * 20) + 20
            drawTextBox(mainX, currentY, mainW, ownerBoxHeight, ownerLines)
            currentY = currentY + ownerBoxHeight + spacing
        end
    else
        if doorGroup then
            drawTextBox(mainX, currentY, mainW, 60, {
                { text = "Besitzer:", font = "DGSPriceFont", color = Color(220, 220, 220) },
                { text = doorGroup, font = "DGSTextFont", color = Color(220, 220, 220) }
            })
            currentY = currentY + 60 + spacing
        elseif doorTeams then
            local teamLines = {
                { text = "Besitzer:", font = "DGSPriceFont", color = Color(220, 220, 220) }
            }
            for k, v in pairs(doorTeams) do
                if v and RPExtraTeams[k] then
                    table.insert(teamLines, {
                        text = RPExtraTeams[k].name,
                        font = "DGSTextFont",
                        color = Color(220, 220, 220)
                    })
                end
            end
            local teamBoxHeight = (#teamLines * 20) + 20
            drawTextBox(mainX, currentY, mainW, teamBoxHeight, teamLines)
            currentY = currentY + teamBoxHeight + spacing
        end
    end

    return true
end)

-------------------------------------------------------------------------------
-- Halo-Effekt für unbesessene Gebäude
-------------------------------------------------------------------------------
local MAX_DISTANCE = 200
hook.Add("PreDrawHalos", "DoorGroupSystem_HighlightUnownedDoors", function()
    local ply = GetCachedPlayer()
    if not IsValid(ply) then return end

    local trace = ply:GetEyeTrace()
    if not (trace.Hit and IsValid(trace.Entity)) then return end

    local door = trace.Entity
    if not door:isDoor() then return end
    if door:GetPos():DistToSqr(ply:GetPos()) > (MAX_DISTANCE * MAX_DISTANCE) then return end
    if IsValid(door:getDoorOwner()) then return end

    local bName = GetBuildingNameByDoor(door)
    if not bName then return end

    local doorEnts = CachedBuildingDoorEntities[bName]
    if doorEnts and #doorEnts > 0 then
        halo.Add(doorEnts, Color(255, 0, 0), 2, 2, 1, false, true)
    end
end)
