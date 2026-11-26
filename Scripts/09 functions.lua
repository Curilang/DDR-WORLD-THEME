--[[ EXAMPLES
	["GROUP"] = {
		["SONG"] = {
			min = "MIN BPM TO SHOW",
			max = "MAX BPM TO SHOW AND TO USE FOR REALSPEED",
		},
		["SONG"] = {
			max = "",
			hideChange = true, --HIDE VARIANT BPM
		},
		["SONG"] = {
			charts = {
				Difficulty_"" = { -- SONGS WITH SPLIT BPM
					min = "",
					max = "",
				},
			},
		},
	
	},

]]


local overrides = {
	["01 - DDR 1st"] = {
		["Butterfly"] = {
			max = 135,
			hideChange = true,
		},
		["Have You Never Been Mellow"] = {
			max = 126,
			hideChange = true,
		},
		["KUNG FU FIGHTING"] = {
			max = 116,
			hideChange = true,
		},
		["LET'S GET DOWN"] = {
			max = 129,
			hideChange = true,
		},
		["Little Bitch"] = {
			min = 152,
			max = 161,
		},
		["My Fire (UKS Remix)"] = {
			max = 130,
			hideChange = true,
		},
		["PARANOiA"] = {
			min = 170,
			max = 184,
		},
		["STRICTLY BUSINESS"] = {
			max = 125,
			hideChange = true,
		},
		["That's The Way (I Like It)"] = {
			min = 108,
			max = 111,
		},
	},
	["02 - DDR 2ndMIX"] = {
		["AM-3P"] = {
			max = 130,
			hideChange = true,
		},
		["BAD GIRLS"] = {
			max = 122,
			hideChange = true,
		},
		["Boom Boom Dollar (Red Monster Mix)"] = {
			max = 135,
			hideChange = true,
		},
		["Boys"] = {
			max = 138,
			hideChange = true,
		},
		["BRILLIANT 2U(Orchestra Groove)"] = {
			max = 150,
			hideChange = true,
		},
		["DUB-I-DUB"] = {
			max = 136,
			hideChange = true,
		},
		["GET UP'N MOVE"] = {
			max = 132,
			hideChange = true,
		},
		["I Believe In Miracles (The Lisa Marie Experience Radio Edit)"] = {
			max = 126,
			hideChange = true,
		},
		["IF YOU WERE HERE"] = {
			max = 145,
			hideChange = true,
		},
		["LOVE"] = {
			max = 129,
			hideChange = true,
		},
		["MAKE A JAM!"] = {
			max = 124,
			hideChange = true,
		},
		["MAKE IT BETTER (So-REAL Mix)"] = {
			max = 118,
			hideChange = true,
		},
		["PARANOiA KCET ~clean mix~"] = {
			max = 180,
			hideChange = true,
		},
		["PARANOiA MAX~DIRTY MIX~"] = {
			max = 190,
			hideChange = true,
		},
		["PARANOiA MAX~DIRTY MIX~ (in roulette)"] = {
			max = 190,
			hideChange = true,
		},
		["PUT YOUR FAITH IN ME (Jazzy Groove)"] = {
			max = 120,
			hideChange = true,
		},
		["Smoke"] = {
			max = 135,
			hideChange = true,
		},
		["SP-TRIP MACHINE~JUNGLE MIX~"] = {
			max = 160,
			hideChange = true,
		},
		["stomp to my beat"] = {
			max = 134,
			hideChange = true,
		},
		["TUBTHUMPING"] = {
			max = 104,
			hideChange = true,
		},
	},
	["02 - DDR 2ndMIX CLUB VER.1"] = {
		["R3"] = {
			max = 157,
			hideChange = true,
		},
		["The rhyme brokers"] = {
			max = 91,
			hideChange = true,
		},
	},
	["02 - DDR 2ndMIX CLUB VER.2"] = {
		["g.m.d"] = {
			max = 100,
			hideChange = true,
		},
		["THE EARTH LIGHT"] = {
			max = 145,
			hideChange = true,
		},
	},
	["03 - DDR 3rdMIX"] = {
		["AFTER THE GAME OF LOVE"] = {
			max = 105,
			hideChange = true,
		},
		["BOOM BOOM DOLLAR (K.O.G G3 MIX)"] = {
			max = 170,
			hideChange = true,
		},
		["CUTIE CHASER"] = {
			max = 126,
			hideChange = true,
		},
		["DEAD END"] = {
			max = 190,
			hideChange = true,
		},
		["DO IT ALL NIGHT"] = {
			max = 143,
			hideChange = true,
		},
		["DROP THE BOMB"] = {
			max = 150,
			hideChange = true,
		},
		["FLASHDANCE (WHAT A FEELING)"] = {
			max = 167,
			hideChange = true,
		},
		["GET UP (BEFORE THE NIGHT IS OVER)"] = {
			max = 124,
			hideChange = true,
		},
		["GIMME GIMME GIMME"] = {
			max = 149,
			hideChange = true,
		},
		["GRADIUSIC CYBER ~AMD G5 MIX~"] = {
			max = 160,
			hideChange = true,
		},
		["HOLIDAY"] = {
			max = 128,
			hideChange = true,
		},
		["IN THE NAVY '99 (XXL Disaster Remix)"] = {
			max = 135,
			hideChange = true,
		},
		["La Senorita"] = {
			max = 182,
			hideChange = true,
		},
		["La Senorita Virtual"] = {
			max = 182,
			hideChange = true,
		},
		["LUV TO ME (AMD MIX)"] = {
			max = 154,
			hideChange = true,
		},
		["PARANOiA Rebirth"] = {
			max = 190,
			hideChange = true,
		},
		["THE RACE"] = {
			max = 143,
			hideChange = true,
		},
		["think ya better D"] = {
			max = 136,
			hideChange = true,
		},
		["TRIP MACHINE~luv mix~"] = {
			max = 160,
			hideChange = true,
		},
	},
	["04 - DDR 4thMIX"] = {
		["B4U"] = {
			max = 155,
			hideChange = true,
		},
		["BABY BABY GIMME YOUR LOVE"] = {
			max = 96,
			hideChange = true,
		},
		["BOYS (EURO MIX)"] = {
			max = 155,
			hideChange = true,
		},
		["BURNIN' THE FLOOR"] = {
			max = 155,
			hideChange = true,
		},
		["CAN'T STOP FALLIN' IN LOVE"] = {
			max = 155,
			hideChange = true,
		},
		["CELEBRATE NITE"] = {
			max = 144,
			hideChange = true,
		},
		["Don't Stop!~AMD 2nd MIX~"] = {
			max = 130,
			hideChange = true,
		},
		["DREAM A DREAM"] = {
			max = 141,
			hideChange = true,
		},
		["Holic"] = {
			max = 155,
			hideChange = true,
		},
		["HYSTERIA"] = {
			max = 190,
			hideChange = true,
		},
		["MY SUMMER LOVE"] = {
			max = 100,
			hideChange = true,
		},
		["PARANOIA EVOLUTION"] = {
			max = 200,
			hideChange = true,
		},
		["SEXY PLANET"] = {
			max = 180,
			hideChange = true,
		},
		["SHAKE YOUR BOOTY"] = {
			max = 112,
			hideChange = true,
		},
		["SUPER STAR"] = {
			max = 128,
			hideChange = true,
		},
		["SYNCHRONIZED LOVE (Red Monster Hyper Mix)"] = {
			max = 150,
			hideChange = true,
		},
		["WILD RUSH"] = {
			min = 80,
			max = 180,
		},
	},
	["04 - DDR Solo 2000"] = {
		["HIGH ENERGY (John '00' Fleming Remix)"] = {
			max = 140,
			hideChange = true,
		},
	},
	["04 - DDR Solo BASSMIX"] = {
		["THAT'S THE WAY '98"] = {
			max = 126,
			hideChange = true,
		},
	},
	["05 - DDR 5thMIX"] = {
		["Abyss"] = {
			max = 142,
			hideChange = true,
		},
		["AGAINST ALL ODDS (Definitive MIX)"] = {
			max = 139,
			hideChange = true,
		},
		["B4U glorious style"] = {
			max = 155,
			hideChange = true,
		},
		["BE TOGETHER"] = {
			max = 140,
			hideChange = true,
		},
		["BROKEN MY HEART"] = {
			max = 160,
			hideChange = true,
		},
		["CAN'T STOP FALLIN' IN LOVE ~SPEED MIX~"] = {
			max = 170,
			hideChange = true,
		},
		["DANCING ALL ALONE"] = {
			max = 140,
			hideChange = true,
		},
		["DIVE"] = {
			max = 155,
			hideChange = true,
		},
		["DXY!"] = {
			max = 148,
			hideChange = true,
		},
		["DYNAMITE RAVE(Long ver.)"] = {
			max = 150,
			hideChange = true,
		},
		["Electro Tuned ( the SubS Mix )"] = {
			max = 125,
			hideChange = true,
		},
		["HOT LIMIT"] = {
			max = 156,
			hideChange = true,
		},
		["I Was The One"] = {
			max = 125,
			hideChange = true,
		},
		["MOONLIGHT SHADOW (New Vocal Version)"] = {
			max = 140,
			hideChange = true,
		},
		["MOVIN ON (Extended Moon Mix)"] = {
			max = 142,
			hideChange = true,
		},
		["Mr.T. (take me higher)"] = {
			max = 128,
			hideChange = true,
		},
		["MY GENERATION (Fat Beat Mix)"] = {
			max = 140,
			hideChange = true,
		},
		["NEVER ENDING STORY (Power Club Vocal Mix)"] = {
			max = 140,
			hideChange = true,
		},
		["NO LIMIT(RM Remix)"] = {
			max = 141,
			hideChange = true,
		},
		["OOPS!...I DID IT AGAIN (Fired Up MIX)"] = {
			max = 132,
			hideChange = true,
		},
		["Radical Faith"] = {
			max = 114,
			hideChange = true,
		},
		["RIGHT NOW"] = {
			max = 130,
			hideChange = true,
		},
		["STILL IN MY HEART"] = {
			max = 150,
			hideChange = true,
		},
		["TEST MY BEST"] = {
			max = 147,
			hideChange = true,
		},
		["THE CUBE"] = {
			max = 178,
			hideChange = true,
		},
		["TRIBAL DANCE (ALMIGHTY MIX)"] = {
			max = 136,
			hideChange = true,
		},
		
		["17SAI"] = {
			max = 142,
			hideChange = true,
		},
		["ODORU PONPOKOLIN"] = {
			max = 142,
			hideChange = true,
		},
		["MATSURI JAPAN"] = {
			max = 180,
			hideChange = true,
		},
		["ROMANCE NO KAMISAMA"] = {
			max = 157,
			hideChange = true,
		},
	},
	["06 - DDR MAX"] = {
		["BYE BYE BABY BALLOON"] = {
			max = 145,
			hideChange = true,
		},
		["COW GIRL"] = {
			max = 138,
			hideChange = true,
		},
		["Dark Black Forest (short trip)"] = {
			max = 140,
			hideChange = true,
		},
		["DIVE(more deep & deeper style)"] = {
			max = 155,
			hideChange = true,
		},
		["Do It Right"] = {
			max = 135,
			hideChange = true,
		},
		["DO YOU REMEMBER ME"] = {
			max = 150,
			hideChange = true,
		},
		["FANTASY"] = {
			max = 160,
			hideChange = true,
		},
		["Firefly"] = {
			max = 150,
			hideChange = true,
		},
		["FOLLOW ME"] = {
			max = 158,
			hideChange = true,
		},
		["Groove"] = {
			max = 130,
			hideChange = true,
		},
		["HIGHS OFF U (Scorccio XY Mix)"] = {
			max = 130,
			hideChange = true,
		},
		["I'M IN THE MOOD FOR DANCING"] = {
			max = 150,
			hideChange = true,
		},
		["JUSTIFY MY LOVE"] = {
			max = 140,
			hideChange = true,
		},
		["Let the beat hit em!(CLASSIC R&B STYLE)"] = {
			max = 102,
			hideChange = true,
		},
		["Look To The Sky"] = {
			max = 140,
			hideChange = true,
		},
		["MAX 300"] = {
			max = 300,
			hideChange = true,
		},
		["Midnite Blaze"] = {
			max = 150,
			hideChange = true,
		},
		["MIRACLE"] = {
			max = 128,
			hideChange = true,
		},
		["MY SWEET DARLIN'"] = {
			max = 157,
			hideChange = true,
		},
		["NORI NORI NORI"] = {
			max = 160,
			hideChange = true,
		},
		["ON THE JAZZ"] = {
			max = 130,
			hideChange = true,
		},
		["ORION.78~civilization mix~"] = {
			max = 200,
			hideChange = true,
		},
		["Share My Love"] = {
			max = 125,
			hideChange = true,
		},
		["SO DEEP (PERFECT SPHERE REMIX)"] = {
			max = 140,
			hideChange = true,
		},
		["The Centre Of The Heart (STONEBRIDGE CLUBMIX)"] = {
			max = 128,
			hideChange = true,
		},
		["true...(radio edit)"] = {
			max = 125,
			hideChange = true,
		},
		["true...(Trance Sunrise Mix)"] = {
			max = 140,
			hideChange = true,
		},
		["TWILIGHT ZONE (R-C Extended Club MIX)"] = {
			max = 138,
			hideChange = true,
		},
	},
	["07 - DDR MAX2"] = {
		["AM-3P (AM EAST mix)"] = {
			max = 140,
			hideChange = true,
		},
		["B4U(B4 ZA BEAT MIX)"] = {
			max = 170,
			hideChange = true,
		},
		["BABY LOVE ME"] = {
			max = 160,
			hideChange = true,
		},
		["BREAK DOWN!"] = {
			max = 190,
			hideChange = true,
		},
		["BRILLIANT 2U(K.O.G G3 MIX)"] = {
			max = 170,
			hideChange = true,
		},
		["BURNIN' THE FLOOR (BLUE FIRE mix)"] = {
			max = 155,
			hideChange = true,
		},
		["Busy Child"] = {
			max = 125,
			hideChange = true,
		},
		["CANDY HEART"] = {
			max = 180,
			hideChange = true,
		},
		["D2R"] = {
			max = 160,
			hideChange = true,
		},
		["Days Go By"] = {
			max = 127,
			hideChange = true,
		},
		["DESTINY"] = {
			max = 155,
			hideChange = true,
		},
		["DRIFTING AWAY"] = {
			max = 136,
			hideChange = true,
		},
		["DROP OUT(FROM NONSTOP MEGAMIX)"] = {
			max = 130,
			hideChange = true,
		},
		["ever snow"] = {
			max = 145,
			hideChange = true,
		},
		["FANTASY"] = {
			max = 140,
			hideChange = true,
		},
		["Heaven"] = {
			max = 138,
			hideChange = true,
		},
		["HIGHER (next morning mix)"] = {
			max = 132,
			hideChange = true,
		},
		["i feel"] = {
			max = 141,
			hideChange = true,
		},
		["IT'S RAINING MEN (Almighty Mix)"] = {
			max = 136,
			hideChange = true,
		},
		["LITTLE BOY (BOY ON BOY MIX)"] = {
			max = 150,
			hideChange = true,
		},
		["LIVING IN AMERICA"] = {
			max = 169,
			hideChange = true,
		},
		["LONG TRAIN RUNNIN'"] = {
			max = 126,
			hideChange = true,
		},
		["LOOK AT US (Daddy DJ Remix)"] = {
			max = 135,
			hideChange = true,
		},
		["Love At First Sight"] = {
			max = 125,
			hideChange = true,
		},
		["MAXIMUM OVERDRIVE (KC Club Mix)"] = {
			max = 140,
			hideChange = true,
		},
		["MAXX UNLIMITED"] = {
			min = 140,
			max = 320,
		},
		["more deep (ver.2.1)"] = {
			max = 133,
			hideChange = true,
		},
		["MY SUMMER LOVE(TOMMY'S SMILE MIX)"] = {
			max = 100,
			hideChange = true,
		},
		["NOTHING GONNA STOP (Dance Mania Mix)"] = {
			max = 145,
			hideChange = true,
		},
		["rain of sorrow"] = {
			max = 140,
			hideChange = true,
		},
		["Secret Rendez-vous"] = {
			max = 98,
			hideChange = true,
		},
		["SO FABULOUS SO FIERCE (FREAK OUT)"] = {
			max = 128,
			hideChange = true,
		},
		["Spin the disc"] = {
			max = 130,
			hideChange = true,
		},
		["STAY"] = {
			max = 140,
			hideChange = true,
		},
		["STILL IN MY HEART (MOMO MIX)"] = {
			min = 85,
			max = 170,
		},
		["SUPER STAR(FROM NONSTOP MEGAMIX)"] = {
			max = 128,
			hideChange = true,
		},
		["Take Me Away (into the night)(radio vocal)"] = {
			max = 138,
			hideChange = true,
		},
		["THE WHISTLE SONG (Blow My Whistle Baby)"] = {
			max = 140,
			hideChange = true,
		},
		["TRANCE DE JANEIRO (SAMBA DE JANEIRO 2002 Epic Vocal Remix)"] = {
			max = 145,
			hideChange = true,
		},
		["WAKA LAKA"] = {
			max = 170,
			hideChange = true,
		},
		
		["MATSURI JAPAN (FROM NONSTOP MEGAMIX)"] = {
			max = 180,
			hideChange = true,
		},
	},
	["08 - DDR EXTREME"] = {
		["air"] = {
			max = 130,
			hideChange = true,
		},
		["AM-3P -303 BASS MIX-"] = {
			max = 130,
			hideChange = true,
		},
		["bag"] = {
			max = 65,
			hideChange = true,
		},
		["BE LOVIN"] = {
			max = 185,
			hideChange = true,
		},
		["Colors ~for EXTREME~"] = {
			max = 150,
			hideChange = true,
		},
		["CRASH!"] = {
			max = 200,
			hideChange = true,
		},
		["CUTIE CHASER(MORNING MIX)"] = {
			max = 126,
			hideChange = true,
		},
		["feeling of love"] = {
			max = 136,
			hideChange = true,
		},
		["Frozen Ray ~for EXTREME~"] = {
			max = 156,
			hideChange = true,
		},
		["Happy Wedding"] = {
			max = 126,
			hideChange = true,
		},
		["HYPER EUROBEAT"] = {
			max = 152,
			hideChange = true,
		},
		["I'm gonna get you!"] = {
			max = 160,
			hideChange = true,
		},
		["JET WORLD"] = {
			max = 138,
			hideChange = true,
		},
		["KISS KISS KISS"] = {
			max = 150,
			hideChange = true,
		},
		["Kiss me all night long"] = {
			max = 155,
			hideChange = true,
		},
		["LA BAMBA"] = {
			max = 179,
			hideChange = true,
		},
		["L'amour et la liberte(DDR Ver.)"] = {
			max = 145,
			hideChange = true,
		},
		["LOVE LOVE SHINE"] = {
			max = 177,
			hideChange = true,
		},
		["LOVE LOVE SUGAR"] = {
			max = 155,
			hideChange = true,
		},
		["MEMORIES"] = {
			max = 145,
			hideChange = true,
		},
		["Miracle Moon ~L.E.D.LIGHT STYLE MIX~"] = {
			max = 138,
			hideChange = true,
		},
		["Pink Rose"] = {
			max = 146,
			hideChange = true,
		},
		["SO IN LOVE"] = {
			max = 112,
			hideChange = true,
		},
		["sync (EXTREME version)"] = {
			max = 167,
			hideChange = true,
		},
		["TEARS"] = {
			max = 143,
			hideChange = true,
		},
		["The legend of MAX"] = {
			min = 83,
			max = 333,
		},
		["VANITY ANGEL"] = {
			max = 140,
			hideChange = true,
		},
		
		["321STARS"] = {
			max = 192,
			hideChange = true,
		},
		["MAGIC DOOR(Theme of SPACE MACO)"] = {
			max = 184,
			hideChange = true,
		},
	},
	["09 - DDR SuperNOVA"] = {
		["A LOVE LIKE THIS"] = {
			max = 127,
			hideChange = true,
		},
		["A Stupid Barber"] = {
			max = 132,
			hideChange = true,
		},
		["Baby's Tears"] = {
			max = 180,
			hideChange = true,
		},
		["Bad Routine"] = {
			max = 130,
			hideChange = true,
		},
		["Baile Le Samba"] = {
			max = 92,
			hideChange = true,
		},
		["BALALAIKA,CARRIED WITH THE WIND"] = {
			max = 134,
			hideChange = true,
		},
		["BALLAD FOR YOU"] = {
			max = 65,
			hideChange = true,
		},
		["Brazilian Anthem"] = {
			max = 130,
			hideChange = true,
		},
		["Brilliant R.E.D"] = {
			max = 150,
			hideChange = true,
		},
		["Can Be Real"] = {
			max = 132,
			hideChange = true,
		},
		["DA CAPO"] = {
			max = 138,
			hideChange = true,
		},
		["DoLL"] = {
			max = 170,
			hideChange = true,
		},
		["Dragon Blade"] = {
			max = 240,
			hideChange = true,
		},
		["Drivin'"] = {
			max = 155,
			hideChange = true,
		},
		["Fly away"] = {
			max = 125,
			hideChange = true,
		},
		["Forever Sunshine"] = {
			max = 128,
			hideChange = true,
		},
		["Freedom"] = {
			max = 148,
			hideChange = true,
		},
		["Funk Boogie"] = {
			max = 127,
			hideChange = true,
		},
		["Funkytown"] = {
			max = 122,
			hideChange = true,
		},
		["GORGEOUS 2012"] = {
			max = 135,
			hideChange = true,
		},
		["HAPPY ANGEL"] = {
			max = 180,
			hideChange = true,
		},
		["Healing-D-Vision"] = {
			min = 180,
			max = 360,
		},
		["HONEY PUNCH"] = {
			max = 175,
			hideChange = true,
		},
		["Hunting for you"] = {
			max = 105,
			hideChange = true,
		},
		["iFUTURELIST(DDR VERSION)"] = {
			max = 150,
			hideChange = true,
		},
		["I Need You"] = {
			max = 114,
			hideChange = true,
		},
		["I'll Make Love To You"] = {
			max = 50,
			hideChange = true,
		},
		["I'M FOR REAL"] = {
			max = 140,
			hideChange = true,
		},
		["INSIDE YOUR HEART"] = {
			max = 107,
			hideChange = true,
		},
		["Jam & Marmalade"] = {
			max = 145,
			hideChange = true,
		},
		["JERK IT OUT"] = {
			max = 134,
			hideChange = true,
		},
		["Keep On Liftin'"] = {
			max = 100,
			hideChange = true,
		},
		["KEEP ON MOVIN' ~DMX MIX~"] = {
			max = 132,
			hideChange = true,
		},
		["LOGICAL DASH"] = {
			max = 144,
			hideChange = true,
		},
		["MARIA(I believe...)"] = {
			max = 158,
			hideChange = true,
		},
		["Mind Parasite"] = {
			max = 145,
			hideChange = true,
		},
		["MONDO STREET"] = {
			min = 180,
			max = 183,
		},
		["Monkey Punk"] = {
			max = 180,
			hideChange = true,
		},
		["Morning Glory"] = {
			max = 160,
			hideChange = true,
		},
		["murmur twins"] = {
			max = 174,
			hideChange = true,
		},
		["PARANOiA-Respect-"] = {
			max = 300,
			hideChange = true,
		},
		["PEACE(^^)v"] = {
			max = 142,
			hideChange = true,
		},
		["peace-out"] = {
			max = 133,
			hideChange = true,
		},
		["PUT YOUR FAITH IN ME ~SATURDAY NIGHT MIX~"] = {
			max = 120,
			hideChange = true,
		},
		["Quickening"] = {
			max = 150,
			hideChange = true,
		},
		["rainbow flyer"] = {
			max = 148,
			hideChange = true,
		},
		["Saturday Night Love"] = {
			max = 128,
			hideChange = true,
		},
		["Scorching Moon"] = {
			max = 125,
			hideChange = true,
		},
		["Ska Ska No.3"] = {
			max = 138,
			hideChange = true,
		},
		["SURRENDER(YOUR LOVE)"] = {
			max = 103,
			hideChange = true,
		},
		["TOMORROW"] = {
			max = 140,
			hideChange = true,
		},
		["Tomorrow Perfume"] = {
			max = 144,
			hideChange = true,
		},
		["TOXIC (FT company Edit)"] = {
			max = 143,
			hideChange = true,
		},
		["Try 2 Luv. U"] = {
			max = 115,
			hideChange = true,
		},
		["Under the Sky"] = {
			max = 170,
			hideChange = true,
		},
		["You gotta move it (feat. Julie Rugaard)"] = {
			max = 134,
			hideChange = true,
		},
		["Your Rain(RAGE MIX)"] = {
			max = 134,
			hideChange = true,
		},
		
		["Kagerou"] = {
			max = 164,
			hideChange = true,
		},
		["Gekkou chou"] = {
			max = 218,
			hideChange = true,
		},
		["CHIKARA"] = {
			max = 185,
			hideChange = true,
		},
		["NIJIIRO"] = {
			max = 185,
			hideChange = true,
		},
		["Hana Ranman -Flowers-"] = {
			max = 160,
			hideChange = true,
		},
		["Himawari"] = {
			max = 185,
			hideChange = true,
		},
		["MATSURI (J-SUMMER MIX)"] = {
			max = 180,
			hideChange = true,
		},
		["Mugen"] = {
			max = 171,
			hideChange = true,
		},
	},
	["10 - DDR SuperNOVA2"] = {
		["AM-3P (CHAOS Special)"] = {
			max = 130,
			hideChange = true,
		},
		["B4U (VOLTAGE Special)"] = {
			max = 155,
			hideChange = true,
		},
		["Bloody Tears(IIDX EDITION)"] = {
			max = 170,
			hideChange = true,
		},
		["Burn Baby Burn"] = {
			max = 156,
			hideChange = true,
		},
		["COME CLEAN"] = {
			max = 108,
			hideChange = true,
		},
		["dream of love"] = {
			max = 114,
			hideChange = true,
		},
		["Electrified"] = {
			max = 140,
			hideChange = true,
		},
		["Every Little Step"] = {
			max = 98,
			hideChange = true,
		},
		["FAINT"] = {
			max = 135,
			hideChange = true,
		},
		["FIRE"] = {
			max = 184,
			hideChange = true,
		},
		["Fly away -mix del matador-"] = {
			max = 130,
			hideChange = true,
		},
		["Freeway Shuffle"] = {
			max = 130,
			hideChange = true,
		},
		["GIRIGILI Burning 24H!"] = {
			max = 148,
			hideChange = true,
		},
		["Got To Be Real"] = {
			max = 115,
			hideChange = true,
		},
		["LE FREAK"] = {
			max = 118,
			hideChange = true,
		},
		["Love On My Mind (Radio Mix)"] = {
			max = 129,
			hideChange = true,
		},
		["ME AGAINST THE MUSIC"] = {
			max = 130,
			hideChange = true,
		},
		["MOONSTER"] = {
			max = 140,
			hideChange = true,
		},
		["My Favorite Things"] = {
			max = 130,
			hideChange = true,
		},
		["Pluto Relinquish"] = {
			min = 100,
			max = 400,
		},
		["Say Goodbye"] = {
			max = 115,
			hideChange = true,
		},
		["Shades of Grey"] = {
			max = 170,
			hideChange = true,
		},
		["SOUL CRASH"] = {
			max = 142,
			hideChange = true,
		},
		["Star Gate Heaven (FUTURE LOVE Mix)"] = {
			max = 147,
			hideChange = true,
		},
		["STARS (Re-tuned by HAL) - DDR EDITION -"] = {
			max = 145,
			hideChange = true,
		},
		["stealth"] = {
			max = 160,
			hideChange = true,
		},
		["Suddenly I See"] = {
			max = 100,
			hideChange = true,
		},
		["SUNKiSS DROP~Alison Side~"] = {
			max = 185,
			hideChange = true,
		},
		["SUNKiSS DROP~jun Side~"] = {
			max = 185,
			hideChange = true,
		},
		["SUNRISE(JASON NEVINS REMIX)"] = {
			max = 130,
			hideChange = true,
		},
		["switch"] = {
			max = 152,
			hideChange = true,
		},
		["The Rockafeller Skank"] = {
			max = 153,
			hideChange = true,
		},
		["Trust -DanceDanceRevolution mix-"] = {
			max = 164,
			hideChange = true,
		},
		["Two Months Off"] = {
			max = 140,
			hideChange = true,
		},
		["Unbelievable"] = {
			max = 104,
			hideChange = true,
		},
		["Unwritten (Vicious Club Mix)"] = {
			max = 130,
			hideChange = true,
		},
		["Vem brincar"] = {
			max = 135,
			hideChange = true,
		},
		["Venus"] = {
			max = 195,
			hideChange = true,
		},
		["volcano"] = {
			max = 240,
			hideChange = true,
		},
		["Votum stellarum -forest #25 DDR RMX-"] = {
			max = 140,
			hideChange = true,
		},
		["WAITING FOR TONIGHT"] = {
			max = 125,
			hideChange = true,
		},
		["Why not"] = {
			max = 175,
			hideChange = true,
		},
	},
	["11 - DDR X"] = {
		["AFRONOVA(X-Special)"] = {
			max = 200,
			hideChange = true,
		},
		["A Geisha's Dream"] = {
			max = 140,
			hideChange = true,
		},
		["Always on My Mind"] = {
			max = 125,
			hideChange = true,
		},
		["Beautiful Inside (Cube Hard Mix)"] = {
			max = 110,
			hideChange = true,
		},
		["Boys (2008 X-edit)"] = {
			max = 138,
			hideChange = true,
		},
		["Butterfly (2008 X-edit)"] = {
			max = 135,
			hideChange = true,
		},
		["Dance Celebration (System 7 Remix)"] = {
			max = 132,
			hideChange = true,
		},
		["Dance Floor"] = {
			max = 120,
			hideChange = true,
		},
		["DUB-I-DUB (2008 X-edit)"] = {
			max = 136,
			hideChange = true,
		},
		["Flourish"] = {
			max = 152,
			hideChange = true,
		},
		["GET UP'N MOVE (2008 X-edit)"] = {
			max = 132,
			hideChange = true,
		},
		["Happy"] = {
			max = 138,
			hideChange = true,
		},
		["Here It Goes Again"] = {
			max = 145,
			hideChange = true,
		},
		["Horatio"] = {
			max = 165,
			hideChange = true,
		},
		["Lift You Up"] = {
			max = 123,
			hideChange = true,
		},
		["LOVING YOU (Epidemik remix)"] = {
			max = 165,
			hideChange = true,
		},
		["Malacca"] = {
			max = 140,
			hideChange = true,
		},
		["MAX 300(X-Special)"] = {
			max = 300,
			hideChange = true,
		},
		["MAXX UNLIMITED(X-Special)"] = {
			min = 140,
			max = 320,
		},
		["on the bounce"] = {
			max = 150,
			hideChange = true,
		},
		["PARANOiA(X-Special)"] = {
			min = 170,
			max = 184,
		},
		["PARANOiA ETERNAL(X-Special)"] = {
			max = 200,
			hideChange = true,
		},
		["PARANOIA EVOLUTION(X-Special)"] = {
			max = 200,
			hideChange = true,
		},
		["PARANOiA MAX~DIRTY MIX~(SMM-Special)"] = {
			min = 95,
			max = 380,
		},
		["PARANOiA MAX~DIRTY MIX~(X-Special)"] = {
			max = 190,
			hideChange = true,
		},
		["PARANOiA MAX~DIRTY MIX~in roulette(X-Special)"] = {
			max = 190,
			hideChange = true,
		},
		["PARANOiA Rebirth(X-Special)"] = {
			max = 190,
			hideChange = true,
		},
		["SABER WING"] = {
			min = 74,
			max = 222,
		},
		["SAGA"] = {
			min = 200,
			max = 243,
		},
		["Sound Of Freedom"] = {
			max = 129,
			hideChange = true,
		},
		["SP-TRIP MACHINE~JUNGLE MIX~(SMM-Special)"] = {
			max = 160,
			hideChange = true,
		},
		["SP-TRIP MACHINE~JUNGLE MIX~(X-Special)"] = {
			max = 160,
			hideChange = true,
		},
		["SUPER SAMURAI"] = {
			max = 170,
			hideChange = true,
		},
		["Take A Chance"] = {
			max = 88,
			hideChange = true,
		},
		["The legend of MAX(X-Special)"] = {
			min = 83,
			max = 333,
		},		
		["Ticket to Bombay"] = {
			max = 145,
			hideChange = true,
		},		
		["Till the lonely's gone"] = {
			max = 130,
			hideChange = true,
		},		
		["TRIP MACHINE(X-Special)"] = {
			max = 160,
			hideChange = true,
		},		
		["TRIP MACHINE CLIMAX(X-Special)"] = {
			max = 180,
			hideChange = true,
		},		
		["U Can't Touch This"] = {
			max = 134,
			hideChange = true,
		},	
		["Ubertreffen"] = {
			max = 174,
			hideChange = true,
		},	
		["We've Got To Make It Tonight"] = {
			max = 127,
			hideChange = true,
		},	
		["Wine Red (Tommie Sunshine's Brooklyn Fire Retouch)"] = {
			max = 130,
			hideChange = true,
		},
		
		["PORIRIZUMU"] = {
			max = 128,
			hideChange = true,
		},
		["Suki Melo"] = {
			max = 180,
			hideChange = true,
		},
		["SEKAI HA ODORU"] = {
			max = 110,
			hideChange = true,
		},
		["Rin To Shite Saku Hana No Gotoku"] = {
			max = 163,
			hideChange = true,
		},
		["Tabibito"] = {
			max = 109,
			hideChange = true,
		},
		["KAKUMEI(X-Special)"] = {
			min = 83,
			max = 148,
		},
	},
	["12 - DDR X2"] = {
		["A Brighter Day"] = {
			max = 155,
			hideChange = true,
		},
		["aftershock!!"] = {
			max = 157,
		},
		["All My Love"] = {
			max = 158,
			hideChange = true,
		},
		["Bonafied Lovin'"] = {
			max = 125,
			hideChange = true,
		},
		["DAM DARIRAM"] = {
			max = 142,
			hideChange = true,
		},
		["Dazzlin' Darlin"] = {
			max = 149,
			hideChange = true,
		},
		["DROP"] = {
			max = 152,
			hideChange = true,
		},
		["Feel Good Inc"] = {
			max = 139,
			hideChange = true,
		},
		["Freeze"] = {
			max = 140,
			hideChange = true,
		},
		["going up"] = {
			max = 212,
			hideChange = true,
		},
		["GOLD RUSH"] = {
			max = 162,
			hideChange = true,
		},
		["GOLD RUSH (AC)"] = {
			max = 162,
			hideChange = true,
		},
		["GOLD RUSH (CS)"] = {
			max = 162,
			hideChange = true,
		},
		["Heatstroke"] = {
			max = 140,
			hideChange = true,
		},
		["HERO"] = {
			max = 138,
			hideChange = true,
		},
		["ICE ICE BABY"] = {
			max = 116,
			hideChange = true,
		},
		["IF YOU WERE HERE"] = {
			max = 146,
			hideChange = true,
		},
		["La libertad"] = {
			max = 170,
			hideChange = true,
		},
		["La receta"] = {
			max = 130,
			hideChange = true,
		},
		["Melody Life"] = {
			max = 172,
			hideChange = true,
		},
		["Melody Life (Chinese)"] = {
			max = 172,
			hideChange = true,
		},
		["real-high-SPEED"] = {
			max = 131,
			hideChange = true,
		},
		["roppongi EVOLVED ver. A"] = {
			max = 170,
			hideChange = true,
		},
		["roppongi EVOLVED ver. C"] = {
			min = 85,
			max = 170,
		},
		["roppongi EVOLVED ver. D"] = {
			min = 85,
			max = 340,
		},
		["sakura storm"] = {
			max = 184,
			hideChange = true,
		},
		["Second Heaven"] = {
			max = 149,
			hideChange = true,
		},
		["Shine"] = {
			max = 125,
			hideChange = true,
		},
		["someday"] = {
			max = 154,
			hideChange = true,
		},
		["Super Driver"] = {
			max = 200,
			hideChange = true,
		},
		["Taking It To The Sky"] = {
			max = 130,
			hideChange = true,
		},
		["TENSHI"] = {
			max = 138,
			hideChange = true,
		},
		["THIS NIGHT"] = {
			max = 160,
			hideChange = true,
		},
		["Valkyrie dimension"] = {
			min = 47,
			max = 480,
		},
		["VANESSA"] = {
			max = 185,
			hideChange = true,
		},
		["What Will Come of Me"] = {
			max = 140,
			hideChange = true,
		},
		["Your Angel"] = {
			max = 175,
			hideChange = true,
		},
	},
	["13 - DDR X3 VS 2ndMIX"] = {
		["Amalgamation"] = {
			max = 166,
			hideChange = true,
		},
		["Chronos"] = {
			max = 128,
			hideChange = true,
		},
		["Cosmic Hurricane"] = {
			max = 188,
			hideChange = true,
		},
		["ever snow"] = {
			max = 145,
			hideChange = true,
		},
		["Find You Again"] = {
			max = 150,
			hideChange = true,
		},
		["Go For The Top"] = {
			min = 74,
			max = 180,
		},
		["Haunted Rhapsody"] = {
			max = 155,
			hideChange = true,
		},
		["HEARTBREAK (Sound Selektaz remix)"] = {
			max = 148,
			hideChange = true,
		},
		["In The Air"] = {
			max = 140,
			hideChange = true,
		},
		["LOVE & JOY"] = {
			max = 173,
			hideChange = true,
		},
		["Mermaid girl"] = {
			max = 140,
			hideChange = true,
		},
		["REVOLUTIONARY ADDICT"] = {
			max = 174,
		},
		["Tohoku EVOLVED (TYPE1)"] = {
			min = 42,
			max = 680,
		},
		["Tohoku EVOLVED (TYPE2)"] = {
			min = 42,
			max = 680,
		},
		["Tohoku EVOLVED (TYPE3)"] = {
			min = 42,
			max = 680,
		},
		["Tohoku EVOLVED (TYPE4)"] = {
			min = 42,
			max = 680,
		},
		["tokyoEVOLVED (TYPE1)"] = {
			min = 70,
			max = 280,
		},
		["tokyoEVOLVED (TYPE2)"] = {
			min = 70,
			max = 280,
		},
		["tokyoEVOLVED (TYPE3)"] = {
			min = 70,
			max = 280,
		},
		["TRIP MACHINE EVOLUTION"] = {
			min = 95,
			max = 190,
		},
		["TWINKLE HEART"] = {
			max = 185,
			hideChange = true,
		},
		
		["Shizuku"] = {
			max = 210,
			hideChange = true,
		},
		["Tenjou no Hoshi -Reimeiki-"] = {
			min = 85,
			max = 170,
		},
		["Memeshikute"] = {
			max = 143,
			hideChange = true,
		},
	},
	["14 - DDR 2013"] = {
		["Confession"] = {
			max = 150,
			hideChange = true,
		},
		["Diamond Night"] = {
			max = 135,
			hideChange = true,
		},
		["escape"] = {
			max = 140,
			hideChange = true,
		},
		["Summer Fairytale"] = {
			max = 141,
			hideChange = true,
		},
		["The Island Song"] = {
			max = 85,
			hideChange = true,
		},
		["You"] = {
			max = 72,
			hideChange = true,
		},
		["U-u-uma uma (Speedcake Remix)"] = {
			max = 165,
			hideChange = true,
		},
		["Meumeupettantan!!"] = {
			max = 185,
			hideChange = true,
		},
	},
	["15 - DDR 2014"] = {
		["EGOISM 440"] = {
			min = 55,
			max = 440,
		},
		["JOMANDA"] = {
			min = 90,
			max = 300,
		},
		["PRANA+REVOLUTIONARY ADDICT (U1 DJ Mix)"] = {
			max = 190,
			hideChange = true,
		},
		["Starlight Fantasia (Endorphins Mix)"] = {
			min = 78,
			max = 155,
		},
		["Dopamine"] = {
			min = 100,
			max = 200,
		},
	},
	["16 - DDR A"] = {
		["ACE FOR ACES"] = {
			charts = {
				Difficulty_Medium = {
					min = 100,
					max = 200,
				},
				Difficulty_Hard = {
					min = 50,
					max = 400,
				},
				Difficulty_Challenge = {
					min = 50,
					max = 400,
				},
			},
		},
		["Bad Apple!! feat. nomico"] = {
			max = 138,
			hideChange = true,
		},
		["Catch Our Fire!"] = {
			max = 190,
			hideChange = true,
		},
		["CHOCOLATE PHILOSOPHY"] = {
			max = 110,
			hideChange = true,
		},
		["DDR MEGAMIX"] = {
			min = 65,
			max = 333,
		},
		["Emera"] = {
			max = 161,
			hideChange = true,
		},
		["First Time"] = {
			min = 70,
			max = 140,
		},
		["Grip & Break down !!"] = {
			max = 160,
			hideChange = true,
		},
		["Hillbilly Shoes"] = {
			max = 116,
			hideChange = true,
		},
		["IN BETWEEN"] = {
			max = 160,
			hideChange = true,
		},
		["I Want You To Know"] = {
			max = 130,
			hideChange = true,
		},
		["MAX 360"] = {
			min = 180,
			max = 360,
		},
		["SHION"] = {
			max = 179,
			hideChange = true,
		},
		["Strawberry Chu Chu"] = {
			max = 137,
			hideChange = true,
		},
		["The Night Away (MK Remix)"] = {
			max = 160,
			hideChange = true,
		},
		["Towards the TOWER"] = {
			max = 132,
			hideChange = true,
		},
		["Twin memories W"] = {
			max = 160,
			hideChange = true,
		},
		["Wake Me Up"] = {
			max = 124,
			hideChange = true,
		},
		["Arifureta sekai seifuku"] = {
			max = 150,
			hideChange = true,
		},
		["Yi-er fanclub"] = {
			max = 145,
			hideChange = true,
		},
		["Kuranogawa ondo"] = {
			max = 113,
			hideChange = true,
		},
		["Kurokami midareshi shura to narite ~Rin edition~"] = {
			max = 150,
			hideChange = true,
		},
		["Kunshi ayauku mo chikou yore"] = {
			max = 162,
			hideChange = true,
		},
		["Koisuru uchuu sensou!!"] = {
			max = 200,
			hideChange = true,
		},
		["Kono aozora no shita de"] = {
			max = 165,
			hideChange = true,
		},
		["Shakariki relation"] = {
			max = 167,
			hideChange = true,
		},
		["Tatakae! Dadandarn V"] = {
			max = 176,
			hideChange = true,
		},
		["Cirno no perfect sansuu kyoushitsu"] = {
			max = 175,
			hideChange = true,
		},
		["Cirno no perfect sansuu kyoushitsu (EDM REMIX)"] = {
			max = 130,
			hideChange = true,
		},
		["Nou shou sakuretsu girl"] = {
			max = 155,
			hideChange = true,
		},
		["Haru ichiban"] = {
			max = 180,
			hideChange = true,
		},
		["Houkago stride"] = {
			max = 225,
			hideChange = true,
		},
		["Mahou no tamago ~Cocona ELECTRO POP edition~"] = {
			max = 142,
			hideChange = true,
		},
		["Renaikansoku"] = {
			max = 188,
			hideChange = true,
		},
		["Ronron e rairairai!"] = {
			max = 156,
			hideChange = true,
		},
	},
	["17 - DDR A20"] = {
		["Firestorm"] = {
			max = 177,
			hideChange = true,
		},
		["OVERSOUL"] = {
			max = 155,
			hideChange = true,
		},
		["Saishou sanbai kanzensuu"] = {
			min = 55,
			max = 440,
		},
		["Tiger rampage"] = {
			max = 150,
			hideChange = true,
		},
		["Night of Knights (Ryu Remix)"] = {
			max = 182,
			hideChange = true,
		},
		["Mirai (da) FUTURE"] = {
			max = 172,
			hideChange = true,
		},
	},
	["18 - DDR A20 PLUS"] = {
		["ANTI ANTHEM"] = {
			min = 128,
			max = 175,
		},		
		["Evans"] = {
			max = 185,
		},
		["Hella Deep"] = {
			min = 132,
			max = 150,
		},
		["Sweet Clock"] = {
			max = 178,
			hideChange = true,
		},
		["TYPHON"] = {
			min = 113,
			max = 225,
		},
		["Koi"] = {
			max = 158,
			hideChange = true,
		},
		["Shisouhan"] = {
			max = 200,
			hideChange = true,
		},
		["Sekai no hate ni yakusoku no gaika wo -DDR Extended Megamix-"] = {
			min = 100,
			max = 200,
		},
		["Tokyo shinwa"] = {
			min = 98,
			max = 196,
		},
	},
	["19 - DDR GRAND PRIX"] = {
		["BRIGHT STREAM"] = {
			max = 158,
			hideChange = true,
		},
		["Dear Deer"] = {
			charts = {
				Difficulty_Medium = {
					min = 92,
					max = 185,
				},
				Difficulty_Hard = {
					min = 92,
					max = 185,
				},
				Difficulty_Challenge = {
					min = 92,
					max = 185,
				},
			},
		},
		["HOT LIMIT"] = {
			max = 140,
			hideChange = true,
		},
		["Paradission"] = {
			max = 154,
			hideChange = true,
		},
		["Odoru Pompokolin"] = {
			max = 139,
			hideChange = true,
		},
		["Orion wo nazoru"] = {
			max = 182,
			hideChange = true,
		},
		["Sakuranbo"] = {
			max = 170,
			hideChange = true,
		},
		["JoJo ~Sono Chi no Sadame~"] = {
			max = 146,
			hideChange = true,
		},
		["Tsukematsukeru"] = {
			max = 145,
			hideChange = true,
		},
		["Dry flower"] = {
			max = 148,
			hideChange = true,
		},
		["Natsumatsuri"] = {
			max = 142,
			hideChange = true,
		},
		["PORIRIZUMU"] = {
			max = 128,
			hideChange = true,
		},
		["Maji LOVE 1000%"] = {
			max = 129,
			hideChange = true,
		},
	},
	["20 - DDR A3"] = {
		["Acid,Tribal & Dance (DDR EDITION)"] = {
			min = 71,
			max = 286,
		},
		["BREAKING THE FUTURE"] = {
			min = 45,
			max = 360,
		},
		["Dance Phenomena"] = {
			min = 71,
			max = 142,
		},
		["Finale"] = {
			min = 48,
			max = 190,
		},
		["Let's DANCE aROUND!!"] = {
			charts = {
				Difficulty_Beginner = {
					min = 63,
					max = 126,
				},

				Difficulty_Easy = {
					min = 63,
					max = 126,
				},

				Difficulty_Medium = {
					min = 63,
					max = 126,
				},

				Difficulty_Hard = {
					min = 63,
					max = 126,
				},
			},
		},
		["Lose Your Sense"] = {
			min = 44,
			max = 175,
		},
		["SISYPHUS"] = {
			min = 90,
			max = 190,
		},
		["SMASH"] = {
			min = 80,
			max = 160,
		},
		["STAY GOLD"] = {
			min = 41,
			max = 330,
		},
		["Surrender (PureFocus remix)"] = {
			max = 130,
			hideChange = true,
		},
		["Unreality"] = {
			max = 174,
			hideChange = true,
		},
		["Wuv U"] = {
			min = 87,
			max = 173,
		},
		["9th Outburst"] = {
			min = 82,
			max = 163,
		},
		["Koi no hyoketsu otenba yukemuri Cirno onsen"] = {
			min = 94,
			max = 188,
		},		
		["Mentanpindoradora"] = {
			min = 92,
			max = 185,
		},
	},
	["21 - DDR WORLD"] = {
		["Astra Blaze"] = {
			max = 168,
			hideChange = true,
		},
		["Better When I'm Dancin'"] = {
			max = 128,
			hideChange = true,
		},
		["Burstix Comet"] = {
			charts = {
				Difficulty_Medium = {
					min = 79,
					max = 158,
				},

				Difficulty_Hard = {
					min = 79,
					max = 158,
				},
			},
		},
		["Can't Stop Running!!"] = {
			charts = {
				Difficulty_Medium = {
					min = 98,
					max = 197,
				},
				Difficulty_Hard = {
					min = 98,
					max = 197,
				},
			},
		},
		["Dear Deer"] = {
			charts = {
				Difficulty_Medium = {
					min = 92,
					max = 185,
				},
				Difficulty_Hard = {
					min = 92,
					max = 185,
				},
				Difficulty_Challenge = {
					min = 92,
					max = 185,
				},
			},
		},
		["fixer"] = {
			min = 90,
			max = 215,
		},		
		["Miles on It"] = {
			max = 130,
			hideChange = true,
		},
		["No More Love"] = {
			min = 81,
			max = 162,
		},
		["QuoN"] = {
			max = 168,
			hideChange = true,
		},
		["SCREW owo SCREW"] = {
			charts = {
				Difficulty_Medium = {
					min = 114,
					max = 171,
				},
				Difficulty_Hard = {
					min = 114,
					max = 171,
				},
			},
		},
		["Smintheus"] = {
			charts = {
				Difficulty_Medium = {
					min = 48,
					max = 250,
				},
				Difficulty_Hard = {
					min = 48,
					max = 250,
				},
			},
		},
		["Steps for Victory"] = {
			charts = {
				Difficulty_Medium = {
					min = 105,
					max = 420,
				},
				Difficulty_Hard = {
					min = 105,
					max = 420,
				},
				Difficulty_Challenge = {
					min = 52,
					max = 420,
				},
			},
		},
		["Superior MAXXX"] = {
			charts = {
				Difficulty_Medium = {
					min = 166,
					max = 444,
				},
				Difficulty_Hard = {
					min = 166,
					max = 444,
				},
				Difficulty_Challenge = {
					min = 166,
					max = 444,
				},
			},
		},
		["Timepiece phase II"] = {
			min = 153,
			max = 287,
		},
		["Kagachi"] = {
			max = 170,
			hideChange = true,
		},
		["Kareinaru! Otogi tantei HinaBitter"] = {
			min = 92,
			max = 127,
		},
		["Shukusei!! Loli-kami requiem"] = {
			charts = {
				Difficulty_Challenge = {
					min = 165,
					max = 247,
				},
			},
		},
		["Dadadadadadadadadada (NIJISANJI Dance-bu ver.)"] = {
			max = 156,
			hideChange = true,
		},
		["Tsuki ni murakumo hana ni kaze"] = {
			max = 160,
			hideChange = true,
		},
		["Nante super"] = {
			min = 107,
			max = 195,
		},
		["Hanenaki shoujo uta"] = {
			max = 174,
			hideChange = true,
		},
		
		["Homesick Pt.2&3 (cover)"] = {
			max = 178,
			hideChange = true,
		},
		["Liar dancer"] = {
			max = 170,
			hideChange = true,
		},
		["Yumeiro wonder"] = {
			min = 135,
			max = 208,
		},
	},
}

local function GetSongFolder(song)
	local path = tostring(song:GetSongDir() or "")
	path = path:gsub("\\", "/"):gsub("/+$", "")

	return path:match("([^/]+)$")
end

local function GetSongOverride(song)
	local group = overrides[song:GetGroupName()]

	if not group then
		return nil
	end

	local folder = GetSongFolder(song)

	return folder and group[folder] or nil
end

function GetChartBPMInfo(song, steps)
	if not song or not steps then
		return nil
	end

	local timingData = steps:GetTimingData()
	if not timingData then
		return nil
	end

	local actual = timingData:GetActualBPM()
	if not actual then
		return nil
	end

	local minBPM = actual[1]
	local maxBPM = actual[2]
	local segments = timingData:GetBPMs()
	local hasChange = segments and #segments > 1 or false

	local songOverride = GetSongOverride(song)
	local chartOverride

	if songOverride and songOverride.charts then
		chartOverride = songOverride.charts[tostring(steps:GetDifficulty())]
	end

	local selected = chartOverride or songOverride

	if selected then
		if selected.min then
			minBPM = selected.min
		end

		if selected.max then
			maxBPM = selected.max
		end

		if selected.hideChange then
			hasChange = false
			minBPM = maxBPM
		end
	end

	return {
		min = minBPM,
		max = maxBPM,
		hasChange = hasChange,
	}
end

function RealSpeedCommand(item)
	local song = GAMESTATE:GetCurrentSong()

	for _, pn in ipairs(GAMESTATE:GetEnabledPlayers()) do
		-- solo se toca a quien tenga Real Speed; quien esté en Speed Rate conserva su XMod
		if GetSpeedMode(pn) == "RealSpeed" then
			local steps = GAMESTATE:GetCurrentSteps(pn)
			local bpmInfo = GetChartBPMInfo(song, steps)

			if bpmInfo and bpmInfo.max and bpmInfo.max > 0 then
				local xmod = GetRealSpeed(pn) / bpmInfo.max
				local po = GAMESTATE:GetPlayerState(pn):GetPlayerOptions("ModsLevel_Preferred")
				po:XMod(xmod)
			end
		end
	end
end