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


local TAUNT_TYPE_SINGLE = "Single";
local TAUNT_TYPE_AOE    = "AOE";

local SPELL_EVENT_TYPE_CAST = "CAST";
local SPELL_EVENT_TYPE_AURA = "AURA";

local SPELL_CAST_STATUS_SUCCESS = L["SUCCESS"];
local SPELL_CAST_STATUS_FAILED  = L["FAILED"];
local SPELL_CAST_STATUS_MISSED  = L["MISSED"];
local SPELL_AURA_STATUS_APPLIED = L["APPLIED"];
local SPELL_AURA_STATUS_REMOVED = L["REMOVED"];

local SPELL_CASTER_TYPE_ME 		  = "ME";
local SPELL_CASTER_TYPE_PARTY 	  = "PARTY";
local SPELL_CASTER_TYPE_PARTY_PET = "PARTY_PET";
local SPELL_CASTER_TYPE_OTHER 	  = "OTHER";
local SPELL_CASTER_TYPE_OTHER_PET = "OTHER_PET";


-- ========================================== --
--                                            --
-- MODULE CONSTANTS                           --
--                                            --
-- ========================================== --


TauntAlert.PLAYER_NAME, TauntAlert.PLAYER_REALM = UnitName("player");
TauntAlert.TITLE = "Taunt Alert";
TauntAlert.VERSION = GetAddOnMetadata("ElvUI_TauntAlert", "Version")
TauntAlert.ERROR_COLOR = "|cfffa2f47";
TauntAlert.CHAT_COLOR = "|cff2f9bfa";
TauntAlert.DISABLED_CHAT_WINDOW = "__none__";
TauntAlert.CLASS_COLORS = {
	[L["Druid"]]    = "|cffFF7D0A",
	[L["Hunter"]]   = "|cffABD473",
	[L["Mage"]]     = "|cff69CCF0",
	[L["Paladin"]]  = "|cffF58CBA",
	[L["Priest"]]   = "|cffFFFFFF",
	[L["Rogue"]]    = "|cffFFF569",
	[L["Shaman"]]   = "|cff0070DE",
	[L["Warlock"]]  = "|cff9482C9",
	[L["Warrior"]]  = "|cffC79C6E"
};
TauntAlert.SOUND_EFFECTS = {
	ArcaneExplosion = {
		name = L["Arcane Explosion"],
		id = 6539
	},
	ArcaneInt = {
		name = L["Arcane Intellect"],
		id = 1422
	},
	Bell = {
		name = L["Bell"],
		id = 6595
	},
	Bell2 = {
		name = L["Bell 2"],
		id = 6594
	},
	Bell3 = {
		name = L["Bell 3"],
		id = 6674
	},
	BellowIn = {
		name = L["Bellow In"],
		id = 8672
	},
	BellowOut = {
		name = L["Bellow Out"],
		id = 8673
	},
	BreakBox = {
		name = L["Break Box"],
		id = 4784
	},
	CageOpen = {
		name = L["Cage Open"],
		id = 4674
	},
	Cannon = {
		name = L["Cannon"],
		id = 1400
	},
	Elevator1 = {
		name = L["Elevator Start"],
		id = 7181
	},
	GoblinDeath = {
		name = L["Goblin Death"],
		id = 1411
	},
	GoblinLaugh = {
		name = L["Goblin Laugh"],
		id = 1416
	},
	LevelUp = {
		name = L["Level Up"],
		id = 1440
	},
	QuestFail = {
		name = L["Quest Fail"],
		id = 847
	},
	Warped = {
		name = L["Warped"],
		id = 8156
	},
	__no_sound__ = {
		name = "< "..L["No Sound"].." >",
		id = nil
	}
};
TauntAlert.TAUNTS = {
	[L["Taunt"]] = {
		type = TAUNT_TYPE_SINGLE,
		class = L["Warrior"]
	},
	[L["Growl"]] = {
		type = TAUNT_TYPE_SINGLE,
		class = L["Druid"]
	},
	[L["Distracting Shot"]] = {
		type = TAUNT_TYPE_SINGLE,
		class = L["Hunter"]
	},
	[L["Mocking Blow"]] = {
		type = TAUNT_TYPE_SINGLE,
		class = L["Warrior"]
	},
	[L["Challenging Shout"]] = {
		type = TAUNT_TYPE_AOE,
		class = L["Warrior"]
	},
	[L["Challenging Roar"]] = {
		type = TAUNT_TYPE_AOE,
		class = L["Druid"]
	}
};


-- ========================================== --
--                                            --
-- EVENT REGISTRATION                         --
--                                            --
-- ========================================== --

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

	-- Was a Taunt Detected?
	if (logData.taunt ~= nil) then
		-- print("["..tostring(logData.event).."] ".."Taunt: "..tostring(logData.sourceName).." taunted <"..tostring(logData.destinationName).."> using "..tostring(logData.spellName).." ~~ "..tostring(logData.event));
		-- print("Event["..logData.spellEventType.."="..SPELL_EVENT_TYPE_CAST.."] and ["..logData.spellEventStatus.."~="..SPELL_CAST_STATUS_SUCCESS.."]");
		-- print("Event["..logData.spellEventType.."="..SPELL_EVENT_TYPE_AURA.."] and ["..logData.spellEventStatus.."=="..SPELL_AURA_STATUS_APPLIED.."]");
		local tauntInfo = {
			caster      = logData.sourceName,
			casterType	= nil,
			target      = logData.destinationName,
			ability     = logData.spellName,
			type 		= logData.taunt.type,
			class 		= nil,
			success 	= nil,
			reason 		= nil,
		};

		local className, classFilename = UnitClass(logData.sourceName);
		tauntInfo.class = className;

		-- Who taunted?
		if (UnitIsPlayer(logData.sourceName) and TauntAlert.PLAYER_NAME == logData.sourceName) then
			tauntInfo.casterType = SPELL_CASTER_TYPE_ME;
		elseif (UnitInParty(logData.sourceName) or UnitInRaid(logData.sourceName)) then
			if (UnitIsPlayer(logData.sourceName)) then
				tauntInfo.casterType = SPELL_CASTER_TYPE_PARTY;
			else 
				tauntInfo.casterType = SPELL_CASTER_TYPE_PARTY_PET;
			end
		elseif (UnitIsPlayer(logData.sourceName)) then
			tauntInfo.casterType = SPELL_CASTER_TYPE_OTHER;
		else
			tauntInfo.casterType = SPELL_CASTER_TYPE_OTHER_PET;
		end

		-- NOTE: Ignoring SPELL_CAST_SUCCESS, checking SPELL_AURA_APPLIED instead for successful taunts
		if (logData.spellEventType == SPELL_EVENT_TYPE_CAST) then
			if (logData.spellEventStatus ~= SPELL_CAST_STATUS_SUCCESS) then
				tauntInfo.success = false;
				tauntInfo.reason = logData.spellEventStatus;
				if (logData.spellFailedReason) then
					tauntInfo.reason = logData.spellEventStatus;
				end
				TauntAlert:ProcessTaunt(tauntInfo);
			end
		elseif (logData.spellEventType == SPELL_EVENT_TYPE_AURA) then
			-- Successful taunt
			if (logData.spellEventStatus == SPELL_AURA_STATUS_APPLIED) then
				tauntInfo.success = true;
				TauntAlert:ProcessTaunt(tauntInfo);
			end
		end

		-- -- Was it an AOE or single target taunt?
		-- if (logData.taunt.type == TAUNT_TYPE_SINGLE and logData.spellEventType == SPELL_EVENT_TYPE_CAST) then
		-- 	tauntInfo.success = (logData.spellEventStatus == SPELL_CAST_STATUS_SUCCESS);
		-- 	if (tauntInfo.success ~= true) then
		-- 		tauntInfo.reason = logData.spellEventStatus;
		-- 		if (logData.spellFailedReason) then
		-- 			tauntInfo.reason = logData.spellEventStatus;
		-- 		end
		-- 	end
		-- 	if (tauntInfo.target ~= nil) then
		-- 		-- Notify the player of the Taunt.
		-- 		TauntAlert:ProcessTaunt(tauntInfo);
		-- 	end
		-- -- elseif (logData.taunt.type == TAUNT_TYPE_AOE and logData.spellEventType == SPELL_EVENT_TYPE_AURA) then
		-- elseif (logData.taunt.type == TAUNT_TYPE_AOE) then
		-- 	if (logData.spellEventType == SPELL_EVENT_TYPE_CAST and logData.spellEventStatus ~= SPELL_CAST_STATUS_SUCCESS) then
		-- 		-- Display Failed/Missed Events
		-- 		tauntInfo.success = false;
		-- 		tauntInfo.reason = logData.spellEventStatus;
		-- 		if (logData.spellFailedReason) then
		-- 			tauntInfo.reason = logData.spellEventStatus;
		-- 		end
		-- 		TauntAlert:ProcessTaunt(tauntInfo);
		-- 	elseif (logData.spellEventType == SPELL_EVENT_TYPE_AURA and logData.spellEventStatus == SPELL_AURA_STATUS_APPLIED) then
		-- 		-- Display Success Events
		-- 		tauntInfo.success = true;
		-- 		TauntAlert:ProcessTaunt(tauntInfo);
		-- 	end
		-- end
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
		if (window ~= nil and window ~= TauntAlert.DISABLED_CHAT_WINDOW and tauntInfo.target ~= nil) then
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
		timestamp 				= tEventInfo[1],
		event 					= tEventInfo[2],
		hideCaster				= tEventInfo[3],
		sourceGuid 				= tEventInfo[4],
		sourceName 				= tEventInfo[5],
		sourceFlags 			= tEventInfo[6],
		sourceRaidFlags 		= tEventInfo[7],
		destinationGuid 		= tEventInfo[8],
		destinationName 		= tEventInfo[9],
		destinationFlags		= tEventInfo[10],
		destinationRaidFlags 	= tEventInfo[11],
		isSpell                 = (tEventInfo[2]:sub(1,5) == "SPELL")
	};

	-- Add Spell Details if this is a Spell Event
	if (eventInfo.isSpell) then
		eventInfo.spellId      			= tEventInfo[12];
		eventInfo.spellName    			= tEventInfo[13];
		eventInfo.spellSchool  			= tEventInfo[14];
		eventInfo.taunt 				= TauntAlert.TAUNTS[eventInfo.spellName];

		-- Get Cast/Aura and Status.
		if (eventInfo.event:sub(1, 10) == "SPELL_AURA") then
			eventInfo.spellEventType = SPELL_EVENT_TYPE_AURA;
			if (eventInfo.event == "SPELL_AURA_APPLIED") then
				eventInfo.spellEventStatus = SPELL_AURA_STATUS_APPLIED;
			elseif (eventInfo.event == "SPELL_AURA_REMOVED" or eventInfo.event == "SPELL_AURA_BROKEN" or eventInfo.event == "SPELL_AURA_BROKEN_SPELL") then
				eventInfo.spellEventStatus = SPELL_AURA_STATUS_REMOVED;
			-- else
			-- 	print("AURA Unhandled Event Status: "..eventInfo.event.." | FOR: "..eventInfo.spellName);
			end
		else
			if (eventInfo.event:sub(1, 10) == "SPELL_CAST") then
				eventInfo.spellEventType = SPELL_EVENT_TYPE_CAST;
				if (eventInfo.event == "SPELL_CAST_SUCCESS") then
					eventInfo.spellEventStatus = SPELL_CAST_STATUS_SUCCESS;
				elseif (eventInfo.event == "SPELL_CAST_FAILED") then
					eventInfo.spellEventStatus = SPELL_CAST_STATUS_FAILED;
					eventInfo.spellFailedReason = tEventInfo[15];
					-- print(format("timestamp:%s, event:%s, hideCaster:%s, sourceFlags:%s, destinationGuid:%s, destinationName:%s, destinationFlags:%s, spellId:%s, spellName:%s, spellSchool:%s, failedType:%s",
					-- 	tostring(eventInfo.eventInfo),
					-- 	tostring(eventInfo.event),
					-- 	tostring(eventInfo.hideCaster),
					-- 	tostring(eventInfo.sourceFlags),
					-- 	tostring(eventInfo.destinationGuid),
					-- 	tostring(eventInfo.destinationName),
					-- 	tostring(eventInfo.destinationFlags),
					-- 	tostring(eventInfo.spellId),
					-- 	tostring(eventInfo.spellName),
					-- 	tostring(eventInfo.spellSchool),
					-- 	tostring(eventInfo.failedType)

					-- ));
				-- else
				-- 	print("SPELL Unhandled Event Status: "..eventInfo.event.." | FOR: "..eventInfo.spellName);
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

	local message = format(L["%s %s taunted <%s> using %s"],
		TauntAlert.Colorize("[TauntAlert]", TauntAlert.CHAT_COLOR),
		TauntAlert.Colorize(tauntInfo.caster, TauntAlert.CLASS_COLORS[tauntInfo.class]),
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
	-- Start handling events.
	TauntAlert:InitialEventRegistration();
end


-- Register the module with ElvUI. ElvUI will now call TauntAlert:Initialize() when ElvUI is ready to load our plugin.
E:RegisterModule(TauntAlert:GetName());