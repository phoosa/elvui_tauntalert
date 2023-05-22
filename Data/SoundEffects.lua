-- Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local E, L, V, P, G = unpack(ElvUI);
local TauntAlert = E:GetModule("TauntAlert");

SoundEffect = {
    id = nil,
    name = nil
};

--[[
    Constructor
]]--
function SoundEffect:new(o)
    o = o or {};
    setmetatable(o, self);
    self.__index = self;
    return o;
end


TauntAlert.SOUND_EFFECTS = {
    ArcaneExplosion = SoundEffect:new({
        name = "Arcane Explosion",
        id = 6539
    }),
    ArcaneInt = SoundEffect:new({
        name = "Arcane Intellect",
        id = 1422
    }),
    Bell = SoundEffect:new({
        name = "Bell",
        id = 6595
    }),
    Bell2 = SoundEffect:new({
        name = "Bell 2",
        id = 6594
    }),
    Bell3 = SoundEffect:new({
        name = "Bell 3",
        id = 6674
    }),
    BellowIn = SoundEffect:new({
        name = "Bellow In",
        id = 8672
    }),
    BellowOut = SoundEffect:new({
        name = "Bellow Out",
        id = 8673
    }),
    BreakBox = SoundEffect:new({
        name = "Break Box",
        id = 4784
    }),
    CageOpen = SoundEffect:new({
        name = "Cage Open",
        id = 4674
    }),
    Cannon = SoundEffect:new({
        name = "Cannon",
        id = 1400
    }),
    Elevator1 = SoundEffect:new({
        name = "Elevator Start",
        id = 7181
    }),
    GoblinDeath = SoundEffect:new({
        name = "Goblin Death",
        id = 1411
    }),
    GoblinLaugh = SoundEffect:new({
        name = "Goblin Laugh",
        id = 1416
    }),
    LevelUp = SoundEffect:new({
        name = "Level Up",
        id = 1440
    }),
    QuestFail = SoundEffect:new({
        name = "Quest Fail",
        id = 847
    }),
    Warped = SoundEffect:new({
        name = "Warped",
        id = 8156
    }),
    __no_sound__ = SoundEffect:new({
        name = "< No Sound >",
        id = nil
    })
};
