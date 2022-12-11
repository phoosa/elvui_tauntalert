--Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local E, L, V, P, G = unpack(ElvUI);
--Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local TauntAlert = E:NewModule("TauntAlert", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0");
--We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local EP = LibStub("LibElvUIPlugin-1.0");
--See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2
local addonName, addonTable = ...;


-- ========================================== --
--                                            --
-- LOCAL CONSTANTS                            --
--                                            --
-- ========================================== --

local SPELL_EVENT_TYPE_CAST = "CAST";
local SPELL_EVENT_TYPE_AURA = "AURA";

local SPELL_CAST_STATUS_SUCCESS = "SUCCESS";
local SPELL_CAST_STATUS_FAILED  = "FAILED";
local SPELL_CAST_STATUS_MISSED  = "MISSED";
local SPELL_AURA_STATUS_APPLIED = "APPLIED";
local SPELL_AURA_STATUS_REMOVED = "REMOVED";

local SPELL_CASTER_TYPE_ME 		  = "ME";
local SPELL_CASTER_TYPE_PARTY 	  = "PARTY";
local SPELL_CASTER_TYPE_PARTY_PET = "PARTY_PET";
local SPELL_CASTER_TYPE_OTHER 	  = "OTHER";
local SPELL_CASTER_TYPE_OTHER_PET = "OTHER_PET";

local BIT_PARTY_RAID_PLAYER     = bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_PARTY,
    COMBATLOG_OBJECT_AFFILIATION_RAID,
    COMBATLOG_OBJECT_REACTION_MASK,
    COMBATLOG_OBJECT_CONTROL_MASK,
    COMBATLOG_OBJECT_TYPE_PLAYER
);
local BIT_PARTY_RAID_PET        = bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_PARTY,
    COMBATLOG_OBJECT_AFFILIATION_RAID,
    COMBATLOG_OBJECT_REACTION_MASK,
    COMBATLOG_OBJECT_CONTROL_MASK,
    COMBATLOG_OBJECT_TYPE_PET,
    COMBATLOG_OBJECT_TYPE_GUARDIAN
);
local BIT_OUTSIDER_PLAYER       = bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
    COMBATLOG_OBJECT_REACTION_MASK,
    COMBATLOG_OBJECT_CONTROL_MASK,
    COMBATLOG_OBJECT_TYPE_PLAYER
);
local BIT_OTHER_PET          = bit.bor(
    COMBATLOG_OBJECT_AFFILIATION_OUTSIDER,
    COMBATLOG_OBJECT_REACTION_MASK,
    COMBATLOG_OBJECT_CONTROL_MASK,
    COMBATLOG_OBJECT_TYPE_PET,
    COMBATLOG_OBJECT_TYPE_GUARDIAN
);


-- ========================================== --
--                                            --
-- MODULE CONSTANTS                           --
--                                            --
-- ========================================== --


TauntAlert.PLAYER_NAME, TauntAlert.PLAYER_REALM = UnitName("player");
TauntAlert.TITLE = "Taunt Alert";
TauntAlert.VERSION = GetAddOnMetadata("ElvUI_TauntAlert", "Version");
TauntAlert.ERROR_COLOR = "|cfffa2f47";
TauntAlert.CHAT_COLOR = "|cff2f9bfa";
TauntAlert.DISABLED_CHAT_WINDOW = "__none__";
TauntAlert.DATA = {
    CLASSES = {
        ["Death Knight"] = "Death Knight",
        Druid            = "Druid",
        Hunter           = "Hunter",
        HunterPet        = "Hunter Pet",
        Mage             = "Mage",
        Paladin          = "Paladin",
        Priest           = "Priest",
        Rogue            = "Rogue",
        Shaman           = "Shaman",
        Warlock          = "Warlock",
        Warrior          = "Warrior"
    },
    TAUNT_TYPES = {
        Single  = "Single",
        AOE     = "AOE"
    }
};
TauntAlert.CLASS_COLORS = {
    [TauntAlert.DATA.CLASSES["Death Knight"]]  = "|cffC41E3A",
    [TauntAlert.DATA.CLASSES.Druid]            = "|cffFF7D0A",
    [TauntAlert.DATA.CLASSES.Hunter]           = "|cffABD473",
    [TauntAlert.DATA.CLASSES.HunterPet]        = "|cffABD473",
    [TauntAlert.DATA.CLASSES.Mage]             = "|cff69CCF0",
    [TauntAlert.DATA.CLASSES.Paladin]          = "|cffF58CBA",
    [TauntAlert.DATA.CLASSES.Priest]           = "|cffFFFFFF",
    [TauntAlert.DATA.CLASSES.Rogue]            = "|cffFFF569",
    [TauntAlert.DATA.CLASSES.Shaman]           = "|cff0070DE",
    [TauntAlert.DATA.CLASSES.Warlock]          = "|cff9482C9",
    [TauntAlert.DATA.CLASSES.Warrior]          = "|cffC79C6E"
};
TauntAlert.SOUND_EFFECTS = {
    ArcaneExplosion = {
        name = "Arcane Explosion",
        id = 6539
    },
    ArcaneInt = {
        name = "Arcane Intellect",
        id = 1422
    },
    Bell = {
        name = "Bell",
        id = 6595
    },
    Bell2 = {
        name = "Bell 2",
        id = 6594
    },
    Bell3 = {
        name = "Bell 3",
        id = 6674
    },
    BellowIn = {
        name = "Bellow In",
        id = 8672
    },
    BellowOut = {
        name = "Bellow Out",
        id = 8673
    },
    BreakBox = {
        name = "Break Box",
        id = 4784
    },
    CageOpen = {
        name = "Cage Open",
        id = 4674
    },
    Cannon = {
        name = "Cannon",
        id = 1400
    },
    Elevator1 = {
        name = "Elevator Start",
        id = 7181
    },
    GoblinDeath = {
        name = "Goblin Death",
        id = 1411
    },
    GoblinLaugh = {
        name = "Goblin Laugh",
        id = 1416
    },
    LevelUp = {
        name = "Level Up",
        id = 1440
    },
    QuestFail = {
        name = "Quest Fail",
        id = 847
    },
    Warped = {
        name = "Warped",
        id = 8156
    },
    __no_sound__ = {
        name = "< No Sound >",
        id = nil
    }
};

TauntAlert.TAUNTS = {
    ["355"]    = { class = TauntAlert.DATA.CLASSES.Warrior,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'AURA' },            -- Taunt
    ["1161"]   = { class = TauntAlert.DATA.CLASSES.Warrior,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'AURA' },            -- Challenging Shout
    ["56222"]  = { class = TauntAlert.DATA.CLASSES["Death Knight"], type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'AURA' },            -- Dark Command
    ["49560"]  = { class = TauntAlert.DATA.CLASSES["Death Knight"], type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'AURA' },            -- Death Grip
    ["6795"]   = { class = TauntAlert.DATA.CLASSES.Druid,           type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'AURA' },            -- Growl
    ["5209"]   = { class = TauntAlert.DATA.CLASSES.Druid,           type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'AURA' },            -- Challenging Roar
    ["62124"]  = { class = TauntAlert.DATA.CLASSES.Paladin,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'AURA' },            -- Hand of Reckoning
    ["31789"]  = { class = TauntAlert.DATA.CLASSES.Paladin,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Righteous Defense
    ["31790"]  = { class = TauntAlert.DATA.CLASSES.Paladin,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'AURA' },            -- Righteous Defense (debuff)
    ["20736"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Distracting Shot (Rank 1)
    ["14274"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Distracting Shot (Rank 2)
    ["15629"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Distracting Shot (Rank 3)
    ["15630"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Distracting Shot (Rank 4)
    ["15631"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Distracting Shot (Rank 5)
    ["15632"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Distracting Shot (Rank 6)
    ["27020"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Distracting Shot (Rank 7)
    ["34477"]  = { class = TauntAlert.DATA.CLASSES.Hunter,          type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'AURA' },            -- Misdirection
    ["53477"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Taunt
    ["2649"]   = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 1)
    ["14916"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 2)
    ["14917"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 3)
    ["14918"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 4)
    ["14919"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 5)
    ["14920"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 6)
    ["14921"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 7)
    ["27047"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 8)
    ["61676"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Growl (Rank 9)
    ["19577"]  = { class = TauntAlert.DATA.CLASSES.HunterPet,       type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Intimidation
    ["3716"]   = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 1)
    ["7809"]   = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 2)
    ["7810"]   = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 3)
    ["7811"]   = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 4)
    ["11774"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 5)
    ["11775"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 6)
    ["27270"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 7)
    ["47984"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.Single, successEventType = 'CAST' },            -- Torment (Rank 8)
    ["17735"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Suffering (Rank 1)
    ["17750"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Suffering (Rank 2)
    ["17751"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Suffering (Rank 3)
    ["17752"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Suffering (Rank 4)
    ["27271"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Suffering (Rank 5)
    ["33701"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Suffering (Rank 6)
    ["47989"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' },            -- Suffering (Rank 7)
    ["47990"]  = { class = TauntAlert.DATA.CLASSES.Warlock,         type = TauntAlert.DATA.TAUNT_TYPES.AOE,    successEventType = 'CAST' }             -- Suffering (Rank 8)
};


-- ========================================== --
--                                            --
-- EVENT REGISTRATION                         --
--                                            --
-- ========================================== --

--[[
    Create Pet Owner Frame
    There's no API command to get pet owner info, this frame is a workaround for that.
]]--
function TauntAlert:CreatePetOwnerFrame()
    CreateFrame("GameTooltip", "ELVUI_TAUNTALERT_FRAME_PET_INFO", nil, "GameTooltipTemplate");
    ELVUI_TAUNTALERT_FRAME_PET_INFO:SetOwner(WorldFrame, "ANCHOR_NONE");
    ELVUI_TAUNTALERT_FRAME_PET_INFO:AddFontStrings(
        ELVUI_TAUNTALERT_FRAME_PET_INFO:CreateFontString( "$parentTextLeft1", nil, "GameTooltipText" ),
        ELVUI_TAUNTALERT_FRAME_PET_INFO:CreateFontString( "$parentTextRight1", nil, "GameTooltipText" )
    );
end

--[[
    Initial Event Registration
    TauntAlert can only function if we're listening for event changes.
]]--
function TauntAlert:InitialEventRegistration()
    -- These events are used to determine if we should be monitoring the Combat Log.
    self:RegisterEvent("PLAYER_LOGIN", "OnPlayerLoginEvent");
    self:RegisterEvent("PLAYER_ENTERING_WORLD", "OnPlayerEnterWorldEvent");
    self:RegisterEvent("ZONE_CHANGED_NEW_AREA", "OnZoneChangedEvent");

    -- These events are needed to keep our configuration options current.
    -- self:RegisterEvent("UPDATE_CHAT_WINDOWS", "OnUpdateChatWindowsEvent");

    -- Start Monitoring the Combat Log?
    self:RefreshCombatLogMonitoring();
end


--[[
    Refresh Combat Log Monitoring
    Only Monitor the Combat Log Events if the player state & configuration requires it.
]]--
function TauntAlert:RefreshCombatLogMonitoring()
    -- Should we be monitoring the Combat Log?
    if (TauntAlert:ShouldMonitorCombatLog()) then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent");
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
    end
end


--[[
    Should Monitor Combat Log
    Given the current configuration and player state, should TauntAlert
    Monitor the Combat Log for Taunt Events?
    @return bool
]]--
function TauntAlert:ShouldMonitorCombatLog()
    -- Instance Checks (Battleground)
    local inInstance, instanceType = IsInInstance();
    if (inInstance == true) then
        -- Battleground Check
        if (instanceType == "pvp") and (TauntAlert:GetConfigValue('BGEnabled') == false) then
            return false;
        end
    end
    -- Solo/Party/Raid Checks
    if (UnitInRaid("player")) then
        if (TauntAlert:GetConfigValue('RaidEnabled') == false) then
            return false;
        end
    elseif (UnitInParty("player")) then
        if (TauntAlert:GetConfigValue('PartyEnabled') == false) then
            return false;
        end
    elseif (TauntAlert:GetConfigValue('SoloEnabled') == false) then
        return false;
    end
    
    return true;
end


-- ========================================== --
--                                            --
-- EVENT HANDLING                             --
--                                            --
-- ========================================== --


--[[
    On Combat Log Event
]]--
function TauntAlert:OnCombatLogEvent(self, event, ...)
    local logData = TauntAlert:GetCombatLogEventInfo(CombatLogGetCurrentEventInfo());

    -- Was a Taunt Detected on a target?
    if (logData.taunt ~= nil and (logData.destinationName ~= nil or logData.taunt.type == TauntAlert.DATA.TAUNT_TYPES.AOE)) then
        local tauntInfo = {
            caster      = logData.sourceName,
            petOwner    = nil,
            casterType  = nil,
            target      = logData.destinationName,
            ability     = logData.spellName,
            type        = logData.taunt.type,
            class       = logData.taunt.class,
            success     = nil,
            reason      = nil,
        };
        -- TauntAlert:log(format("[%s:%s] %s:%s (%s -> %s)", logData.spellEventType, logData.spellEventStatus, logData.spellId, logData.spellName, tostring(tauntInfo.caster), tostring(tauntInfo.target)));

        -- Determine which category of caster this taunt is attributed to
        if CombatLog_Object_IsA(logData.sourceFlags, COMBATLOG_FILTER_ME) then
            tauntInfo.casterType = SPELL_CASTER_TYPE_ME;
        elseif CombatLog_Object_IsA(logData.sourceFlags, COMBATLOG_FILTER_MY_PET) then
            tauntInfo.casterType = SPELL_CASTER_TYPE_PARTY_PET;
            tauntInfo.petOwner = TauntAlert:getPetOwner(tauntInfo.caster);
        elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_PARTY_RAID_PET) then
            tauntInfo.casterType = SPELL_CASTER_TYPE_PARTY_PET;
            tauntInfo.petOwner = TauntAlert:getPetOwner(tauntInfo.caster);
        elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_PARTY_RAID_PLAYER) then
            tauntInfo.casterType = SPELL_CASTER_TYPE_PARTY;
        elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_OTHER_PET) then
            tauntInfo.casterType = SPELL_CASTER_TYPE_OTHER_PET;
            tauntInfo.petOwner = TauntAlert:getPetOwner(tauntInfo.caster);
        elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_OUTSIDER_PLAYER) then
            tauntInfo.casterType = SPELL_CASTER_TYPE_OTHER;
        else
            tauntInfo.casterType = SPELL_CASTER_TYPE_OTHER;
        end

        if (logData.spellEventType == SPELL_EVENT_TYPE_CAST) then
            if (logData.spellEventStatus ~= SPELL_CAST_STATUS_SUCCESS) then
                tauntInfo.success = false;
                tauntInfo.reason = logData.spellEventStatus;
                if (logData.spellFailedReason) then
                    tauntInfo.reason = logData.spellEventStatus;
                end
                TauntAlert:ProcessTaunt(tauntInfo);
            elseif (logData.taunt.successEventType == 'CAST') then
                -- NOTICE: We only announce "successful" casts if the event
                tauntInfo.success = true;
                TauntAlert:ProcessTaunt(tauntInfo);
            end
        elseif (logData.spellEventType == SPELL_EVENT_TYPE_AURA) then
            if logData.taunt.successEventType == 'AURA' and (logData.spellEventStatus == SPELL_AURA_STATUS_APPLIED or logData.spellEventStatus == SPELL_CAST_STATUS_SUCCESS) then
                tauntInfo.success = true;
                TauntAlert:ProcessTaunt(tauntInfo);
            end
        end
    end
end


--[[
    Process Taunt
    A Taunt Event has been detected in the Combat Log, perform the necessary notifications for this event.
]]--
function TauntAlert:ProcessTaunt(tauntInfo)
    -- Play Sound Effect for Taunt Event.
    local soundId = TauntAlert.GetTauntEventSoundID[tauntInfo.casterType](tauntInfo);
    if (soundId ~= nil) then
        PlaySound(soundId);
    end

    -- Display the Taunt Event in Chat.
    if (TauntAlert.CanDisplayTauntEvent[tauntInfo.casterType](tauntInfo)) then
        local window = TauntAlert:GetConfigValue('ChatWindow');
        if (window ~= nil and window ~= TauntAlert.DISABLED_CHAT_WINDOW) then
            TauntAlert:PrintToChatWindow(TauntAlert:FormatChatMessage(tauntInfo), window);
        end
    end
end


--[[
    On Player Login Event
    Update Event Listener Registration
]]--
function TauntAlert:OnPlayerLoginEvent(self, event, ...)
    TauntAlert:RefreshCombatLogMonitoring();
end


--[[
    On Player Enter World Event
    Update Event Listener Registration
]]--
function TauntAlert:OnPlayerEnterWorldEvent(self, event, ...)
    TauntAlert:RefreshCombatLogMonitoring();
end


--[[
    On Zone Changed Event
    Update Event Listener Registration
]]--
function TauntAlert:OnZoneChangedEvent(self, event, ...)
    TauntAlert:RefreshCombatLogMonitoring();
end


-- ========================================== --
--                                            --
-- EVENT PROCESSING HELPERS                   --
--                                            --
-- ========================================== --


--[[
    Get Combat Log Event Info
    @see  https://wow.gamepedia.com/COMBAT_LOG_EVENT
    @see  https://wow.gamepedia.com/API_CombatLogGetCurrentEventInfo
]]--
function TauntAlert:GetCombatLogEventInfo(...)
    local tEventInfo = {...};

    local eventInfo = {
        timestamp               = tEventInfo[1],
        event                   = tEventInfo[2],
        hideCaster              = tEventInfo[3],
        sourceGuid              = tEventInfo[4],
        sourceName              = tEventInfo[5],
        sourceFlags             = tEventInfo[6],
        sourceRaidFlags         = tEventInfo[7],
        destinationGuid         = tEventInfo[8],
        destinationName         = tEventInfo[9],
        destinationFlags        = tEventInfo[10],
        destinationRaidFlags    = tEventInfo[11],
        isSpell                 = (tEventInfo[2]:sub(1,5) == "SPELL")
    };

    -- Add Spell Details if this is a Spell Event
    if (eventInfo.isSpell) then
        eventInfo.spellId       = tEventInfo[12];
        eventInfo.spellName     = tEventInfo[13];
        eventInfo.spellSchool   = tEventInfo[14];
        eventInfo.taunt         = TauntAlert.TAUNTS[tostring(eventInfo.spellId)];

        -- Get Cast/Aura and Status.
        if (eventInfo.event:sub(1, 10) == "SPELL_AURA") then
            eventInfo.spellEventType = SPELL_EVENT_TYPE_AURA;
            if (eventInfo.event == "SPELL_AURA_APPLIED") then
                eventInfo.spellEventStatus = SPELL_AURA_STATUS_APPLIED;
            elseif (eventInfo.event == "SPELL_AURA_REMOVED" or eventInfo.event == "SPELL_AURA_BROKEN" or eventInfo.event == "SPELL_AURA_BROKEN_SPELL") then
                eventInfo.spellEventStatus = SPELL_AURA_STATUS_REMOVED;
            end
        else
            if (eventInfo.event:sub(1, 10) == "SPELL_CAST") then
                eventInfo.spellEventType = SPELL_EVENT_TYPE_CAST;
                if (eventInfo.event == "SPELL_CAST_SUCCESS") then
                    eventInfo.spellEventStatus = SPELL_CAST_STATUS_SUCCESS;
                elseif (eventInfo.event == "SPELL_CAST_FAILED") then
                    eventInfo.spellEventStatus = SPELL_CAST_STATUS_FAILED;
                    eventInfo.spellFailedReason = tEventInfo[15];
                -- I should only track SPELL_CAST_MISSED and SPELL_AURA_APPLIED
                end
            elseif (eventInfo.event == "SPELL_MISSED") then
                eventInfo.spellEventType = SPELL_EVENT_TYPE_CAST;
                eventInfo.spellEventStatus = SPELL_CAST_STATUS_MISSED;
                eventInfo.spellFailedReason = tEventInfo[15];
            end
        end
    end

    return eventInfo;
end


--[[
    Check if this Taunt Event should be Displayed in Chat.
    @return bool
]]--
TauntAlert.CanDisplayTauntEvent = {
    [SPELL_CASTER_TYPE_ME] = function (tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayMineSuccess");
        else
            return TauntAlert:GetConfigValue("DisplayMineFailed");
        end
    end,
    [SPELL_CASTER_TYPE_PARTY] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayPartySuccess");
        else
            return TauntAlert:GetConfigValue("DisplayPartyFailed");
        end
    end,
    [SPELL_CASTER_TYPE_PARTY_PET] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayPartyPetSuccess");
        else
            return TauntAlert:GetConfigValue("DisplayPartyPetFailed");
        end
    end,
    [SPELL_CASTER_TYPE_OTHER] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayOtherPlayerSuccess");
        else
            return TauntAlert:GetConfigValue("DisplayOtherPlayerFailed");
        end
    end,
    [SPELL_CASTER_TYPE_OTHER_PET] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayOtherPetSuccess");
        else
            return TauntAlert:GetConfigValue("DisplayOtherPetFailed");
        end
    end
};


--[[
    Get the Taunt Event Sound ID to play
    @return number|nil
]]--
TauntAlert.GetTauntEventSoundID = {
    [SPELL_CASTER_TYPE_ME] = function (tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearMineSuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearMineFailed")].id;
        end
    end,
    [SPELL_CASTER_TYPE_PARTY] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartySuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartyFailed")].id;
        end
    end,
    [SPELL_CASTER_TYPE_PARTY_PET] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartyPetSuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartyPetFailed")].id;
        end
    end,
    [SPELL_CASTER_TYPE_OTHER] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearOtherPlayerSuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearOtherPlayerFailed")].id;
        end
    end,
    [SPELL_CASTER_TYPE_OTHER_PET] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearOtherPetSuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearOtherPetFailed")].id;
        end
    end
};


-- ========================================== --
--                                            --
-- HELPERS                                    --
--                                            --
-- ========================================== --


--[[
    Debug logging
]]--
function TauntAlert:log(message)
    local window = TauntAlert:GetConfigValue('ChatWindow');
    TauntAlert:PrintToChatWindow(tostring(message), window);
end


--[[
    Get name of Pet Owner using Tooltip  Frame
]]--
function TauntAlert:getPetOwner(petName)
    if not petName then return nil end
    
    ELVUI_TAUNTALERT_FRAME_PET_INFO:ClearLines();
    ELVUI_TAUNTALERT_FRAME_PET_INFO:SetUnit(petName);
    local ownerText = ELVUI_TAUNTALERT_FRAME_PET_INFOTextLeft2:GetText();
    if not ownerText then return nil end
    local owner, _ = string.split("'", ownerText);
    return owner;
end


--[[
    Print Message to Chat Window
]]--
function TauntAlert:PrintToChatWindow(message, windowName)
    for i = 1, NUM_CHAT_WINDOWS, 1 do
        local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(i);
        if (name) and (name:trim() ~= "") and (tostring(name) == tostring(windowName)) then
            -- @NOTICE: Bypassing Ace:Print because it prepends the addon name
            -- TauntAlert:Print(_G["ChatFrame"..i], tostring(message));
            _G["ChatFrame"..i]:AddMessage(tostring(message));
        end
    end
end


--[[
    Format Chat Message
]]--
function TauntAlert:FormatChatMessage(tauntInfo)
    local target = "?";
    if (tauntInfo.target ~= nil) then
        target = tauntInfo.target;
    end

    local ownerSuffix = "";
    if (tauntInfo.petOwner ~= nil) then
        local className, classFilename = UnitClass(tauntInfo.petOwner);
        tauntInfo.class = className;
        if (className ~= nil and TauntAlert.DATA.CLASSES[className] ~= nil) then
            tauntInfo.class = className;
        end
        ownerSuffix = format("<%s>", TauntAlert.Colorize(tauntInfo.petOwner.."'s pet", TauntAlert.CLASS_COLORS[tauntInfo.class]));
    end

    local message = format(L["%s %s%s taunted <%s> using %s"],
        TauntAlert.Colorize("[TauntAlert]", TauntAlert.CHAT_COLOR),
        TauntAlert.Colorize(tauntInfo.caster, TauntAlert.CLASS_COLORS[tauntInfo.class]),
        ownerSuffix,
        TauntAlert.Colorize(target, TauntAlert.CHAT_COLOR),
        TauntAlert.Colorize(tauntInfo.ability, TauntAlert.CLASS_COLORS[tauntInfo.class])
    );
    if (tauntInfo.success ~= true) then
        local suffix = "";
        if (tauntInfo.reason ~= nil) then
            suffix = format("%s", TauntAlert.Colorize(tauntInfo.reason, TauntAlert.ERROR_COLOR));
        else
            suffix = format("%s", TauntAlert.Colorize(L["FAILED"], TauntAlert.ERROR_COLOR));
        end
        message = message..format(" (%s)", suffix);
    end

    return message;
end


--[[
    Colorize Text
]]--
function TauntAlert.Colorize(text, color)
    return format("%s%s%s", color, text, "|r") 
end


-- ========================================== --
--                                            --
-- MODULE REGISTRATION                        --
--                                            --
-- ========================================== --


--[[
    Initialization Hook
    Registers the Plugin with ElvUI, and Initialize Event Listeners.
]]--
function TauntAlert:Initialize()
    -- Register plugin so options are properly inserted when config is loaded
    EP:RegisterPlugin(addonName, TauntAlert.ConfigOptions);
    -- Create Frame needed to lookup Pet Owner
    TauntAlert:CreatePetOwnerFrame();
    -- Start handling events.
    TauntAlert:InitialEventRegistration();
end


-- Register the module with ElvUI. ElvUI will now call TauntAlert:Initialize() when ElvUI is ready to load our plugin.
E:RegisterModule(TauntAlert:GetName());
