------------------------------------------------------------------------
-- RotaAssist - Widgets Aggregator
-- Base module for UI widgets. The actual widget classes are loaded
-- prior to this file via the TOC.
------------------------------------------------------------------------

local _, NS = ...
local RA = NS.RA

-- All UI sub-components live here
RA.UI = RA.UI or {}

-- Register the dummy module so Init.lua can call OnInitialize
local Widgets = {}
RA:RegisterModule("Widgets", Widgets)

function Widgets:OnInitialize()
    -- Nothing to do, widgets are just classes
end

function Widgets:OnEnable()
    -- Nothing to do
end
