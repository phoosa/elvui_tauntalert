--Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local E, L, V, P, G = unpack(ElvUI);
--Create a plugin within ElvUI and adopt AceHook-3.0, AceEvent-3.0 and AceTimer-3.0. We can make use of these later.
local TauntAlert = E:NewModule("TauntAlert", "AceHook-3.0", "AceEvent-3.0", "AceTimer-3.0", "AceConsole-3.0");
--We can use this to automatically insert our GUI tables when ElvUI_Config is loaded.
local EP = LibStub("LibElvUIPlugin-1.0");
local LSM = E.Libs.LSM;
--See http://www.wowinterface.com/forums/showthread.php?t=51502&p=304704&postcount=2
local addonName, addonTable = ...;


-- ========================================== --
--                                            --
-- LOCAL CONSTANTS                            --
--                                            --
-- ========================================== --

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
TauntAlert.TAUNT_TYPES = {
    Single   = "Single",
    AOE      = "AOE",
    TRANS    = "Transfer"
};
TauntAlert.SUCCESS_EVENT_TYPES = {
    AURA = 'AURA',
    CAST = 'CAST'
};
TauntAlert.SPELL_CAST_STATUS = {
    SUCCESS = 'SUCCESS',
    FAILED  = 'FAILED',
    MISSED  =  'MISSED'
};
TauntAlert.SPELL_AURA_STATUS = {
    APPLIED = 'APPLIED',
    REMOVED = 'REMOVED'
};
TauntAlert.SPELL_CASTER_TYPE ={
    ME        = 'ME',
    PARTY     = 'PARTY',
    PARTY_PET = 'PARTY_PET',
    OTHER     = 'OTHER',
    OTHER_PET = 'OTHER_PET'
};
TauntAlert.CLASSES = {
    DRUID       = 'DRUID',
    DEATHKNIGHT = 'DEATHKNIGHT',
    HUNTER      = 'HUNTER',
    MAGE        = 'MAGE',
    PALADIN     = 'PALADIN',
    PRIEST      = 'PRIEST',
    ROGUE       = 'ROGUE',
    SHAMAN      = 'SHAMAN',
    WARLOCK     = 'WARLOCK',
    WARRIOR     = 'WARRIOR'
}
TauntAlert.COLORS = {
    WHITE                       = "|cffFFFFFF",
    RED                         = "|cffC41E3A",
    ORANGE                      = "|cffFF7D0A",
    YELLOW                      = "|cffFFF569",
    GREEN                       = "|cffABD473",
    CYAN                        = "|cff69CCF0",
    BLUE                        = "|cff0070DE",
    PURPLE                      = "|cff9482C9",
    PINK                        = "|cffF58CBA",
    BROWN                       = "|cffC79C6E"
};
TauntAlert.CLASS_COLOR = {
    DRUID                       = TauntAlert.COLORS.ORANGE,
    DEATHKNIGHT                 = TauntAlert.COLORS.RED,
    HUNTER                      = TauntAlert.COLORS.GREEN,
    MAGE                        = TauntAlert.COLORS.CYAN,
    PALADIN                     = TauntAlert.COLORS.PINK,
    PRIEST                      = TauntAlert.COLORS.WHITE,
    ROGUE                       = TauntAlert.COLORS.YELLOW,
    SHAMAN                      = TauntAlert.COLORS.BLUE,
    WARLOCK                     = TauntAlert.COLORS.PURPLE,
    WARRIOR                     = TauntAlert.COLORS.BROWN
};

TauntAlert.isMonitoringLog = false;


-- ========================================== --
--                                            --
-- EVENT REGISTRATION                         --
--                                            --
-- ========================================== --

--[[
    Initialize Announce Frame
]]--
function TauntAlert:InitializeAnnounceFrame()
    ELVUI_TAUNTALERT_FRAME_ANNOUNCE:FontTemplate(LSM:Fetch("font"));

    E:CreateMover(ELVUI_TAUNTALERT_FRAME_ANNOUNCE, "TauntAlert_Announce_Mover", "Taunt Alert "..L["Announcements"]);
end

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
    if (TauntAlert:ShouldMonitorCombatLog() and not TauntAlert.isMonitoringLog) then
        self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED", "OnCombatLogEvent");
        TauntAlert.isMonitoringLog = true;
    else
        self:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED");
        TauntAlert.isMonitoringLog = false;
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
    if (logData.taunt ~= nil and (logData.destinationName ~= nil or logData.taunt.type == TauntAlert.TAUNT_TYPES.AOE)) then
        if (E.db.TauntAlert.spells[tostring(logData.spellId)]) then
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
                tauntInfo.casterType = TauntAlert.SPELL_CASTER_TYPE.ME;
            elseif CombatLog_Object_IsA(logData.sourceFlags, COMBATLOG_FILTER_MY_PET) then
                tauntInfo.casterType = TauntAlert.SPELL_CASTER_TYPE.PARTY_PET;
                tauntInfo.petOwner = TauntAlert:getPetOwner(tauntInfo.caster);
            elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_PARTY_RAID_PET) then
                tauntInfo.casterType = TauntAlert.SPELL_CASTER_TYPE.PARTY_PET;
                tauntInfo.petOwner = TauntAlert:getPetOwner(tauntInfo.caster);
            elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_PARTY_RAID_PLAYER) then
                tauntInfo.casterType = TauntAlert.SPELL_CASTER_TYPE.PARTY;
            elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_OTHER_PET) then
                tauntInfo.casterType = TauntAlert.SPELL_CASTER_TYPE.OTHER_PET;
                tauntInfo.petOwner = TauntAlert:getPetOwner(tauntInfo.caster);
            elseif CombatLog_Object_IsA(logData.sourceFlags, BIT_OUTSIDER_PLAYER) then
                tauntInfo.casterType = TauntAlert.SPELL_CASTER_TYPE.OTHER;
            else
                tauntInfo.casterType = TauntAlert.SPELL_CASTER_TYPE.OTHER;
            end

            if (logData.spellEventType == TauntAlert.SUCCESS_EVENT_TYPES.CAST) then
                if (logData.spellEventStatus ~= TauntAlert.SPELL_CAST_STATUS.SUCCESS) then
                    tauntInfo.success = false;
                    tauntInfo.reason = logData.spellEventStatus;
                    if (logData.spellFailedReason) then
                        tauntInfo.reason = logData.spellEventStatus;
                    end
                    TauntAlert:ProcessTaunt(tauntInfo);
                elseif (logData.taunt.successEventType == TauntAlert.SUCCESS_EVENT_TYPES.CAST) then
                    -- NOTICE: We only announce "successful" casts if the event
                    tauntInfo.success = true;
                    TauntAlert:ProcessTaunt(tauntInfo);
                end
            elseif (logData.spellEventType == TauntAlert.SUCCESS_EVENT_TYPES.AURA) then
                if (
                    logData.taunt.successEventType == TauntAlert.SUCCESS_EVENT_TYPES.AURA
                    and (logData.spellEventStatus == TauntAlert.SPELL_AURA_STATUS.APPLIED or logData.spellEventStatus == TauntAlert.SPELL_CAST_STATUS.SUCCESS)
                ) then
                    tauntInfo.success = true;
                    TauntAlert:ProcessTaunt(tauntInfo);
                end
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
        TauntAlert:AnnounceMessage(TauntAlert:FormatChatMessage(tauntInfo));
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
            eventInfo.spellEventType = TauntAlert.SUCCESS_EVENT_TYPES.AURA;
            if (eventInfo.event == "SPELL_AURA_APPLIED") then
                eventInfo.spellEventStatus = TauntAlert.SPELL_AURA_STATUS.APPLIED;
            elseif (eventInfo.event == "SPELL_AURA_REMOVED" or eventInfo.event == "SPELL_AURA_BROKEN" or eventInfo.event == "SPELL_AURA_BROKEN_SPELL") then
                eventInfo.spellEventStatus = TauntAlert.SPELL_AURA_STATUS.REMOVED;
            end
        else
            if (eventInfo.event:sub(1, 10) == "SPELL_CAST") then
                eventInfo.spellEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST;
                if (eventInfo.event == "SPELL_CAST_SUCCESS") then
                    eventInfo.spellEventStatus = TauntAlert.SPELL_CAST_STATUS.SUCCESS;
                elseif (eventInfo.event == "SPELL_CAST_FAILED") then
                    eventInfo.spellEventStatus = TauntAlert.SPELL_CAST_STATUS.FAILED;
                    eventInfo.spellFailedReason = tEventInfo[15];
                -- I should only track SPELL_CAST_MISSED and SPELL_AURA_APPLIED
                end
            elseif (eventInfo.event == "SPELL_MISSED") then
                eventInfo.spellEventType = TauntAlert.SUCCESS_EVENT_TYPES.CAST;
                eventInfo.spellEventStatus = TauntAlert.SPELL_CAST_STATUS.MISSED;
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
    [TauntAlert.SPELL_CASTER_TYPE.ME] = function (tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayMineSuccess");
        else
            return TauntAlert:GetConfigValue("DisplayMineFailed");
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.PARTY] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayPartySuccess");
        else
            return TauntAlert:GetConfigValue("DisplayPartyFailed");
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.PARTY_PET] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayPartyPetSuccess");
        else
            return TauntAlert:GetConfigValue("DisplayPartyPetFailed");
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.OTHER] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert:GetConfigValue("DisplayOtherPlayerSuccess");
        else
            return TauntAlert:GetConfigValue("DisplayOtherPlayerFailed");
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.OTHER_PET] = function(tauntInfo)
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
    [TauntAlert.SPELL_CASTER_TYPE.ME] = function (tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearMineSuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearMineFailed")].id;
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.PARTY] = function(tauntInfo)
        if (tauntInfo.type == TauntAlert.TAUNT_TYPES.TRANS) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartyTransfer")].id;
        elseif (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartySuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartyFailed")].id;
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.PARTY_PET] = function(tauntInfo)
        if (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartyPetSuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearPartyPetFailed")].id;
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.OTHER] = function(tauntInfo)
        if (tauntInfo.type == TauntAlert.TAUNT_TYPES.TRANS) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearOtherTransfer")].id;
        elseif (tauntInfo.success) then
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearOtherPlayerSuccess")].id;
        else 
            return TauntAlert.SOUND_EFFECTS[TauntAlert:GetConfigValue("HearOtherPlayerFailed")].id;
        end
    end,
    [TauntAlert.SPELL_CASTER_TYPE.OTHER_PET] = function(tauntInfo)
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
    Announce a Message to the appropriate location (frame or chat)
]]--
function TauntAlert:AnnounceMessage(msg)
    local location = TauntAlert:GetConfigValue('AnnounceLocation');
    if (location == 'hud') then
        ELVUI_TAUNTALERT_FRAME_ANNOUNCE:AddMessage(msg, 1, 1, 1, 1.0);
    elseif (location == 'chat') then
        TauntAlert:PrintToChatWindow(
            format(L["%s %s"], TauntAlert.Colorize("[TauntAlert]", TauntAlert.CHAT_COLOR), msg));
    end
end


--[[
    Debug logging
]]--
function TauntAlert:log(message)
    TauntAlert:PrintToChatWindow(tostring(message), 1);
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
function TauntAlert:PrintToChatWindow(message, window)
    if (window == nil) then
        local windowName = TauntAlert:GetConfigValue('ChatWindow');
        if (windowName ~= TauntAlert.DISABLED_CHAT_WINDOW) then
            for i = 1, NUM_CHAT_WINDOWS, 1 do
                local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(i);
                if (name) and (name:trim() ~= "") and (tostring(name) == tostring(windowName)) then
                    window = i;
                    break;
                end
            end
        end
    end

    if (window ~= nil) then
        -- @NOTICE: Bypassing Ace:Print because it prepends the addon name
        _G["ChatFrame"..window]:AddMessage(tostring(message));
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
        local className, classKey = UnitClass(tauntInfo.petOwner);
        if (classKey ~= nil and TauntAlert.CLASSES[classKey] ~= nil) then
            tauntInfo.class = classKey;
        end
        ownerSuffix = format("<%s>", TauntAlert.Colorize(format(L["%s's pet"], tauntInfo.petOwner), TauntAlert.CLASS_COLOR[tauntInfo.class]));
    end

    local message = format(L["%s%s taunted <%s> using %s"],
        TauntAlert.Colorize(tauntInfo.caster, TauntAlert.CLASS_COLOR[tauntInfo.class]),
        ownerSuffix,
        TauntAlert.Colorize(target, TauntAlert.CHAT_COLOR),
        TauntAlert.Colorize(tauntInfo.ability, TauntAlert.CLASS_COLOR[tauntInfo.class])
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
    -- Create Announcement Frame.
    TauntAlert:InitializeAnnounceFrame();
    -- Create Frame needed to lookup Pet Owner
    TauntAlert:CreatePetOwnerFrame();
    -- Start handling events.
    TauntAlert:InitialEventRegistration();
end


-- Register the module with ElvUI. ElvUI will now call TauntAlert:Initialize() when ElvUI is ready to load our plugin.
E:RegisterModule(TauntAlert:GetName());
