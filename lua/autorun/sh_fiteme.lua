
AddCSLuaFile()

if(SERVER) then

	--Keep track of all the ongoing duels.
	local Duels = {}
	
	--Keep track of all the outgoing duel requests.
	local DuelChallenges = {}
	
	util.AddNetworkString( "duelchallenge" )
	util.AddNetworkString( "duelaccept" )
	util.AddNetworkString( "duelannounce" )
	util.AddNetworkString( "duelnotify" )
	util.AddNetworkString( "duelsurrender" )
	util.AddNetworkString( "dueldisconnect" )
	util.AddNetworkString( "duelstatus" )
	
	
	--Find player by name
	function pl(name) 
		name = string.lower(name) 
		for k, v in pairs(player.GetAll()) do 
			if(string.find(string.lower(v:GetName()),name,1,true)and v:IsPlayer()) then 
				return v 
			end 
		end 
	end 
	
	local function TableHasValForKey(tbl, val, key)
		for i = 1, table.Count(tbl) do
			if(tbl[i][key] == val) then
				return i
			end
		end
		return nil
	end
	
	local function TablePosWithValForKey(tbl, val, key)
		local positions = {}
		for i = 1, table.Count(tbl) do
			if(tbl[i][key] == val) then
				table.insert(positions, i)
			end
		end
		return positions
	end
	
	local function TableFirstPosWithValForKey(tbl, val, key)
		for i = 1, table.Count(tbl) do
			if(tbl[i][key] == val) then
				return i
			end
		end
		return nil
	end
	
	local function DuelGlobalChatAnnounce(p1, str1, p2, str2)
		net.Start( "duelannounce" )
		net.WriteEntity(p1)
		net.WriteString(str1)
		net.WriteEntity(p2)
		net.WriteString(str2)
		net.Send(player.GetAll())
	end
	
	local function DuelChatNotify(ply, str)
		net.Start( "duelnotify" )
		net.WriteString(str)
		net.Send(ply)
	end
	
	--Send/Accept duel challenges. Sorry for GIANT function.
	net.Receive( "duelchallenge", function( len, ply )
		local args = net.ReadTable()
		
		local targply = pl(args[1])
		if(IsValid(targply) && targply:IsPlayer()) then
			--Check if there's already a duel challenge from target player for this player. If so, accept the challenge.
			local check = TablePosWithValForKey(DuelChallenges, targply, "p1")
			for i = 1, table.Count(check) do
				if(DuelChallenges[i].p2 == ply) then
					print(ply:Nick().." has accepted "..targply:Nick().."'s challenge!")
					DuelGlobalChatAnnounce(ply, " has accepted ", targply, "'s challenge!")
					
					table.remove(DuelChallenges, i)
					
					--Go through and remove any challenges given out by both players
					check = TablePosWithValForKey(DuelChallenges, targply, "p1")
					for i = 1, table.Count(check) do
						table.remove(DuelChallenges, i)
					end
					check = TablePosWithValForKey(DuelChallenges, ply, "p1")
					for i = 1, table.Count(check) do
						table.remove(DuelChallenges, i)
					end
					
					--Create the duel.
					local DuelStruct = {}
					DuelStruct.p1 = targply
					DuelStruct.p2 = ply
					DuelStruct.p1kills = 0
					DuelStruct.p2kills = 0
					
					table.insert(Duels, DuelStruct)
					
					net.Start( "duelaccept" )
					net.Send(player.GetAll())
						
					return
				end
			end
			
			--Else, send the challenge.
			--Check if the player is challenging him/herself.
			if(ply == targply) then
				print(ply:Nick().." tried to challenge themselves.")
				DuelChatNotify(ply, "You can't duel yourself. Sorry, but that's the way the world works.")
				return
			end
			--Do not let the player send or accept duel requests if already in a duel.
			if(TableHasValForKey(Duels, ply, "p1") || TableHasValForKey(Duels, ply, "p2")) then
				print(ply:Nick().." is eager to duel "..targply:Nick().." but is already in a duel!")
				DuelChatNotify(ply, "You are already in a duel. Get lost.")
				return
			end
			
			--Auto-accept duel request if is bot. Sorry for the terrible code duplication. We do this check all the way down here so it goes through the "already-in-a-duel" check first. Fix later.
			if(targply:IsBot()) then
				print(ply:Nick().." has accepted "..targply:Nick().."'s challenge!")
				DuelGlobalChatAnnounce(ply, " has accepted ", targply, "'s challenge!")
					
				table.remove(DuelChallenges, i)
					
				--Go through and remove any challenges given out by both players
				check = TablePosWithValForKey(DuelChallenges, targply, "p1")
				for i = 1, table.Count(check) do
					table.remove(DuelChallenges, i)
				end
				check = TablePosWithValForKey(DuelChallenges, ply, "p1")
				for i = 1, table.Count(check) do
					table.remove(DuelChallenges, i)
				end
					
				--Create the duel.
				local DuelStruct = {}
				DuelStruct.p1 = targply
				DuelStruct.p2 = ply
				DuelStruct.p1kills = 0
				DuelStruct.p2kills = 0
					
				table.insert(Duels, DuelStruct)
					
				net.Start( "duelaccept" )
				net.Send(player.GetAll())
						
				return
			end
			
			--First check if this player has already sent a request to the given targplayer. If so, stop.
			check = TablePosWithValForKey(DuelChallenges, ply, "p1")
			for i = 1, table.Count(check) do
				if(DuelChallenges[i].p2 == targply) then
					print(ply:Nick().." has nagged "..targply:Nick().." to a duel!")
					DuelChatNotify(ply, "You have already challenged that player to a duel. Quit nagging.")
					return 
				end
			end
			
			--Now, send the challenge.
			print(ply:Nick().." has challenged "..targply:Nick().." to a duel!")
			DuelGlobalChatAnnounce(ply, " has challenged ", targply, " to a duel!")

			local DuelChallengeStruct = {}
			DuelChallengeStruct.p1 = ply
			DuelChallengeStruct.p2 = targply
			
			table.insert(DuelChallenges, DuelChallengeStruct)
			PrintTable(DuelChallenges)
			
			net.Start( "duelchallenge" )
			net.Send(player.GetAll())
		else
			DuelChatNotify(ply, "No idea who you just tried to challenge.")
		end
	end )
	
	--Handle players surrendering.
	net.Receive( "duelsurrender", function( len, ply )
		local check1 = TableFirstPosWithValForKey(Duels, ply, "p1")
		local check2 = TableFirstPosWithValForKey(Duels, ply, "p2")
		local otherply
		if(check1 != nil || check2 != nil) then
			if(check1 != nil) then
				otherply = Duels[check1].p2
				table.remove(Duels, check1)
			elseif (check2 != nil) then
				otherply = Duels[check2].p1
				table.remove(Duels, check2)
			end 
			DuelGlobalChatAnnounce(ply, " has surrendered to ", otherply, ". Coward.")
			net.Start( "duelsurrender" )
			net.Send(player.GetAll())
		else
			DuelChatNotify(ply, "Who are you even surrendering to?")
		end
	end )	
	
	net.Receive( "duelstatus", function( len, ply )
		local check1 = TableFirstPosWithValForKey(Duels, ply, "p1")
		local check2 = TableFirstPosWithValForKey(Duels, ply, "p2")
		local curduel
		if(check1 != nil || check2 != nil) then
			if(check1 != nil) then
				curduel = table.Copy(Duels[check1])
			elseif (check2 != nil) then
				curduel = table.Copy(Duels[check2])
			end 
			net.Start( "duelstatus" )
			net.WriteTable(curtable)
			net.Send(ply)
		else
			DuelChatNotify(ply, "You are not in a duel.")
		end
	end )	
	
	local function DuelDisconnect(ply)
		local check1 = TableFirstPosWithValForKey(Duels, ply, "p1")
		local check2 = TableFirstPosWithValForKey(Duels, ply, "p2")
		local otherply
		--Remove from all tables.
		if(check1 != nil || check2 != nil) then
			if(check1 != nil) then
				otherply = Duels[check1].p2
				table.remove(Duels, check1)
			elseif (check2 != nil) then
				otherply = Duels[check2].p1
				table.remove(Duels, check2)
			end 
			DuelGlobalChatAnnounce(ply, " has fled from ", otherply, ", tail between their legs.")
			net.Start( "duelsurrender" )
			net.Send(player.GetAll())
		end
		
		--Clean all challenges given by and to them
		check = TablePosWithValForKey(DuelChallenges, ply, "p1")
		for i = 1, table.Count(check) do
			table.remove(DuelChallenges, i)
		end
		check = TablePosWithValForKey(DuelChallenges, ply, "p2")
		for i = 1, table.Count(check) do
			table.remove(DuelChallenges, i)
		end
	end
	hook.Add("PlayerDisconnect", "DuelDisconnect", DuelDisconnect)
	
	--Damage restriction
	local function DuelShouldTakeDamage(ply, attacker)
		//if the attacker is not a player, return true
		if(!attacker:IsPlayer()) then
			return true
		end
		--If the player is not dueling
		if(!TableHasValForKey(Duels, ply, "p1") && !TableHasValForKey(Duels, ply, "p2")) then
			--if the attacker is not in a duel then take damage
			if(!TableHasValForKey(Duels, attacker, "p1") && !TableHasValForKey(Duels, attacker, "p2")) then
				return true
			else
				DuelChatNotify(attacker, "You cannot hurt a player who is not in a duel with you.")
				return false
			end
		end
		--If the player and attacker are in a duel then take damage.
		for k, v in pairs(Duels) do
			if((ply == v.p1 && attacker == v.p2) || (ply == v.p2 && attacker == v.p1)) then
				return true
			end
		end
		--Otherwise, do no damage and tell the attacking player why he is not doing any damage.
		if(attacker:IsPlayer()) then
			DuelChatNotify(attacker, "You cannot hurt a player who is in a duel with somebody other than you.")
		end
		return false
	end
	hook.Add("PlayerShouldTakeDamage", "DuelShouldTakeDamage", DuelShouldTakeDamage)
	
	function DuelDeath( victim, inflictor, attacker )
		if(!TableHasValForKey(Duels, victim, "p1") && !TableHasValForKey(Duels, victim, "p2")) then return end
		
		if ( victim == attacker ) then
			local check = TableFirstPosWithValForKey(Duels, victim, "p1")
			if(check != nil) then
				Duels[check].p1kills = Duels[check].p1kills - 1
			end
			check = TableFirstPosWithValForKey(Duels, victim, "p2")
			if(check != nil) then
				Duels[check].p2kills = Duels[check].p2kills - 1
			end
		end
		
	end
	hook.Add("PlayerDeath", "DuelDeath", DuelDeath)
end

if (CLIENT) then
	concommand.Add( "duel_challenge", function(ply, cmd, args, argstring)
		net.Start( "duelchallenge" )
		net.WriteTable(args)
		net.SendToServer()
	end )
	
	concommand.Add( "duel_surrender", function(ply, cmd, args, argstring)
		net.Start( "duelsurrender" )
		net.SendToServer()
	end )
	
	concommand.Add( "duel_status", function(ply, cmd, args, argstring)
		net.Start( "duelstatus" )
		net.SendToServer()
	end )
	
	net.Receive( "duelchallenge", function( len, ply )
		surface.PlaySound( "ambient/alarms/warningbell1.wav" )
	end )
	
	net.Receive( "duelaccept", function( len, ply )
		surface.PlaySound( "ambient/machines/wall_ambient1.wav" )
	end )

	net.Receive( "duelsurrender", function( len, ply )
		surface.PlaySound( "vo/npc/barney/ba_laugh02.wav" )
	end )
	
	net.Receive( "duelnotify", function( len, ply )
		chat.AddText(Color(46,204,113), "[FiteMe] ", Color(220,220,220), net.ReadString())
	end )
	
	net.Receive( "duelannounce", function( len, ply )
		chat.AddText(Color(46,204,113), "[FiteMe] ", Color(220,220,220), net.ReadEntity(), net.ReadString(), net.ReadEntity(), net.ReadString())
	end )
	
	net.Receive( "duelstatus", function( len, ply )
		local status = net.ReadTable()
		chat.AddText(Color(46,204,113), "[FiteMe] ", Color(220,220,220), status.p1, ": ", status.p1kills, ", ", status.p2, ": ", status.p2kills)
	end )
	
	local function DuelChatCommands( ply, text, teamChat, isDead )
		if ply != LocalPlayer() then return end
	
		local expl = string.Explode(" ", text, false)
		
		--Duel
		if ( expl[1] == "!duel" ) then
			local args = table.Copy(expl)
			table.remove(args, 1)
			net.Start( "duelchallenge" )
			net.WriteTable(args)
			net.SendToServer()
			return true
		end
		
		--Surrender
		if ( expl[1] == "!surrender" ) then
			net.Start( "duelsurrender" )
			net.SendToServer()
			return true
		end
		
	end
	hook.Add( "OnPlayerChat", "DuelChatCommands", DuelChatCommands)
	
end
