--Import: Engine, Locales, PrivateDB, ProfileDB, GlobalDB
local E, L, V, P, G = unpack(ElvUI);
local TauntAlert = E:GetModule("TauntAlert");


--[[
	Get Chat Windows
]]--
function TauntAlert:GetChatWindows()
	local ChatWindows = {};
	ChatWindows[TauntAlert.DISABLED_CHAT_WINDOW] = "< "..L["Disabled"].." >";
	for i = 1, NUM_CHAT_WINDOWS, 1 do
		local name, fontSize, r, g, b, alpha, shown, locked, docked, uninteractable = GetChatWindowInfo(i);
		if (name) and (tostring(name) ~= COMBAT_LOG) and (name:trim() ~= "") then
			ChatWindows[tostring(name)] = tostring(name);
		end
	end
	return ChatWindows;
end


--[[
	Get Sound Effect Option Names
	@see http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
]]--
function TauntAlert:GetSoundEffectOptionNames()
	local SoundEffectNames = {};
	for k, v in pairs(TauntAlert.SOUND_EFFECTS) do
		SoundEffectNames[k] = v.name;
	end
	return SoundEffectNames;
end


--[[
	Get Config Value
	Get the Users saved configuration value for the `key` provided
	If the User does not yet have a value for this key, the default value will be returned
]]--
function TauntAlert:GetConfigValue(key)
	return E.db.TauntAlert[key];
end


--[[
	Set Config Value
	Set the Users saved configuration value for the `key` provided
]]--
function TauntAlert:SetConfigValue(key, value)
	E.db.TauntAlert[key] = value;
	-- Play Sound
	local sid = TauntAlert.SOUND_EFFECTS[value].id;
	if (sid ~= nil) then
		PlaySound(sid);
	end
	-- Reload our Event Handlers
	TauntAlert:RefreshCombatLogMonitoring();
end


--[[
	Config Options
	Initialize Configuration Options using AceConfig.
	@see http://www.wowace.com/addons/ace3/pages/ace-config-3-0-options-tables/
]]--
function TauntAlert:ConfigOptions()
	E.Options.args.TauntAlert = {
		order = 100,
		type = "group",
		childGroups = "tree",
		name = TauntAlert.TITLE,
		args = {
			header1 = {
				order = 1,
				type = "header",
				name = format(L["%s (v%s) by %sPhoosa|r"], TauntAlert.TITLE, TauntAlert.VERSION, TauntAlert.CLASS_COLORS[L["Druid"]]),
			},
			global = {
				order = 2,
				type = "group",
				inline = true,
				name = L["Global"],
				args = {
					info = {
						order = 1,
						type = "description",
						name = L["Select which Scenarios you would like to receive Taunt Alerts for:"].."\n",
						width = "full"
					},
					SoloEnabled = {
						order = 2,
						type = "toggle",
						name = L["Solo Enabled"],
						desc = L["Enable TauntAlert when I'm not in a party or raid."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					PartyEnabled = {
						order = 3,
						type = "toggle",
						name = L["Party Enabled"],
						desc = L["Enable TauntAlert when I'm in a party."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					RaidEnabled = {
						order = 4,
						type = "toggle",
						name = L["Raid Enabled"],
						desc = L["Enable TauntAlert when I'm in a raid."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					BGEnabled = {
						order = 5,
						type = "toggle",
						name = L["BG Enabled"],
						desc = L["Enable TauntAlert when I'm in a Battleground."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
				}
			},
			display = {
				order = 3,
				type = "group",
				name = L["Display"],
				args = {
					ChatWindow = {
						order = 1,
						type = "select",
						values = TauntAlert.GetChatWindows,
						name = L["Chat Window"],
						desc = L["Select the Chat Window to display Taunt Details in. Only you will see the Taunt Alerts."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					info = {
						order = 2,
						type = "description",
						name = "\n\n"..L["Select which Taunts will be displayed in the Chat Window:"].."\n",
						width = "full"
					},
					DisplayMineSuccess = {
						order = 101,
						type = "toggle",
						name = L["My Taunts"],
						desc = L["My Successful Taunts will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					DisplayMineFailed = {
						order = 102,
						type = "toggle",
						name = L["My Failed Taunts"],
						desc = L["My Failed Taunts will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer1 = {
						order = 200,
						type = "description",
						name = "\n",
						width = "full"
					},
					DisplayPartySuccess = {
						order = 201,
						type = "toggle",
						name = L["Party Taunts"],
						desc = L["Party/Raid member Successful Taunts will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					DisplayPartyFailed = {
						order = 202,
						type = "toggle",
						name = L["Party Failed Taunts"],
						desc = L["Party/Raid member Failed Taunts will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer2 = {
						order = 300,
						type = "description",
						name = "\n",
						width = "full"
					},
					DisplayPartyPetSuccess = {
						order = 301,
						type = "toggle",
						name = L["Party Pet Taunts"],
						desc = L["Successful Taunts by Pets in my Party or Raid will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					DisplayPartyPetFailed = {
						order = 302,
						type = "toggle",
						name = L["Party Pet Failed Taunts"],
						desc = L["Failed Taunts by Pets in my Party or Raid will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer3 = {
						order = 400,
						type = "description",
						name = "\n",
						width = "full"
					},
					DisplayOtherPlayerSuccess = {
						order = 401,
						type = "toggle",
						name = L["Non-Party Taunts"],
						desc = L["Successful Taunts by Players NOT in my Party or Raid will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					DisplayOtherPlayerFailed = {
						order = 402,
						type = "toggle",
						name = L["Non-Party Failed Taunts"],
						desc = L["Failed Taunts by Players NOT in my Party or Raid will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer4 = {
						order = 500,
						type = "description",
						name = "\n",
						width = "full"
					},
					DisplayOtherPetSuccess = {
						order = 501,
						type = "toggle",
						name = L["Non-Party Pet Taunts"],
						desc = L["Successful Taunts by Pets NOT in my Party or Raid will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					DisplayOtherPetFailed = {
						order = 502,
						type = "toggle",
						name = L["Non-Party Pet Failed Taunts"],
						desc = L["Failed Taunts by Pets NOT in my Party or Raid will be displayed in the Chat Window."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					}
				}
			},
			sound = {
				order = 4,
				type = "group",
				name = L["Sounds"],
				args = {
					info = {
						order = 2,
						type = "description",
						name = L["Select the Sound Effect you would like to hear when a Taunt is detected:"].."\n",
						width = "full"
					},
					HearMineSuccess = {
						order = 101,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["My Taunts"],
						desc = L["My Successful Taunts will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					HearMineFailed = {
						order = 102,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["My Failed Taunts"],
						desc = L["My Failed Taunts will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer1 = {
						order = 200,
						type = "description",
						name = "\n",
						width = "full",
					},
					HearPartySuccess = {
						order = 201,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Taunts"],
						desc = L["Party/Raid member Successful Taunts will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					HearPartyFailed = {
						order = 202,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Failed Taunts"],
						desc = L["Party/Raid member Failed Taunts will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer2 = {
						order = 300,
						type = "description",
						name = "\n",
						width = "full",
					},
					HearPartyPetSuccess = {
						order = 301,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Pet Taunts"],
						desc = L["Successful Taunts by Pets in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					HearPartyPetFailed = {
						order = 302,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Pet Failed Taunts"],
						desc = L["Failed Taunts by Pets in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer3 = {
						order = 400,
						type = "description",
						name = "\n",
						width = "full",
					},
					HearOtherPlayerSuccess = {
						order = 401,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Taunts"],
						desc = L["Successful Taunts by Players NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					HearOtherPlayerFailed = {
						order = 402,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Failed Taunts"],
						desc = L["Failed Taunts by Players NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					spacer4 = {
						order = 500,
						type = "description",
						name = "\n",
						width = "full",
					},
					HearOtherPetSuccess = {
						order = 501,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Pet Taunts"],
						desc = L["Successful Taunts by Pets NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					HearOtherPetFailed = {
						order = 502,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Pet Failed Taunts"],
						desc = L["Failed Taunts by Pets NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					}
				}
			}
		}
	};
end
