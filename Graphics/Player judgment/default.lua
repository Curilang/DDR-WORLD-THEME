local c;
local args = ...
if type(args) ~= "table" then args = nil end
local pn = (args and args.Player) or Var "Player"
local isCopy = args ~= nil and args.Copy == true

-- El motor no le pasa Var "Player" al actor HoldJudgment, pero lo carga justo después de este archivo.
-- Se deja aquí el dueño para que lo lea HoldJudgment label 1x2 (solo en la instancia del motor, no en la copia).
if not isCopy and pn then
	HoldJudgmentOwner = pn
end

function ShowFastSlow(pn)
	if pn and POMenu and POMenu.FastSlowOn then
		return POMenu.FastSlowOn(pn)
	end
	return true
end

local showFastSlow = true

-- JUDGMENT DISPLAY POSITION = FAR: the judgment (and its FAST/SLOW) goes down under the combo, away from the
-- receptors. 144 units (106 from the reference images + 38 so it clears the COMBO!!! label in game);
-- mirrored when the arrows are reversed.
local function PositionShift()
	if POMenu and POMenu.JudgmentBelow and POMenu.JudgmentBelow(pn) then
		return IsReverse(pn) and -144 or 144
	end
	return 0
end

-- FAST/SLOW always sits between the judgment and the combo, close to the judgment (measured on arcade
-- screenshots, about 24 units): below the judgment when the judgment is above the combo, above it when the
-- judgment is below the combo. The judgment is above the combo with NEAR in normal mode and with FAR in reverse.
local function FastSlowY()
	local far = POMenu and POMenu.JudgmentBelow and POMenu.JudgmentBelow(pn) and true or false
	local towardCombo = (IsReverse(pn) ~= far) and -1 or 1
	return 2 + PositionShift() + towardCombo * 24
end

local tTotalJudgments = {};

local JudgeCmds = {
	TapNoteScore_W1 = cmd(diffusealpha,1;zoom,0.68;linear,0.036;zoom,0.66;sleep,0.434;diffusealpha,0);
	TapNoteScore_W2 = cmd(diffusealpha,1;zoom,0.68;linear,0.036;zoom,0.66;sleep,0.434;diffusealpha,0);
	TapNoteScore_W3 = cmd(diffusealpha,1;zoom,0.68;linear,0.036;zoom,0.66;sleep,0.434;diffusealpha,0);
	TapNoteScore_W4 = cmd(diffusealpha,1;zoom,0.68;linear,0.036;zoom,0.66;sleep,0.434;diffusealpha,0);
	TapNoteScore_W5 = cmd(diffusealpha,1;zoom,0.68;sleep,0.5;diffusealpha,0);
	TapNoteScore_Miss = cmd(diffusealpha,1;zoom,0.62;sleep,0.5;diffusealpha,0);
	TapNoteScore_AvoidMine = cmd(diffusealpha,1;zoom,0.68;linear,0.036;zoom,0.66;sleep,0.434;diffusealpha,0);
	TapNoteScore_HitMine = cmd(diffusealpha,1;zoom,0.68;linear,0.036;zoom,0.66;sleep,0.434;diffusealpha,0);
};

local TNSFrames = {
	TapNoteScore_W1 = 0;
	TapNoteScore_W2 = 1;
	TapNoteScore_W3 = 2;
	TapNoteScore_W4 = 3;
	TapNoteScore_W5 = 4;
	TapNoteScore_Miss = 4;
	TapNoteScore_AvoidMine = 5;
	TapNoteScore_HitMine = 6;
};

local t = Def.ActorFrame {};



t[#t+1] = Def.ActorFrame {
	LoadActor("FastSlow")..{
	InitCommand=function(s)
		showFastSlow = ShowFastSlow(pn)
		s:diffusealpha(0):animate(false):xy(0,FastSlowY())
	end,
	JudgmentMessageCommand=function(s, p)
		if p.Player ~= pn then return end;
		if not showFastSlow then return end;
		if 		p.TapNoteScore == 'TapNoteScore_W1' 
			or 	p.TapNoteScore == 'TapNoteScore_W5' 
			or	p.TapNoteScore == 'TapNoteScore_Miss'
			or	p.TapNoteScore == 'TapNoteScore_HitMine' 
			or	p.TapNoteScore == 'TapNoteScore_AvoidMine' 
			or	p.HoldNoteScore 
		then return end;
		s:finishtweening();
		if p.Early then
			s:setstate(0);
		else
			s:setstate(1);
		end
		s:queuecommand("Animate");
	end;
	AnimateCommand=cmd(diffusealpha,1;zoom,0.37*1.5;linear,0.05;zoom,0.34*1.5;sleep,0.4;diffusealpha,0);
};
	
	LoadActor("Judgment") .. {
		Name="Judgment";
		InitCommand=function(s) s:y(2+PositionShift()):pause():visible(false) end;
		ResetCommand=cmd(finishtweening;stopeffect;visible,false);
	};
	InitCommand = function(s)
		c = s:GetChildren();
		-- LOW: el juicio del motor se oculta y lo dibuja la copia del underlay
		if not isCopy and POMenu and POMenu.JudgmentHigh and not POMenu.JudgmentHigh(pn) then
			s:visible(false)
		end
	end;
	JudgmentMessageCommand=function(s, p)
		if p.Player ~= pn then return end;
		if p.HoldNoteScore then return end;
		
		local iNumStates = c.Judgment:GetNumStates();
		local iFrame = TNSFrames[p.TapNoteScore];
		
		if not iFrame then return end
		
		if iNumStates == 12 then
			iFrame = iFrame * 2;
			if not p.Early then
				iFrame = iFrame + 1;
			end
		end
		
		local fTapNoteOffset = p.TapNoteOffset;
		
		if p.HoldNoteScore then
			fTapNoteOffset = 1;
		else
			fTapNoteOffset = p.TapNoteOffset; 
		end
		
		if p.TapNoteScore == 'TapNoteScore_Miss' then
			fTapNoteOffset = 1;
			bUseNegative = true;
		else
			bUseNegative = false;
		end;
		
		if fTapNoteOffset and fTapNoteOffset ~= 1 then
			tTotalJudgments[#tTotalJudgments+1] = bUseNegative and fTapNoteOffset or math.abs( fTapNoteOffset );
		end
		
		s:playcommand("Reset");

		c.Judgment:visible( not bShowProtiming );
		c.Judgment:setstate( iFrame );
		JudgeCmds[p.TapNoteScore](c.Judgment);
	end;
	
	LoadActor("TargetScore",pn);
	
};


return t;
