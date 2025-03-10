
DoorGroupSystem = DoorGroupSystem or {}
DoorGroupSystem.DoorFactor        = 100   -- Standard-Türfaktor, falls nicht gesetzt
DoorGroupSystem.PropertyTaxValue  = 0.1   -- Prozentsatz für Property-Tax
DoorGroupSystem.MaxOwnBuildings   = 3     -- Maximale Gebäude, die ein Spieler besitzen darf

-------------------------------------------------------------------------------
-- Preis-Berechnung
-------------------------------------------------------------------------------
function DoorGroupSystem:CalculateBuildingPrice(buildingData)
    if not buildingData then return 0 end
    local basePrice = buildingData.price or 0
    local doorFactor = buildingData.doorFactor or self.DoorFactor
    local doorCount = #(buildingData.doors or {})
    return basePrice + (doorCount * doorFactor)
end
