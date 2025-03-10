if not DarkRP then return end

-------------------------------------------------------------------------------
-- Variablen und Netzwerk-Setup
-------------------------------------------------------------------------------
if not file.IsDir("doorgroupsystem", "DATA") then
    file.CreateDir("doorgroupsystem")
end

DoorGroupSystem = DoorGroupSystem or {}
DoorGroupSystem.DataFile = "doorgroupsystem/doorgroups_" .. game.GetMap() .. ".json"
DoorGroupSystem.Buildings = DoorGroupSystem.Buildings or {}
DoorGroupSystem.DoorToBuildingMapping = {}

util.AddNetworkString("DoorGroupSystem_Buildings")

-------------------------------------------------------------------------------
-- Hilfsfunktionen
-------------------------------------------------------------------------------
function DoorGroupSystem:ForEachDoorInBuilding(buildingName, callback)
    local building = self.Buildings[buildingName]
    if not (building and building.doors) then return end
    for _, doorID in ipairs(building.doors) do
        local doorEnt = ents.GetMapCreatedEntity(doorID)
        if IsValid(doorEnt) and doorEnt:isDoor() then
            callback(doorEnt)
        end
    end
end

function DoorGroupSystem:RebuildDoorMapping()
    self.DoorToBuildingMapping = {}
    for bName, data in pairs(self.Buildings) do
        if data.doors then
            for _, doorID in ipairs(data.doors) do
                self.DoorToBuildingMapping[doorID] = bName
            end
        end
    end
end

function DoorGroupSystem:CountBuildingsOwnedBy(ply)
    local count = 0
    for _, building in pairs(self.Buildings) do
        if building.doors then
            for _, doorID in ipairs(building.doors) do
                local doorEnt = ents.GetMapCreatedEntity(doorID)
                if IsValid(doorEnt) and doorEnt:isMasterOwner(ply) then
                    count = count + 1
                    break
                end
            end
        end
    end
    return count
end

-------------------------------------------------------------------------------
-- Map File Laden & Speichern
-------------------------------------------------------------------------------
function DoorGroupSystem:LoadBuildings()
    if not file.Exists(self.DataFile, "DATA") then
        print("[DoorGroupSystem] " .. self.DataFile .. " nicht gefunden; erstelle eine neue Datei...")
        self.Buildings = {}
        self:SaveBuildings()
        return
    end

    local jsonData = file.Read(self.DataFile, "DATA")
    if not jsonData or jsonData == "" then
        print("[DoorGroupSystem] " .. self.DataFile .. " ist leer oder ungültig.")
        self.Buildings = {}
        return
    end

    local loaded = util.JSONToTable(jsonData)
    if loaded then
        self.Buildings = loaded
        self:RebuildDoorMapping()
        print("[DoorGroupSystem] Gebäudedaten erfolgreich geladen.")
    else
        print("[DoorGroupSystem] Fehler beim Parsen von " .. self.DataFile .. " (ungültiges JSON?).")
    end
end

function DoorGroupSystem:SaveBuildings()
    local jsonData = util.TableToJSON(self.Buildings, true)
    file.Write(self.DataFile, jsonData)
    print("[DoorGroupSystem] Gebäudedaten gespeichert.")
end

-------------------------------------------------------------------------------
-- Core: Erstellen von Gebäuden, Hinzufügen von Türen, Besitz
-------------------------------------------------------------------------------
function DoorGroupSystem:CreateBuilding(buildingName, price, doorFactor)
    if self.Buildings[buildingName] then
        return false, "Ein Gebäude mit diesem Namen existiert bereits."
    end

    self.Buildings[buildingName] = {
        price = price,
        doorFactor = doorFactor or self.DoorFactor,
        doors = {}
    }
    self:SaveBuildings()
    return true, ("Gebäude '%s' erstellt mit Grundpreis $%d und Türpreis $%d."):format(
        buildingName, price, doorFactor or self.DoorFactor
    )
end

function DoorGroupSystem:AddDoorToBuilding(buildingName, doorEnt)
    if not (IsValid(doorEnt) and doorEnt:isDoor()) then
        return false, "Das anvisierte Objekt ist keine gültige Tür."
    end

    local mapID = doorEnt:MapCreationID()
    if mapID == -1 then
        return false, "Die Tür hat eine ungültige MapCreationID (möglicherweise eine dynamische Tür)."
    end

    local building = self.Buildings[buildingName]
    if not building then
        return false, ("Das Gebäude '%s' existiert nicht."):format(buildingName)
    end

    if self.DoorToBuildingMapping[mapID] then
        return false, "Diese Tür ist bereits einer Gebäudengruppe zugeordnet."
    end

    building.doors = building.doors or {}
    table.insert(building.doors, mapID)
    self.DoorToBuildingMapping[mapID] = buildingName
    self:SaveBuildings()
    return true, ("Tür (ID %d) wurde dem Gebäude '%s' hinzugefügt."):format(mapID, buildingName)
end

function DoorGroupSystem:GetBuildingFromDoor(doorEnt)
    if not (IsValid(doorEnt) and doorEnt:isDoor()) then return nil end
    return self.DoorToBuildingMapping[doorEnt:MapCreationID()]
end

-------------------------------------------------------------------------------
-- Netzwerk: Senden von Gebäudedaten an Clients
-------------------------------------------------------------------------------
function DoorGroupSystem:SendBuildingsToClient(ply)
    net.Start("DoorGroupSystem_Buildings")
    net.WriteTable({
        buildings = self.Buildings,
        doorFactor = self.DoorFactor
    })
    net.Send(ply)
end

function DoorGroupSystem:BroadcastBuildings()
    for _, pl in ipairs(player.GetAll()) do
        self:SendBuildingsToClient(pl)
    end
end

-------------------------------------------------------------------------------
-- Admin-Chat-Befehle
-------------------------------------------------------------------------------
local function requireAdmin(ply)
    if not ply:IsSuperAdmin() then
        DarkRP.notify(ply, 1, 4, "Du hast keine Berechtigung dafür.")
        return false
    end
    return true
end

local function parseArgs(args)
    args = string.Trim(args or "")
    if args == "" then return nil, nil, "Keine Argumente angegeben." end

    local firstChar = args:sub(1, 1)
    local buildingName, remainder

    if firstChar == '"' or firstChar == "'" then
        local closingQuote = args:find(firstChar, 2)
        if not closingQuote then return nil, nil, "Ungültige Syntax: Fehlendes schließendes Anführungszeichen." end
        buildingName = args:sub(2, closingQuote - 1)
        remainder = string.Trim(args:sub(closingQuote + 1))
    else
        local parts = string.Explode(" ", args)
        buildingName = parts[1] or ""
        remainder = args:sub(#buildingName + 1)
    end

    return buildingName, remainder
end

DarkRP.defineChatCommand("createbuilding", function(ply, args)
    if not requireAdmin(ply) then return "" end

    local buildingName, remainder, err = parseArgs(args)
    if err or not buildingName or buildingName == "" then
        DarkRP.notify(ply, 1, 4, "Syntax: /createbuilding \"<Name>\" <Grundpreis> <Türpreis>")
        return ""
    end

    local priceStr, doorFactorStr = string.match(remainder, "^(%S+)%s+(%S+)")
    local price = tonumber(priceStr)
    local doorFactor = tonumber(doorFactorStr)

    if not (price and doorFactor) then
        DarkRP.notify(ply, 1, 4, "Syntax: /createbuilding \"<Name>\" <Grundpreis> <Türpreis>")
        return ""
    end

    local success, msg = DoorGroupSystem:CreateBuilding(buildingName, price, doorFactor)
    DarkRP.notify(ply, success and 0 or 1, 4, msg)
    if success then
        DoorGroupSystem:BroadcastBuildings()
    end
    return ""
end)

DarkRP.defineChatCommand("setbuildingprice", function(ply, args)
    if not requireAdmin(ply) then return "" end

    local buildingName, remainder, err = parseArgs(args)
    if err or not buildingName or buildingName == "" then
        DarkRP.notify(ply, 1, 4, "Syntax: /setbuildingprice \"<Gebäudename>\" <NeuerGrundpreis> <NeuerTürpreis>")
        return ""
    end

    local priceStr, doorFactorStr = string.match(remainder, "^(%S+)%s+(%S+)")
    local newPrice = tonumber(priceStr)
    local newDoorFactor = tonumber(doorFactorStr)

    if not (newPrice and newDoorFactor) then
        DarkRP.notify(ply, 1, 4, "Syntax: /setbuildingprice \"<Gebäudename>\" <NeuerGrundpreis> <NeuerTürpreis>")
        return ""
    end

    if not DoorGroupSystem.Buildings[buildingName] then
        DarkRP.notify(ply, 1, 4, "Gebäude '" .. buildingName .. "' existiert nicht.")
        return ""
    end

    DoorGroupSystem.Buildings[buildingName].price = newPrice
    DoorGroupSystem.Buildings[buildingName].doorFactor = newDoorFactor
    DoorGroupSystem:SaveBuildings()
    DarkRP.notify(ply, 0, 4, ("Grundpreis von '%s' wurde auf $%d gesetzt und Türpreis auf $%d."):format(buildingName, newPrice, newDoorFactor))
    DoorGroupSystem:BroadcastBuildings()
    return ""
end)

DarkRP.defineChatCommand("adddoor", function(ply, args)
    if not requireAdmin(ply) then return "" end

    local buildingName, _, err = parseArgs(args)
    if err or not buildingName or buildingName == "" then
        DarkRP.notify(ply, 1, 4, "Syntax: /adddoor \"<Gebäudename>\"")
        return ""
    end

    local trace = ply:GetEyeTrace()
    if not (trace and IsValid(trace.Entity)) then
        DarkRP.notify(ply, 1, 4, "Du musst auf eine gültige Tür schauen.")
        return ""
    end

    local success, msg = DoorGroupSystem:AddDoorToBuilding(buildingName, trace.Entity)
    DarkRP.notify(ply, success and 0 or 1, 4, msg)
    if success then
        DoorGroupSystem:BroadcastBuildings()
    end
    return ""
end)

DarkRP.defineChatCommand("deletebuilding", function(ply, args)
    if not requireAdmin(ply) then return "" end

    local buildingName, _, err = parseArgs(args)
    if err or not buildingName or buildingName == "" then
        DarkRP.notify(ply, 1, 4, "Syntax: /deletebuilding \"<Gebäudename>\"")
        return ""
    end

    if not DoorGroupSystem.Buildings[buildingName] then
        DarkRP.notify(ply, 1, 4, ("Gebäude '%s' existiert nicht."):format(buildingName))
        return ""
    end

    DoorGroupSystem.Buildings[buildingName] = nil
    DoorGroupSystem:RebuildDoorMapping()
    DoorGroupSystem:SaveBuildings()
    DarkRP.notify(ply, 0, 4, ("Gebäude '%s' wurde gelöscht."):format(buildingName))
    DoorGroupSystem:BroadcastBuildings()
    return ""
end)

DarkRP.defineChatCommand("renamebuilding", function(ply, args)
    if not requireAdmin(ply) then return "" end

    local oldName, remainder, err = parseArgs(args)
    if err or not oldName or oldName == "" then
        DarkRP.notify(ply, 1, 4, "Syntax: /renamebuilding \"<AlterName>\" \"<NeuerName>\"")
        return ""
    end

    local newName = string.match(string.Trim(remainder or ""), "^(\"[^\"]+\"|'[^']+'|%S+)")
    if newName then
        newName = newName:gsub('^["\']', ''):gsub('["\']$', '')
    end

    if not (newName and newName ~= "") then
        DarkRP.notify(ply, 1, 4, "Syntax: /renamebuilding \"<AlterName>\" \"<NeuerName>\"")
        return ""
    end

    if not DoorGroupSystem.Buildings[oldName] then
        DarkRP.notify(ply, 1, 4, ("Gebäude '%s' existiert nicht."):format(oldName))
        return ""
    end

    if DoorGroupSystem.Buildings[newName] then
        DarkRP.notify(ply, 1, 4, ("Gebäude '%s' existiert bereits."):format(newName))
        return ""
    end

    local buildingData = DoorGroupSystem.Buildings[oldName]
    DoorGroupSystem.Buildings[newName] = buildingData
    DoorGroupSystem.Buildings[oldName] = nil

    if buildingData.doors then
        for _, doorID in ipairs(buildingData.doors) do
            DoorGroupSystem.DoorToBuildingMapping[doorID] = newName
        end
    end

    DoorGroupSystem:SaveBuildings()
    DarkRP.notify(ply, 0, 4, ("Gebäude umbenannt von '%s' zu '%s'."):format(oldName, newName))
    DoorGroupSystem:BroadcastBuildings()
    return ""
end)

DarkRP.defineChatCommand("reloadbuildings", function(ply)
    if not requireAdmin(ply) then return "" end
    DoorGroupSystem:LoadBuildings()
    DoorGroupSystem:BroadcastBuildings()
    DarkRP.notify(ply, 2, 4, "Gebäudengruppen neu geladen.")
    return ""
end)

-------------------------------------------------------------------------------
-- Hooks: Initialisierung & Spielersynchronisation
-------------------------------------------------------------------------------
hook.Add("Initialize", "DoorGroupSystem_Init", function()
    DoorGroupSystem:LoadBuildings()
end)

hook.Add("PlayerInitialSpawn", "DoorGroupSystem_PlayerInitSpawn", function(ply)
    DoorGroupSystem:SendBuildingsToClient(ply)
end)

-------------------------------------------------------------------------------
-- Überschreiben der Entity-Metatable für Türvorgänge
-------------------------------------------------------------------------------
local ENT = FindMetaTable("Entity")
if ENT then
    local function wrapDoorGroupFunction(funcName)
        local original = ENT[funcName]
        if original then
            ENT[funcName] = function(self, ply)
                -- Bei Aufruf für eine Tür in einem Gebäude,
                -- wende die Funktion auf alle Türen dieses Gebäudes an
                original(self, ply)
                local buildingName = DoorGroupSystem:GetBuildingFromDoor(self)
                if buildingName then
                    DoorGroupSystem:ForEachDoorInBuilding(buildingName, function(doorEnt)
                        original(doorEnt, ply)
                    end)
                end
            end
        end
    end

    local doorFuncs = {
        "addKeysAllowedToOwn", "removeKeysAllowedToOwn", "removeKeysDoorOwner",
        "keysOwn", "keysUnOwn", "addKeysDoorOwner", "removeAllKeysExtraOwners",
        "removeAllKeysAllowedToOwn"
    }
    for _, funcName in ipairs(doorFuncs) do
        wrapDoorGroupFunction(funcName)
    end

    function ENT:FireBuilding(command, arg, delay)
        local buildingName = DoorGroupSystem:GetBuildingFromDoor(self)
        if buildingName then
            DoorGroupSystem:ForEachDoorInBuilding(buildingName, function(doorEnt)
                doorEnt:Fire(command, arg, delay)
            end)
        end
    end

    function ENT:setBuildingKeysTitle(title)
        local buildingName = DoorGroupSystem:GetBuildingFromDoor(self)
        if buildingName then
            DoorGroupSystem:ForEachDoorInBuilding(buildingName, function(doorEnt)
                doorEnt:setKeysTitle(title)
            end)
        end
    end
end

-------------------------------------------------------------------------------
-- Kauf- / Verkaufsvorgänge
-------------------------------------------------------------------------------
function DoorGroupSystem:BuyBuilding(ply, doorEnt)
    if not doorEnt:isKeysOwned() then
        doorEnt:keysOwn(ply)
    elseif doorEnt:isKeysAllowedToOwn(ply) then
        doorEnt:addKeysDoorOwner(ply)
    end
end

function DoorGroupSystem:SellBuilding(ply, doorEnt)
    if doorEnt:isMasterOwner(ply) then
        doorEnt:keysUnOwn(ply)
        doorEnt:removeAllKeysExtraOwners()
        doorEnt:removeAllKeysAllowedToOwn()
        doorEnt:FireBuilding("unlock", "", 0)
        doorEnt:setBuildingKeysTitle(nil)
    elseif doorEnt:isKeysOwnedBy(ply) then
        doorEnt:removeKeysDoorOwner(ply)
    end
end

hook.Add("playerBuyDoor", "DoorGroupSystem_PlayerBuyDoor", function(ply, ent)
    if ply:isArrested() then
        DarkRP.notify(ply, 1, 5, DarkRP.getPhrase("door_unown_arrested"))
        return false
    end

    if not IsValid(ent) or not ent:isKeysOwnable() or ply:GetPos():DistToSqr(ent:GetPos()) >= 40000 then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("must_be_looking_at", DarkRP.getPhrase("door_or_vehicle")))
        return false
    end

    if ent:getKeysNonOwnable() or ent:getKeysDoorGroup() or not fn.Null(ent:getKeysDoorTeams() or {}) then
        DarkRP.notify(ply, 1, 5, DarkRP.getPhrase("door_unownable"))
        return false
    end

    if ent:isKeysOwned() and not ent:isKeysAllowedToOwn(ply) then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("door_already_owned"))
        return false
    end

    local buildingName = DoorGroupSystem:GetBuildingFromDoor(ent)
    if not buildingName then return end

    local buildingData = DoorGroupSystem.Buildings[buildingName]
    if not buildingData then return end

    if not ent:isKeysAllowedToOwn(ply) then 
        if DoorGroupSystem:CountBuildingsOwnedBy(ply) >= DoorGroupSystem.MaxOwnBuildings then
            DarkRP.notify(ply, 1, 5, "Du hast bereits die maximale Anzahl von " .. DoorGroupSystem.MaxOwnBuildings .. " Gebäuden erreicht.")
            return false
        end
    end

    local buildingPrice = DoorGroupSystem:CalculateBuildingPrice(buildingData)
    if not ply:canAfford(buildingPrice) then
        DarkRP.notify(ply, 1, 4, "Du kannst dir dieses Gebäude nicht leisten.")
        return false
    end

    ply:addMoney(-buildingPrice)
    DarkRP.notify(ply, 0, 4, ("Du hast '%s' für $%d gekauft."):format(buildingName, buildingPrice))
    DoorGroupSystem:BuyBuilding(ply, ent)
    return false
end)

hook.Add("playerSellDoor", "DoorGroupSystem_PlayerSellDoor", function(ply, ent)
    local buildingName = DoorGroupSystem:GetBuildingFromDoor(ent)
    if not buildingName then return end

    local buildingData = DoorGroupSystem.Buildings[buildingName]
    if not buildingData then return end

    local buildingPrice = DoorGroupSystem:CalculateBuildingPrice(buildingData)
    local refund = math.floor(buildingPrice * 0.5)

    ply:addMoney(refund)
    DarkRP.notify(ply, 2, 4, ("Du hast '%s' verkauft und erhälst $%d."):format(buildingName, refund))
    DoorGroupSystem:SellBuilding(ply, ent)
    return false
end)

function DoorGroupSystem:SellAllBuildingsForPlayer(ply)
    local soldBuildings = {}
    for doorID, buildingName in pairs(self.DoorToBuildingMapping) do
        local doorEnt = ents.GetMapCreatedEntity(doorID)
        if IsValid(doorEnt) and (doorEnt:isMasterOwner(ply) or doorEnt:isKeysOwnedBy(ply)) then
            soldBuildings[buildingName] = true
        end
    end

    if not next(soldBuildings) then
        DarkRP.notify(ply, 1, 4, "Du besitzt keine Gebäude zum Verkaufen.")
        return
    end

    for bName in pairs(soldBuildings) do
        local buildingData = self.Buildings[bName]
        self:ForEachDoorInBuilding(bName, function(doorEnt)
            self:SellBuilding(ply, doorEnt)
        end)
        local buildingPrice = self:CalculateBuildingPrice(buildingData)
        local refund = math.floor(buildingPrice * 0.5)

        ply:addMoney(refund)
        DarkRP.notify(ply, 2, 4, ("Du hast '%s' verkauft und erhälst $%d."):format(bName, refund))
    end
end

DarkRP.defineChatCommand("sellalldoors", function(ply)
    DoorGroupSystem:SellAllBuildingsForPlayer(ply)
    return ""
end)

DarkRP.defineChatCommand("unownalldoors", function(ply)
    DoorGroupSystem:SellAllBuildingsForPlayer(ply)
    return ""
end)

-------------------------------------------------------------------------------
-- Property Tax
-------------------------------------------------------------------------------
hook.Add("canPropertyTax", "DoorGroupSystem_CanPropertyTax", function(ply, tax)
    local totalValue = 0
    for buildingName, buildingData in pairs(DoorGroupSystem.Buildings) do
        local owned = false
        for _, doorID in ipairs(buildingData.doors or {}) do
            local doorEnt = ents.GetMapCreatedEntity(doorID)
            if IsValid(doorEnt) and doorEnt:isMasterOwner(ply) then
                owned = true
                break
            end
        end
        if owned then
            totalValue = totalValue + DoorGroupSystem:CalculateBuildingPrice(buildingData)
        end
    end
    if totalValue <= 0 then
        return false, tax
    end
    local taxOverride = math.floor(totalValue * DoorGroupSystem.PropertyTaxValue)
    return true, taxOverride
end)

-------------------------------------------------------------------------------
-- Spieler-Disconnect - mit Fallback
-------------------------------------------------------------------------------
hook.Add("PlayerDisconnected", "DoorGroupSystem_PlayerDisconnected", function(ply)
    for doorID, _ in pairs(DoorGroupSystem.DoorToBuildingMapping) do
        local doorEnt = ents.GetMapCreatedEntity(doorID)
        if IsValid(doorEnt) then
            if doorEnt:isMasterOwner(ply) then
                local coOwners = doorEnt:getKeysCoOwners() or {}
                local fallbackSteamID = next(coOwners)
                if fallbackSteamID then
                    local fallback = Player(fallbackSteamID)
                    if IsValid(fallback) then

                        local currentBuildingCount = DoorGroupSystem:CountBuildingsOwnedBy(fallback) or 0
                        local buildingName = DoorGroupSystem:GetBuildingFromDoor(doorEnt) or "Unbekanntes Gebäude"
                        if currentBuildingCount < DoorGroupSystem.MaxOwnBuildings then
                            doorEnt:keysUnOwn(ply)
                            doorEnt:removeKeysDoorOwner(fallback)
                            doorEnt:keysOwn(fallback)
                            DarkRP.notify(fallback, 0, 7, "Der vorherige Besitzer von '" .. buildingName .. "' hat die Verbindung getrennt.\nDu bist nun der neue Hauptbesitzer dieses Gebäudes.")
                        else
                            DarkRP.notify(fallback, 1, 7, "Der vorherige Besitzer von '" .. buildingName .. "' hat die Verbindung getrennt.\nDu hast bereits die maximale Anzahl von " .. DoorGroupSystem.MaxOwnBuildings .. " Gebäuden erreicht.")
                            DoorGroupSystem:SellBuilding(ply, doorEnt)
                        end
                    else
                        DoorGroupSystem:SellBuilding(ply, doorEnt)
                    end
                else
                    DoorGroupSystem:SellBuilding(ply, doorEnt)
                end
            elseif doorEnt:isKeysOwnedBy(ply) then
                doorEnt:removeKeysDoorOwner(ply)
            end
        end
    end
end)
