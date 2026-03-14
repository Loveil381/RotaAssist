-- tests/helpers.lua
-- Test helpers for loading RotaAssist modules in busted.
-- 为 busted 测试提供模块加载辅助函数。
local M = {}

--- Compute the repository root from this file's path.
-- 从本文件路径推导仓库根目录。
local function repoRoot()
    -- __FILE__ is not available in all Lua versions; use a relative fallback.
    -- busted is expected to be run from the repo root, so "." is sufficient.
    return "."
end
M.repoRoot = repoRoot

--- Load a single addon file as WoW would: pass (addonName, NS) as varargs.
-- 模拟 WoW 加载 Lua 文件的方式，将 addonName 和 NS 作为可变参数传入。
---@param path string  Relative path from repo root (e.g. "addon/Core/Init.lua")
---@param addonName string  Addon name string (e.g. "RotaAssist")
---@param ns table   Shared namespace table (NS)
---@return boolean ok, string|nil err
function M.loadAddonFile(path, addonName, ns)
    local fullPath = repoRoot() .. "/" .. path
    local fn, err = loadfile(fullPath)
    if not fn then
        return false, "loadfile failed: " .. tostring(err)
    end
    -- Call with the WoW-style varargs so `local ADDON_NAME, NS = ...` works
    local ok, loadErr = pcall(fn, addonName, ns)
    if not ok then
        return false, "execution failed: " .. tostring(loadErr)
    end
    return true, nil
end

--- Build a fresh, minimal shared namespace table.
-- 创建一个干净的 NS 命名空间表。
---@return table ns
function M.newNS()
    return {}
end

--- Load mock_wow_api.lua once before any addon files.
-- 在加载插件文件前确保 WoW API mock 已就位。
local _mockLoaded = false
function M.ensureMockLoaded()
    if _mockLoaded then return end
    local ok, err = M.loadAddonFile("tests/mock_wow_api.lua", "", {})
    if not ok then error("Failed to load mock_wow_api: " .. tostring(err)) end
    _mockLoaded = true
end

--- Full addon loader: loads mock then Init.lua, returns (RA, NS).
-- 加载 mock 后再加载 Init.lua，返回 (RA, NS)。
---@return table RA, table NS
function M.loadAddon()
    M.ensureMockLoaded()
    local ns = M.newNS()
    local ok, err = M.loadAddonFile("addon/Core/Init.lua", "RotaAssist", ns)
    if not ok then error("loadAddon failed: " .. tostring(err)) end
    return ns.RA, ns
end

--- Load Registry.lua into an existing NS (requires RA to be set on NS first).
-- 将 Registry.lua 载入已有的 NS 命名空间（NS.RA 必须已设置）。
---@param ns table  Namespace table with ns.RA set
function M.loadRegistry(ns)
    M.ensureMockLoaded()
    local ok, err = M.loadAddonFile("addon/Data/Registry.lua", "RotaAssist", ns)
    if not ok then error("loadRegistry failed: " .. tostring(err)) end
    -- Sync aliases that Init.lua sets at file-load time before Registry existed
    local RA = ns.RA
    if RA and RA.Registry then
        RA.KNOWN_OVERRIDE_PAIRS = RA.Registry.OVERRIDE_PAIRS or {}
    end
end

return M
