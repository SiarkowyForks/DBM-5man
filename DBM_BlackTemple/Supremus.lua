local Supremus = DBM:NewBossMod("Supremus", DBM_SUPREMUS_NAME, DBM_SUPREMUS_DESCRIPTION, DBM_BLACK_TEMPLE, DBM_BT_TAB, 2);

Supremus.Version	= "1.2";
Supremus.Author		= "Tandanu, Siarkowy";
Supremus.MinRevision = 1080

local lastIcon		= nil;
local phase2		= nil

Supremus:RegisterCombat("COMBAT");

Supremus:RegisterEvents(
	"CHAT_MSG_RAID_BOSS_EMOTE",
	"SPELL_AURA_APPLIED"
);

Supremus:AddOption("WarnKiteTarget", true, DBM_SUPREMUS_OPTION_TARGETWARN);
Supremus:AddOption("IconKiteTarget", true, DBM_SUPREMUS_OPTION_TARGETICON);
Supremus:AddOption("WhisperKiteTarget", true, DBM_SUPREMUS_OPTION_TARGETWHISPER);

Supremus:AddBarOption("Enrage")
Supremus:AddBarOption("Kite Phase")
Supremus:AddBarOption("Tank & Spank Phase")

function Supremus:OnCombatStart(delay)
	self:StartStatusBarTimer(900 - delay, "Enrage", "Interface\\Icons\\Spell_Shadow_UnholyFrenzy")
	self:ScheduleAnnounce(300 - delay, DBM_GENERIC_ENRAGE_WARN:format(10, DBM_MIN), 1)
	self:ScheduleAnnounce(600 - delay, DBM_GENERIC_ENRAGE_WARN:format(5, DBM_MIN), 1)
	self:ScheduleAnnounce(720 - delay, DBM_GENERIC_ENRAGE_WARN:format(3, DBM_MIN), 1)
	self:ScheduleAnnounce(840 - delay, DBM_GENERIC_ENRAGE_WARN:format(1, DBM_MIN), 2)
	self:ScheduleAnnounce(870 - delay, DBM_GENERIC_ENRAGE_WARN:format(30, DBM_SEC), 3)
	self:ScheduleAnnounce(890 - delay, DBM_GENERIC_ENRAGE_WARN:format(10, DBM_SEC), 4)
	
	self:StartStatusBarTimer(60 - delay, "Kite Phase", "Interface\\Icons\\Spell_Fire_BurningSpeed");
	self:ScheduleSelf(50 - delay, "PhaseWarn", 2);
	self:ScheduleMethod(60 - delay, "SendSync", "KitePhase")
	lastIcon = nil;
	phase2 = nil
end

function Supremus:OnCombatEnd()
	if lastIcon then
		DBM.ClearIconByName(lastIcon);
		lastIcon = nil;
	end
end

function Supremus:OnSync(arg1)
	if arg1 then
		if arg1 == "TankPhase" then
			self:UnScheduleMethod("NewTarget")
			self:StartStatusBarTimer(60, "Kite Phase", "Interface\\Icons\\Spell_Fire_BurningSpeed");

			self:ScheduleSelf(50, "PhaseWarn", 2);
			self:ScheduleMethod(60, "SendSync", "KitePhase")
			self:Announce(DBM_SUPREMUS_WARN_PHASE_1, 3);
			if lastIcon then
				DBM.ClearIconByName(lastIcon);
				lastIcon = nil;
			end
			phase2 = nil
		elseif arg1 == "KitePhase" then
			self:StartStatusBarTimer(60, "Tank & Spank Phase", "Interface\\Icons\\Ability_Defend");
			self:ScheduleSelf(50, "PhaseWarn", 1);
			self:ScheduleMethod(60, "SendSync", "TankPhase")
			self:Announce(DBM_SUPREMUS_WARN_PHASE_2, 3);
			self:ScheduleMethod(1, "NewTarget")
			phase2 = true
		end		
	end
end

function Supremus:OnEvent(event, arg1)
	if event == "PhaseWarn" and arg1 then
		self:Announce(getglobal("DBM_SUPREMUS_WARN_PHASE_"..tostring(arg1).."_SOON"), 1);
	elseif event == "SPELL_AURA_APPLIED" then
		if arg1.spellId == 42052 and arg1.destName == UnitName("player") then
			self:AddSpecialWarning(DBM_SUPREMUS_SPECWARN_VOLCANO);
		end
	end
end

function Supremus:NewTarget()
	local target;
	for i = 1, GetNumRaidMembers() do
		if UnitName("raid"..i.."target") == DBM_SUPREMUS_NAME then
			target = UnitName("raid"..i.."targettarget");
			break
		end
	end	
	if target then
		if self.Options.WarnKiteTarget then
			self:Announce(DBM_SUPREMUS_WARN_KITE_TARGET:format(target), 2);
		end
		if self.Options.IconKiteTarget and DBM.Rank >= 1 and self.Options.Announce then
			lastIcon = target;
			self:SetIcon(target);
		end
		if self.Options.WhisperKiteTarget and DBM.Rank >= 1 and self.Options.Announce then
			self:SendHiddenWhisper(DBM_SUPREMUS_WHISPER_RUN_AWAY, target);
		end
	end

	self:ScheduleMethod(10, "NewTarget")
end