-- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local E, L, V, P, G = unpack(ElvUI);
local TauntAlert = E:GetModule("TauntAlert");

TauntInfo = {
    caster     = nil,
    petOwner   = nil,
    casterType = nil,
    target     = nil,
    ability    = nil,
    type       = nil,
    class      = nil,
    success    = nil,
    reason     = nil
};

--[[
    Constructor
]]--
function TauntInfo:new(o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end

