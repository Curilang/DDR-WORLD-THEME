local cursor = Def.ActorFrame{};

for i=1,2 do
	cursor[#cursor+1] = Def.Sprite{
		Texture="scroll",
		InitCommand=function(s) 
			s:xy(i==1 and 345 or -345,0.187):setsize(20,1.2)
		end,
	};
end

return Def.ActorFrame{
	cursor;
};

