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
	local sound = TauntAlert.SOUND_EFFECTS[value];
	if (sound ~= nil and sound.id ~= nil) then
		PlaySound(sound.id);
	end
	-- Reload our Event Handlers
	TauntAlert:RefreshCombatLogMonitoring();
end


--[[
	Get Config Value for Spell
	Get the Users saved Spell configuration value for the `sid` provided
]]--
function TauntAlert:GetSpellConfigValue(sid)
	return E.db.TauntAlert.spells[sid];
end


--[[
	Set Spell Config Value
	Set the Users saved Spell configuration value for all spells matching the `spell.group`
]]--
function TauntAlert:SetSpellConfigValue(spell, value)
    for k, v in pairs(TauntAlert.TAUNTS) do
        if (v.group == spell.group) then
            E.db.TauntAlert.spells[k] = value;
        end
	end
	-- Reload our Event Handlers
	TauntAlert:RefreshCombatLogMonitoring();
end

--[[
    Render Taunt Spells Config Toggles
]]--
function RenderTauntSpells()
    local returnVal = {};
    for k,spell in pairs(TauntAlert.TAUNTS) do
        local name = GetSpellInfo(tonumber(k));
        if (nil ~= name) then
            if (nil == returnVal[spell.class]) then
                returnVal[spell.class] = {
                    type = "group",
                    inline = true,
                    name = TauntAlert.Colorize(spell.class, TauntAlert.CLASS_COLOR[spell.class]),
                    args = {}
                };
            end
            
            if (spell.type == TauntAlert.TAUNT_TYPES.TRANS) then
                name = name ..' '..L["(Transfer)"];
            elseif (spell.type == TauntAlert.TAUNT_TYPES.AOE) then
                name = name ..' '..L["(AOE)"];
            end

            returnVal[spell.class].args[name] = {
                type = "toggle",
                name = tostring(name),
                width = "full",
                get = function(info) return TauntAlert:GetSpellConfigValue(k); end,
                set = function(info, v) TauntAlert:SetSpellConfigValue(spell, v); end
            }
        end
    end
    return returnVal;
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
                name = format(L["%s (v%s) by %sFoosader|r"], TauntAlert.TITLE, TauntAlert.VERSION, TauntAlert.CLASS_COLOR.PALADIN)
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
                    DisplayPartyTransfer = {
                        order = 203,
						type = "toggle",
						name = L["Party Threat Transfer"],
						desc = L["Party/Raid member Threat Transfers will be displayed in the Chat Window."],
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
                    DisplayOtherPlayerTransfer = {
                        order = 403,
						type = "toggle",
						name = L["Non-Party Threat Transfer"],
						desc = L["Threat Transfers by Players NOT in my Party or Raid will be displayed in the Chat Window."],
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
                    _successHeader = {
                        order = 99,
                        type = "header",
                        name = L["Successful Taunt Sounds"]
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
                    HearPartySuccess = {
						order = 102,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Taunts"],
						desc = L["Party/Raid member Successful Taunts will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    HearPartyPetSuccess = {
						order = 103,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Pet Taunts"],
						desc = L["Successful Taunts by Pets in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    HearOtherPlayerSuccess = {
						order = 104,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Taunts"],
						desc = L["Successful Taunts by Players NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    HearOtherPetSuccess = {
						order = 105,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Pet Taunts"],
						desc = L["Successful Taunts by Pets NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    _transferHeader = {
                        order = 199,
                        type = "header",
                        name = L["Threat Transfer Sounds"]
                    },
                    HearPartyTransfer = {
						order = 202,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Threat Transfer"],
						desc = L["Party/Raid member Successful Threat Transfers will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    HearOtherTransfer = {
						order = 203,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Threat Transfer"],
						desc = L["Successful Threat Transfers by Players NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    _failHeader = {
                        order = 299,
                        type = "header",
                        name = L["Failed Taunt Sounds"]
                    },
					HearMineFailed = {
						order = 301,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["My Failed Taunts"],
						desc = L["My Failed Taunts will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    HearPartyFailed = {
						order = 302,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Failed Taunts"],
						desc = L["Party/Raid member Failed Taunts will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
                    HearPartyPetFailed = {
						order = 303,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Party Pet Failed Taunts"],
						desc = L["Failed Taunts by Pets in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					HearOtherPlayerFailed = {
						order = 304,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Failed Taunts"],
						desc = L["Failed Taunts by Players NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					},
					HearOtherPetFailed = {
						order = 304,
						type = "select",
						values = TauntAlert.GetSoundEffectOptionNames,
						name = L["Non-Party Pet Failed Taunts"],
						desc = L["Failed Taunts by Pets NOT in my Party or Raid will trigger this sound effect."],
						width = "normal",
						get = function(info) return TauntAlert:GetConfigValue(info[3]); end,
						set = function(info, v) TauntAlert:SetConfigValue(info[3], v); end
					}
				}
			},
            taunts = {
                order = 5,
                type = "group",
                name = L["Taunts"],
                args = RenderTauntSpells()
            }
		}
	};
end
