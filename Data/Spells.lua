-- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local E, L, V, P, G = unpack(ElvUI);
local TauntAlert = E:GetModule("TauntAlert");

TauntSpell = {
    group = nil,
    class = nil,
    type = nil,
    successEventType = nil
};

--[[
    Constructor
]]--
function TauntSpell:new(o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end


TauntAlert.TAUNTS = {
    ["355"]    = TauntSpell:new({ group = 'WA1', class = 'WARRIOR',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Taunt
    ["1161"]   = TauntSpell:new({ group = 'WA2', class = 'WARRIOR',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Challenging Shout
    ["56222"]  = TauntSpell:new({ group = 'DK1', class = 'DEATHKNIGHT', type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Dark Command
    ["49560"]  = TauntSpell:new({ group = 'DK2', class = 'DEATHKNIGHT', type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Death Grip
    ["6795"]   = TauntSpell:new({ group = 'DR1', class = 'DRUID',       type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Growl
    ["5209"]   = TauntSpell:new({ group = 'DR2', class = 'DRUID',       type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Challenging Roar
    ["62124"]  = TauntSpell:new({ group = 'PA1', class = 'PALADIN',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Hand of Reckoning
    ["31789"]  = TauntSpell:new({ group = 'PA2', class = 'PALADIN',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Righteous Defense
    ["31790"]  = TauntSpell:new({ group = 'PA2', class = 'PALADIN',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Righteous Defense (debuff)
    ["20736"]  = TauntSpell:new({ group = 'HU1', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Distracting Shot (Rank 1)
    ["14274"]  = TauntSpell:new({ group = 'HU1', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Distracting Shot (Rank 2)
    ["15629"]  = TauntSpell:new({ group = 'HU1', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Distracting Shot (Rank 3)
    ["15630"]  = TauntSpell:new({ group = 'HU1', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Distracting Shot (Rank 4)
    ["15631"]  = TauntSpell:new({ group = 'HU1', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Distracting Shot (Rank 5)
    ["15632"]  = TauntSpell:new({ group = 'HU1', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Distracting Shot (Rank 6)
    ["27020"]  = TauntSpell:new({ group = 'HU1', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Distracting Shot (Rank 7)
    ["34477"]  = TauntSpell:new({ group = 'HU2', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA }),    -- Misdirection
    ["53477"]  = TauntSpell:new({ group = 'HU3', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Taunt
    ["2649"]   = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 1)
    ["14916"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 2)
    ["14917"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 3)
    ["14918"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 4)
    ["14919"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 5)
    ["14920"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 6)
    ["14921"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 7)
    ["27047"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 8)
    ["61676"]  = TauntSpell:new({ group = 'HU4', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Growl (Rank 9)
    ["19577"]  = TauntSpell:new({ group = 'HU5', class = 'HUNTER',      type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Intimidation
    ["57934"]  = TauntSpell:new({ group = 'RO1', class = 'ROGUE',       type = TauntAlert.TAUNT_TYPES.TRANS,  successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Tricks of the Trade
    ["3716"]   = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 1)
    ["7809"]   = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 2)
    ["7810"]   = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 3)
    ["7811"]   = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 4)
    ["11774"]  = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 5)
    ["11775"]  = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 6)
    ["27270"]  = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 7)
    ["47984"]  = TauntSpell:new({ group = 'WK1', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.Single, successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Torment (Rank 8)
    ["17735"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Suffering (Rank 1)
    ["17750"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Suffering (Rank 2)
    ["17751"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Suffering (Rank 3)
    ["17752"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Suffering (Rank 4)
    ["27271"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Suffering (Rank 5)
    ["33701"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Suffering (Rank 6)
    ["47989"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST }),    -- Suffering (Rank 7)
    ["47990"]  = TauntSpell:new({ group = 'WK2', class = 'WARLOCK',     type = TauntAlert.TAUNT_TYPES.AOE,    successEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST })     -- Suffering (Rank 8)
};