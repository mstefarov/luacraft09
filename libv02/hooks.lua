function hook_puttile(x,y,z,player,bidx,midx)
	local passon = true
	
	local ta = minecraft.gettile(midx,x,y+1,z)
	local tb = minecraft.gettile(midx,x,y-1,z)
	
	if bidx == tile.GRASS then bidx = tile.DIRT end
	if bidx == tile.BLOCKF then bidx = tile.BLOCKH end
	
	if bidx == tile.LAVA or bidx == tile.LAVASTILL or bidx == tile.WATER or bidx == tile.WATERSTILL then
		bidx = -1
		passon = false
	end
	
	-- grass/dirt
	if tb == tile.DIRT and isclear[bidx] then
		minecraft.settile_announce(midx,x,y-1,z,tile.GRASS)
	elseif tb == tile.GRASS and not isclear[bidx] then
		minecraft.settile_announce(midx,x,y-1,z,tile.DIRT)
	end
	
	if bidx == tile.DIRT and isclear[ta] then
		bidx = tile.GRASS
	end
	
	-- half blocks
	if tb == tile.BLOCKH and bidx == tile.BLOCKH then
		minecraft.settile_announce(midx,x,y-1,z,tile.BLOCKF)
		minecraft.settile_announce(midx,x,y,z,tile.AIR)
		bidx = -1
		passon = false
	elseif tb == tile.BLOCKF and bidx == tile.AIR then
		bidx = tile.BLOCKF
	end
	
	if passon then
		minecraft.settile_announce(midx,x,y,z,bidx)
	end
end

function hook_dotick()
	for i,nick in ipairs(players) do
		local p = players.obj[nick]
		local idx = minecraft.getidxbynick(nick)
		local midx = minecraft.gp_midx(idx)
		if midx ~= nil then
			local x,y,z,yo,xo
			x,y,z,yo,xo = minecraft.gp_pos(idx)
			if x ~= 0 or y ~= 0 or z ~= 0 then
				local mapname = settings.map_lookup[midx]
				local map = settings.maps[mapname]
				local curport = nil
				
				--print(nick..": "..x..","..y..","..z)
				
				x = math.floor(x / 32)
				y = math.floor(y / 32)
				z = math.floor(z / 32)
				
				if map.portals then
					for j,port in ipairs(map.portals) do
						if x >= port.x1 and x <= port.x2 then
							if y >= port.y1 and y <= port.y2 then
								if z >= port.z1 and z <= port.z2 then
									curport = port
								end
							end
						end
					end
					
					if curport then
						local sx,sy,sz,syo,sxo
				
						sx = curport.spawn.x
						sy = curport.spawn.y
						sz = curport.spawn.z
						syo = curport.spawn.yo
						sxo = curport.spawn.xo
						
						x,y,z,yo,xo = minecraft.gp_pos(idx)
						x = (x - curport.x1)*curport.scale
						y = (y - curport.y1)*curport.scale
						z = (z - curport.z1)*curport.scale
						sx = sx + x
						sy = sy + y
						sz = sz + z
						
						minecraft.setmap(idx,curport.altname,curport.message,settings.maps[curport.target].midx,
							sx,sy,sz,syo,sxo)
					end
				end
			end
		end
	end
end

function hook_chat(idx,pid,msg)
	local nick = minecraft.gp_nick(idx)
	
	print(nick..": "..msg)
	minecraft.chatmsg_all(pid,nick..": "..msg)
end

function hook_join(pid,nick,idx,midx)
	players.obj[nick].midx = midx
	local mapname = settings.map_lookup[midx] or "(?)"
	minecraft.chatmsg_map(midx,0x7F,nick.." has joined "..mapname)
end

function hook_part(pid,nick,idx,midx)
	players.obj[nick].midx = nil
	local mapname = settings.map_lookup[midx] or "(?)"
	minecraft.chatmsg_map(midx,0x7F,nick.." has left "..mapname)
end

function hook_connect(pid,nick,idx)
	local mapname = settings.map_default
	local map = settings.maps[mapname]
	local midx = map and map.midx
	
	if midx == nil then
		print("MAP "..mapname.." DOES NOT EXIST")
		return false
	end
	
	local x,y,z,yo,xo
	
	x = map.spawn.x
	y = map.spawn.y
	z = map.spawn.z
	yo = map.spawn.yo
	xo = map.spawn.xo
	
	player_add(nick)
	minecraft.chatmsg_all(0x7F,nick.." has connected")
	minecraft.setmap(idx,settings.server_name,settings.server_message,midx,x,y,z,xo,yo)
	
	return true
end

function hook_disconnect(pid,nick,idx)
	minecraft.chatmsg_all(0x7F,nick.." has disconnected")
end

minecraft.sethook_puttile("hook_puttile")
minecraft.sethook_dotick("hook_dotick")
minecraft.sethook_chat("hook_chat")
minecraft.sethook_join("hook_join")
minecraft.sethook_part("hook_part")
minecraft.sethook_connect("hook_connect")
minecraft.sethook_disconnect("hook_disconnect")
