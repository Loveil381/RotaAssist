-- tests/test_cdm_hook.lua
-- Unit tests for CDMHook (EssentialCooldownViewer co-existence hook).
local helpers = require("tests.helpers")

describe("CDMHook", function()
    local RA, ns, CDM

    -- Build a synthetic EssentialCooldownViewer with a configurable
    -- visible-spell list and an Update method that the hook will wrap.
    local function makeECV(spellIDs)
        local ecv = {
            _visibleIDs = spellIDs or {},
        }
        function ecv:GetCooldownIDs()
            local list = {}
            for _, sid in ipairs(self._visibleIDs) do
                list[#list + 1] = sid
            end
            return list
        end
        function ecv:Update()
            -- Real Blizzard frame does layout work here; the hook fires
            -- on the trailing edge via hooksecurefunc.
        end
        return ecv
    end

    setup(function()
        RA, ns = helpers.loadAddon()
        helpers.loadRegistry(ns)
        helpers.loadAddonFile("addon/Core/EventHandler.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/CooldownOverlay.lua", "RotaAssist", ns)
        helpers.loadAddonFile("addon/Engine/CDMHook.lua", "RotaAssist", ns)
        CDM = RA:GetModule("CDMHook")
    end)

    before_each(function()
        -- Ensure each test sees a clean ECV / hook state.
        _G.EssentialCooldownViewer = nil
        CDM:OnInitialize()
    end)

    after_each(function()
        _G.EssentialCooldownViewer = nil
    end)

    describe("module registration", function()
        it("registers under RA.modules", function()
            assert.is_not_nil(CDM)
            assert.equals("CDMHook", CDM._name)
        end)

        it("exposes the standard Ace3 lifecycle hooks", function()
            assert.is_function(CDM.OnInitialize)
            assert.is_function(CDM.OnEnable)
            assert.is_function(CDM.OnDisable)
        end)
    end)

    describe("graceful degradation when ECV is absent", function()
        it("OnEnable does not error when EssentialCooldownViewer is nil", function()
            _G.EssentialCooldownViewer = nil
            assert.has_no.errors(function() CDM:OnEnable() end)
        end)

        it("reports inactive state when no ECV present", function()
            _G.EssentialCooldownViewer = nil
            CDM:OnEnable()
            assert.is_false(CDM:IsActive())
        end)

        it("emits no event when ECV is absent", function()
            local eh = RA:GetModule("EventHandler")
            local fired = 0
            eh:Subscribe("ROTAASSIST_CDM_UPDATE", "TestProbe", function()
                fired = fired + 1
            end)

            _G.EssentialCooldownViewer = nil
            CDM:OnEnable()
            CDM:ForceUpdate()
            assert.equals(0, fired)

            eh:Unsubscribe("ROTAASSIST_CDM_UPDATE", "TestProbe")
        end)

        it("OnDisable is safe when never enabled with ECV", function()
            assert.has_no.errors(function() CDM:OnDisable() end)
        end)
    end)

    describe("hook installation when ECV is present", function()
        it("installs hook and reports active", function()
            _G.EssentialCooldownViewer = makeECV({ 188499, 198013 })
            CDM:OnEnable()
            assert.is_true(CDM:IsActive())
            assert.is_true(CDM:IsECVPresent())
        end)

        it("fires ROTAASSIST_CDM_UPDATE on enable with initial visible set", function()
            local eh = RA:GetModule("EventHandler")
            local lastPayload = nil
            eh:Subscribe("ROTAASSIST_CDM_UPDATE", "TestProbe", function(_, payload)
                lastPayload = payload
            end)

            _G.EssentialCooldownViewer = makeECV({ 188499, 198013 })
            CDM:OnEnable()

            assert.is_table(lastPayload)
            assert.is_table(lastPayload.visibleSpellIDs)
            assert.is_true(lastPayload.visibleSpellIDs[188499])
            assert.is_true(lastPayload.visibleSpellIDs[198013])

            eh:Unsubscribe("ROTAASSIST_CDM_UPDATE", "TestProbe")
        end)

        it("re-fires when the ECV visible set changes", function()
            local eh = RA:GetModule("EventHandler")
            local fireCount = 0
            local lastPayload = nil
            eh:Subscribe("ROTAASSIST_CDM_UPDATE", "TestProbe", function(_, payload)
                fireCount = fireCount + 1
                lastPayload = payload
            end)

            local ecv = makeECV({ 188499 })
            _G.EssentialCooldownViewer = ecv
            CDM:OnEnable()
            local firstFireCount = fireCount

            -- Mutate ECV and force another scan.
            ecv._visibleIDs = { 188499, 162794 }
            CDM:ForceUpdate()

            assert.is_true(fireCount > firstFireCount)
            assert.is_true(lastPayload.visibleSpellIDs[188499])
            assert.is_true(lastPayload.visibleSpellIDs[162794])

            eh:Unsubscribe("ROTAASSIST_CDM_UPDATE", "TestProbe")
        end)

        it("dedupes identical consecutive updates", function()
            local eh = RA:GetModule("EventHandler")
            local fireCount = 0
            eh:Subscribe("ROTAASSIST_CDM_UPDATE", "TestProbe", function()
                fireCount = fireCount + 1
            end)

            _G.EssentialCooldownViewer = makeECV({ 188499 })
            CDM:OnEnable()
            local afterEnable = fireCount

            -- Force two more scans with no change to the visible set.
            CDM:ForceUpdate()
            CDM:ForceUpdate()

            assert.equals(afterEnable, fireCount)

            eh:Unsubscribe("ROTAASSIST_CDM_UPDATE", "TestProbe")
        end)
    end)

    describe("CooldownOverlay subscriber integration", function()
        it("CooldownOverlay receives and exposes the visible set", function()
            local CO = RA:GetModule("CooldownOverlay")
            CO:OnInitialize()
            -- Manually invoke the OnEnable wiring to attach the
            -- ROTAASSIST_CDM_UPDATE subscriber.
            CO:OnEnable()

            _G.EssentialCooldownViewer = makeECV({ 188499, 162794 })
            CDM:OnEnable()

            local visible = CO:GetCDMVisibleSet()
            assert.is_table(visible)
            assert.is_true(visible[188499])
            assert.is_true(visible[162794])
        end)
    end)

    describe("public accessors", function()
        it("GetLastVisibleSet returns a copy not the internal table", function()
            _G.EssentialCooldownViewer = makeECV({ 188499 })
            CDM:OnEnable()

            local snap1 = CDM:GetLastVisibleSet()
            snap1[999999] = true
            local snap2 = CDM:GetLastVisibleSet()
            assert.is_nil(snap2[999999])
        end)
    end)
end)
