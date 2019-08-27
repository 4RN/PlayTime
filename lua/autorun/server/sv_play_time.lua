local PlayTime = {}
--=====SETTINGS=====--
PlayTime.Use_MySQL = false --true/false

PlayTime.MySQL_ip = "127.0.0.1"
PlayTime.MySQL_user = "root"
PlayTime.MySQL_password = "1234"
PlayTime.MySQL_database = "db123"
PlayTime.MySQL_port = "3306"

PlayTime.update_time = 10 --
PlayTime.welcome_message = "[PlayTime] Hello again! Your total time playing here is %s and recently online you were on: %s" 
PlayTime.welcome_message_first_time = "[PlayTime] It seems to be your first time on the server! Make yourself comfortable and make yourself a warm tea!" 
--=====END OF SETTINGS=====--
PlayTime.Connected = nil
PlayTime.db = nil

if PlayTime.Use_MySQL then
	require("mysqloo")
	PlayTime.db = mysqloo.connect(PlayTime.MySQL_ip, PlayTime.MySQL_user, PlayTime.MySQL_password, PlayTime.MySQL_database, PlayTime.MySQL_port)

	
	PlayTime.db.onConnected = function(self)
		PlayTime.Connected = true
		local create_table = self:query("CREATE TABLE IF NOT EXISTS play_time( nick TEXT, SteamID TEXT, time INTEGER, lastonline INTEGER )")
		create_table:start()
		print("[PlayTime] Connected to database!")
	end
	
	function PlayTime.db:onConnectionFailed( err )
		print( "[PlayTime]Connection to database failed!" )
		print( "Error:", err )
	end
	
	PlayTime.db:connect()

else
	if not sql.TableExists("play_time") then
		sql.Query("CREATE TABLE play_time( nick TEXT, SteamID TEXT, time INTEGER, lastonline INTEGER )")
		print("[PlayTime] The database has been successfully created")
	else
		print("[PlayTime] The database has been successfully loaded")
	end
end

function TimeFromSeconds(data)
		local goodtime = tonumber(data)
		if goodtime < 60 then
			goodtime = "less than minute"
		elseif goodtime < 120 then
			goodtime = "minute"
		elseif goodtime < 60*60 then
			goodtime =  math.Round(goodtime/60)
			goodtime = goodtime.." minutes"
		elseif goodtime < 60*60*2 then
			goodtime = "1 hour"
		else 
			goodtime =  math.Round(goodtime/60/60)
			goodtime = goodtime.." hours"
		end
		return goodtime
end

function PlayTime.GetPlayerTime(ply)
	local SQL = "SELECT time FROM play_time WHERE SteamID='"..ply:SteamID().."' LIMIT 1"
	return sql.Query(SQL)[1]["time"]
end

if (timer.Exists("PlayTime_Updater")) then
timer.Remove("PlayTime_Updater")
end

timer.Create("PlayTime_Updater", PlayTime.update_time, 0, function()
	for _, v in pairs(player.GetAll()) do
		if PlayTime.Use_MySQL then
			if v.PlayTime_auth then
					local SQL = "UPDATE play_time SET time=time+"..PlayTime.update_time..", lastonline='".. os.time() .."' WHERE SteamID='"..v:SteamID().."'"
					local q = PlayTime.db:query(SQL)
					q:start()
			end
		else
			local SQL = "UPDATE play_time SET time=time+".. PlayTime.update_time ..", lastonline='".. os.time() .."' WHERE SteamID='"..v:SteamID().."'"
			sql.Query(SQL)
		end
	end
end)

hook.Add("PlayerInitialSpawn", "PlayTime_PlayerCheck", function(ply)
	local steamid = ply:SteamID()
	local current_time = os.time()
	ply.PlayTime_auth = false
	local nick = ply:Nick()
	nick = string.Replace( nick, "'", "" ) 
	nick = string.Replace( nick, ";", "" ) 
	if not PlayTime.Use_MySQL then
	
		
		
			local data = sql.Query("SELECT * FROM play_time WHERE SteamID='"..steamid.."' LIMIT 1")
			if not data then
			
				local SQL = "INSERT INTO play_time( nick, SteamID, time, lastonline ) VALUES ('".. nick .."','" .. steamid .. "', 0, ".. current_time ..")"
				sql.Query(SQL)
				ply:ChatPrint(PlayTime.welcome_message_first_time)
			
			else
			
				local time_online = tonumber(data[1]["time"])
				
				local last_online = os.date( "%H:%M:%S - %d/%m/%Y" , data[1]["lastonline"])
			
				local message = string.format( PlayTime.welcome_message, TimeFromSeconds(time_online), last_online ) 
				ply:ChatPrint(message)
			
			end
		
	else
	
		if PlayTime.Connected then
			
			local SQL = "SELECT * FROM play_time WHERE SteamID='"..steamid.."' LIMIT 1"
			local q = PlayTime.db:query(SQL)
			function q:onSuccess(data)
			
					if data[1] == nil then
						local SQL = "INSERT INTO play_time( nick, SteamID, time, lastonline ) VALUES ('".. nick .."','" .. steamid .. "', 0, ".. current_time ..")"
						local q2 = PlayTime.db:query(SQL)
							q2:start()
							function q2:onSuccess()
							ply.PlayTime_auth = true
							ply:ChatPrint(PlayTime.welcome_message_first_time)
							end
					else
					
						local time_online = tonumber(data[1]["time"])
						local last_online = os.date( "%H:%M:%S - %d/%m/%Y" , data[1]["lastonline"])
						local message = string.format( PlayTime.welcome_message, TimeFromSeconds(time_online), last_online ) 
						ply:ChatPrint(message)
						
						local SQL = "UPDATE play_time SET nick='"..nick.."', lastonline='".. os.time() .."' WHERE SteamID='"..ply:SteamID().."'"
						local q2 = PlayTime.db:query(SQL)
							q2:start()
							function q2:onSuccess()
							ply.PlayTime_auth = true
							end
					end
			end
			q:start()
		else
			print("[PlayTime] Server is not connected to database!!")
		end
	end
end)
