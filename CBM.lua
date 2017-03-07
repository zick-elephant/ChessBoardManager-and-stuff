--
-- Author: zick_elephant
-- Date: 2015-12-15&H:48:59
-- ChessBoardManager,缩写成CBM
CBM = {}

-- 用于在scene之间传输参数的公共变量
CBM.sceneobj = {}

CBM.chosen = {}

CBM.partychangeEvent = {}

function CBM:new(o)
    o = o or {}
    setmetatable(o,self)
    self.__index = self
    self.rpvect = {}
    self.rpcenter = {}
    self.rows = 0
    self.cols = 0
    self.startx = 0
    self.starty = 0
    -- 默认六边形边长是41
    self.sidelen = 41
    -- 格子数据记录
    self.mapData = {}
    -- 默认地图定义
    self.mapDefine = {}
    -- 六个方向偏移量,行数为偶数时，后两个偏移量列数都加1，行数为奇数时，后两个偏移量列数都减1；
    self.aDir = {{0,1},{0,-1},{-1,0},{1,0},{-1,1},{1,1}}
    self.bDir = {{0,1},{0,-1},{-1,0},{1,0},{-1,-1},{1,-1}}
    -- 起始点
    self.starr = {}
    --开闭列表
    self.openlist = {}
    self.closelist = {}
    -- 所有步数集合
    self.allpath = {}
    -- 当前还可以通过的格子集合
    self.passable_remain = {}
    -- 
    self.check = {}

    return o
end

function CBM:getInstance()
    if self.instance_ == nil then
        self.instance_ = self:new()
    end

    return self.instance_
end

-- function CBM:initMapCheck(dest)
-- 	for i=1,#dest do
-- 		self.check[dest[i][1]][dest[i][2]] = true
-- 	end
-- end
-- 纯粹查看重复点，若未重复，则使该点的hash为true
function CBM:mapCheck(gd)
	if self.check[gd[1]][gd[2]] then
		return true
	else
		self.check[gd[1]][gd[2]] = true
		return false
	end
end

function CBM:resetMapCheck()
	for i=1,self.rows do
		self.check[i] = {}
	end
end

function CBM:releaseInstance()
	if self.instance_ then
		self.instance_ = nil
	end
end
function CBM:setInit( param )
	if param == nil then
		print("CBM初始传参错误，参数table为空")
		return
	end
	self.rows = checkint(param.rows or 11)
	self.cols = checkint(param.cols or 14)
	self.sidelen = checknumber(param.sidelen or 41)
	self.startx = checknumber(param.startx or 100)
	self.starty = checknumber(param.starty or 30)
	self:resetMapCheck()
end
-- 返回一个随机格子
function CBM:getRandomGrid(passAble,except)
	local result = nil
	passAble = CALC_3(passAble==false,false,true)
	if except and #except>=#self.passable_remain then
		except = nil
	end
	if self.rows>0 and self.cols>0 then
		if passAble and #self.passable_remain>0 then
			repeat
				result = self.passable_remain[math.random(#self.passable_remain)]
			until not except or not next(except) or not contain2D(result,except)
		else
			repeat
				result = {math.random(self.rows),math.random(self.cols)}
			until not except or not next(except) or not contain2D(result,except)
		end
	end
	return result
end
-- 判断是否为有效格子（不超过或小于行列数）
function CBM:isValidGrid( pos )
	if pos == nil or not next(pos) then
		return false
	end
	if pos[1] > self.rows or pos[1] < 1 or pos[2] > self.cols or pos[2] < 1 then
		return false
	end
	return true
end
-- 由行列数得到的确切x,y位置，注意行列数从1开始
function CBM:getPos(row,col,tocenter)
	if not self:isValidGrid({row,col}) then
		print("无效格子:"..row..","..col.."当前地图总行列数：",self.rows,self.cols)
		return nil
	end
	tocenter = checkbool(tocenter or false)
	scaleX = checknumber(scaleX or 1)
	scaleY = checknumber(scaleY or 1)
	local i = (row-1)*self.cols + col
	-- print(i,row,col,self.cols,tocenter)
	if tocenter then
		return clone(self.rpcenter[i])
	else
		return clone(self.rpvect[i])
	end
end
-- 返回对应col数的一整列格子坐标集合(只需要有rows和cols即可)
function CBM:getCol(which)
	local result = {}
	which = checkint(which or 1)
	if self.rows>0 and self.cols>0 then
		for i=1,self.rows do
			Push(result,{i,which})
		end
	end
	return result
end
-- 得到一条直线的格子坐标集合，参数（起点，方向，长度起始,长度(0表示到头)，是否包含起点），方向为从水平左起顺时针由1到6，总共六个方向；
function CBM:getaline(pos,direct,begin,len,includeself)
	if not self:isValidGrid(pos) then
		-- print("参数为非法格子———getaline(pos)")
		return nil
	end
	direct = checkint(direct or 1)
	begin = checkint(begin or 0)
	includeself = checkbool(includeself or false)
	local long = checkint(len or 0)
	local result = {}
	if includeself then
		Push(result,pos)
	end
	local newg = {}
	local newar = {}
	local b = 0
	if direct == 1 then
		newg = {pos[1],pos[2] - 1}
		while newg[2]>= 1 do
			newar = clone(newg)
			Push(result,newar)
			newg[2] = newg[2] - 1
			if long > 0 then
				long = long - 1
				if long<=0 then
					break
				end
			end
		end
	elseif direct == 4 then
		newg = {pos[1],pos[2] + 1}
		while newg[2]<=self.cols do
			newar = clone(newg)
			Push(result,newar)
			newg[2] = newg[2] + 1
			if long > 0 then
				long = long - 1
				if long<=0 then
					break
				end
			end
		end
	elseif direct == 2 then
		newg = clone(pos)
		while self:isValidGrid(newg) do
			newar = clone(newg)
			b = CALC_3(newar[1]%2==0,-1,0)
			newar[2] = newar[2] + b
			newar[1] = newar[1] + 1
			if self:isValidGrid(newar) then
				Push(result,newar)
			end
			newg = newar
			if long > 0 then
				long = long - 1
				if long<=0 then
					break
				end
			end
		end
	elseif direct == 3 then
		newg = clone(pos)
		while self:isValidGrid(newg) do
			newar = clone(newg)
			b = CALC_3(newar[1]%2==0,0,1)
			newar[2] = newar[2] + b
			newar[1] = newar[1] + 1
			if self:isValidGrid(newar) then
				Push(result,newar)
			end
			newg = newar
			if long > 0 then
				long = long - 1
				if long<=0 then
					break
				end
			end
		end
	elseif direct == 6 then
		newg = clone(pos)
		while self:isValidGrid(newg) do
			newar = clone(newg)
			b = CALC_3(newar[1]%2==0,-1,0)
			newar[2] = newar[2] + b
			newar[1] = newar[1] - 1
			if self:isValidGrid(newar) then
				Push(result,newar)
			end
			newg = newar
			if long > 0 then
				long = long - 1
				if long<=0 then
					break
				end
			end
		end
	elseif direct == 5 then
		newg = clone(pos)
		while self:isValidGrid(newg) do
			newar = clone(newg)
			b = CALC_3(newar[1]%2==0,0,1)
			newar[2] = newar[2] + b
			newar[1] = newar[1] - 1
			if self:isValidGrid(newar) then
				Push(result,newar)
			end
			newg = newar
			if long > 0 then
				long = long - 1
				if long<=0 then
					break
				end
			end
		end
	else
		print("得到直线方向超出第6个--getaline")
	end
	if begin > 0 then
		while begin > 0 do
		table.remove(result,1)
		begin = begin - 1
		end
	end
	return result
end
-- 得到一个(二维数组)为中心的米字形范围,参数：角色，方向起始，方向数（水平左起顺时针旋转），远起始，多远（far = 0表示到地图尽头）；
function CBM:riceShape(po,directstart,directlength,startIndex,far,includeself)
	-- print("riceShape传参:",directstart,directlength,startIndex,far)
	far = checkint(far or 0)
	includeself = checkbool(includeself or false)
	local result = {}
	local ric1 = {}
	local ric2 = {}
	local st = checkint(directstart or 1)
	local dl = checkint(directlength or 6)
	local sndex = checkint(startIndex or 0)
	if next(po) then
		for i=1,#po do
			for j=1,dl do
				local dst = CALC_3(j+st-1>6,(j+st-1)%6,j+st-1)
				if i==1 then
					local aline = self:getaline(po[i], dst, sndex, far, false)
					for k=1,#aline do
						ric1[#ric1+1] = aline[k]
					end
					-- ric1 = ASconcat(ric1,self:getaline(po[i], dst, sndex, far, false))
				else
					ric2 = ASconcat(ric2,self:getaline(po[i], dst, sndex, far, false))
				end
			end
		end
		result = combine2D(ric1,ric2)
		if includeself then
			for i=1,#po do
				result[#result+1] = po[i]
			end
			-- result = ASconcat(result,po)
		end
	end
	return result
end
-- 根据给定的起始点和目标格，返回一个固定长度的，包含此格子的规范化60度的扇形区域
function CBM:fanShape(startpos,despos,far,hollow,includeself)
	far = checkint(far or 3)
	local fanIndex = 0
	local inside = nil
	local result = {}
	local jibo = startpos[1]%2 ~= 0
	if despos[1] > startpos[1] then
		if jibo then
			if despos[2] <= startpos[2] then
				fanIndex = 1
				inside = {1,-1}
			elseif despos[2] > startpos[2] + 1 then
				fanIndex = 3
				inside = {1,2}
			else
				fanIndex = 2
				inside = {2,0}
			end
		else
			if despos[2] < startpos[2] then
				fanIndex = 1
				inside = {1,-2}
			elseif despos[2] > startpos[2] then
				fanIndex = 3
				inside = {1,1}
			else
				fanIndex = 2
				inside = {2,0}
			end
		end
	elseif despos[1] < startpos[1] then
		if jibo then
			if despos[2] < startpos[2] then
				fanIndex = 6
				inside = {-1,-1}
			elseif despos[2] >= startpos[2] + 1 then
				fanIndex = 4
				inside = {-1,2}
			else
				fanIndex = 5
				inside = {-2,0}
			end
		else
			if despos[2] < startpos[2] - 1 then
				fanIndex = 6
				inside = {-1,-2}
			elseif despos[2] >= startpos[2] then
				fanIndex = 4
				inside = {-1,1}
			else
				fanIndex = 5
				inside = {-2,0}
			end
		end
	else
		if despos[2] >= startpos[2] then
			fanIndex = 3
			inside = CALC_3(jibo,{1,2},{1,1})
		else
			fanIndex = 6
			inside = CALC_3(jibo,{-1,-1},{-1,-2})
		end
	end
	local presetclose = self:riceShape({startpos}, fanIndex, 2, hollow, far, includeself)
	if self:isValidGrid(inside) and far>2 then
		result = self:getshotArea(inside, far - 1, hollow, includeself, presetclose)
	else
		result = presetclose
	end
	return result
end

-- 返回两个非重叠的角色，或格子之间的距离（非直线距离，而是在棋盘上要经过的最短格子数(无视地形)）
function CBM:distanceOfGrid(arg1,arg2)
	local dis = 0
	local fur = 1
	if arg1 and arg2 then
		local from = {arg1}
		if arg1.__cname == "RoleView" then from = occupy1or2(arg1) end
		local to = {arg2}
		if arg2.__cname == "RoleView" then to = occupy1or2(arg2) end
		
		while fur < self.cols + self.rows do
			local rea = self:getshotArea(from,fur,0,false)
			if #intersection2D(rea,to)>0 then
				-- 最少返回1
				dis = fur
				break
			end
			fur = fur + 1
		end
	end
	return dis
end
-- 确定触摸点(单点触摸)位于哪一个六边形之内,返回{行，列}
function CBM:checker( point,scaleX,scaleY )
	if point == nil then
		print("CBM -- checker参数point为nil")
		return nil
	end
	scaleX = checknumber(scaleX or 1)
	scaleY = checknumber(scaleY or 1)
	local high = (self.sidelen * 1.5 * self.rows + self.starty)*scaleY
	local wide = (self.sidelen * 1.73 * self.cols + self.startx)*scaleX
	if point.y < (self.starty - self.sidelen*0.5)*scaleY or point.y > high or point.x < (self.startx - 0.866*self.sidelen)*scaleX or point.x > wide then
		-- print(point.x,point.y,"checker超出棋盘边界:",high,wide)
		return nil
	end
	local result = {}
	local gao = self.sidelen*1.5*scaleY
	local kuan = self.sidelen*1.73*scaleX
	local r = math.floor((point.y - self.starty*scaleY + 0.5*self.sidelen*scaleY)/gao)
	local ra = {}
	if r <= 0 then
		ra[#ra + 1] = 1
	elseif r >= self.rows then
		ra[#ra + 1] = self.rows
	else
		ra[#ra + 1] = r
		ra[#ra + 1] = r + 1
	end
	local c = math.floor((point.x - self.startx*scaleX + self.sidelen*0.86*scaleX)/kuan)
	local ca = {}
	if c <= 0 then
		ca[#ca +1] = 1
	elseif c >= self.cols then
		ca[#ca + 1] = self.cols
	else
		ca[#ca + 1] = c
		ca[#ca + 1] = c + 1
	end
	local  pre = {}
	for i=1,#ra do
		for j=1,#ca do
			pre[#pre + 1] = {self:getPos(ra[i],ca[j],true,scaleX,scaleY),ra[i],ca[j]}
		end
	end
	-- dump(pre,"预判断格子")
	-- 判断是否在内的内外接圆半径只接受等比缩放
	local sr = self.sidelen*0.866*scaleX
	local br = self.sidelen*scaleX
	local aft = {}
	for i=1,#pre do
		local np = pre[i][1]
		local dis = cc.pGetDistance(np, point)
		if dis < sr then
			result = {pre[i][2],pre[i][3]}
			return result
		elseif dis > br then
			-- nothing
		else
			aft[#aft +1] = {dis,pre[i][2],pre[i][3]}
			-- print(aft[#aft])
		end
	end
	table.sort( aft, Sort2Dimen )
	-- dump(aft)
	if next(aft) then
		result = {aft[1][2],aft[1][3]}
	end
	return result
end
function CBM:initMapData( tbl )
	self.mapData = {}
	for i=1,self.rows do
		self.mapData[i] = {}
	end
	for i=1,self.rows do
		for j=1,self.cols do
			--- 下面数组内分别代表:id，是否可通过，通过代价，是否已标记，阵营,是否锁定
			self.mapData[i][j] = {0,true,1,0,"",false}
		end
	end
	-- 通过传入的参数初始化地图上的不可通过区域或其它，默认为无,使用锁定标记强制不通行地块
	if tbl ~= nil and #tbl > 0 then
		--todo
	end
end

function CBM:updateMapData( arr,rvo,obj,removeBarrier)
	removeBarrier = checkbool(removeBarrier or false)
	self:initMapData(obj)
	-- 数组存在，有长度，第一个值是角色类
	if arr ~= nil and #arr ~= 0 then
		local len = #arr
		for i=1,len do
			if arr[i] ~= nil and not arr[i]:isDead() and (not arr[i]:isSneaking() or arr[i]:getRoleVo().id < 0) then
				if not(removeBarrier and arr[i]:getRoleVo().party == "abiotic") then
					local arrvo = arr[i]:getRoleVo()
					if arrvo.occupy == 1 then
						-- 向地图数据组中录入角色位置信息，id为0则说明没有角色或障碍存在,大于1000且小于2000为人物ID，大于2000为召唤生物ID；
						self.mapData[arrvo.row][arrvo.col] = {arrvo.id,arrvo.passable,arrvo.movecost,0,arrvo.party}
					elseif arrvo.occupy == 2 then
						self.mapData[arrvo.row][arrvo.col] = {arrvo.id,arrvo.passable,arrvo.movecost,0,arrvo.party}
						self.mapData[arrvo.row][arrvo.col + 1] = {arrvo.id,arrvo.passable,arrvo.movecost,0,arrvo.party}
					end
				end
			end
		end
	end
	-- 重新初始passable_remain
	self.passable_remain = {}
	-- 下面这部分应改为对不同阵营的角色进行self.mapData的重新初始化
	if rvo ~= nil and (rvo.party ~= "neutral" or rvo.party ~= "abiotic") or rvo == nil then
		local opp
		if rvo ~= nil and rvo.party ~= "neutral" then
			opp = CALC_3(rvo.party=="mine" or rvo.party == "ally","enemy","mine")
		end
		for i=1,self.rows do
			for j=1,self.cols do
				if self.mapData[i][j][2] then
					Push(self.passable_remain,{i,j})
				end
				-- id大于0是人物ID,小于0为召唤物（死物）ID,不会对周围的格子行动力消耗造成影响；
				if rvo ~= nil and self.mapData[i][j][1] > 0 and self.mapData[i][j][5] == opp and not self.mapData[i][j][2] then
				---	self.mapData[i][j] = {0,true,1,0,"",false}分别代表:id，是否可通过，通过代价，是否已标记，阵营,是否锁定
					if i-1>=1 and self.mapData[i-1][j][4]==0 then
						self.mapData[i - 1][j][3] = self.mapData[i - 1][j][3] + 1
						self.mapData[i - 1][j][4] = 1
					end
					if i+1 <= self.rows and self.mapData[i+1][j][4] == 0 then
						self.mapData[i + 1][j][3] = self.mapData[i + 1][j][3] + 1
						self.mapData[i + 1][j][4] = 1
					end
					if j-1>=1 and self.mapData[i][j - 1][4]==0 then
						self.mapData[i][j - 1][3] = self.mapData[i][j - 1][3] + 1
						self.mapData[i][j - 1][4] = 1
					end
					if j+1 <= self.cols and self.mapData[i][j + 1][4]==0 then
						self.mapData[i][j + 1][3] = self.mapData[i][j + 1][3] + 1
						self.mapData[i][j + 1][4] = 1
					end
					if i % 2 ~= 0 then
						if i-1>=1 and j+1 <= self.cols and self.mapData[i - 1][j + 1][4] == 0 then
							self.mapData[i - 1][j + 1][3] = self.mapData[i - 1][j + 1][3] + 1
							self.mapData[i - 1][j + 1][4] = 1
						end
						if i+1<= self.rows and j+1 <= self.cols and self.mapData[i + 1][j + 1][4]==0 then
							self.mapData[i + 1][j + 1][3] = self.mapData[i + 1][j + 1][3] + 1
							self.mapData[i + 1][j + 1][4] = 1
						end
					elseif i%2 ==0 then
						if i-1>=1 and j-1>=1 and self.mapData[i - 1][j - 1][4]==0 then
							self.mapData[i - 1][j - 1][3] = self.mapData[i - 1][j - 1][3] + 1
							self.mapData[i - 1][j - 1][4] = 1
						end
						if i+1<= self.rows and j-1>=1 and self.mapData[i + 1][j - 1][4]==0 then
							self.mapData[i + 1][j - 1][3] = self.mapData[i + 1][j - 1][3] + 1
							self.mapData[i + 1][j - 1][4] = 1
						end
					end
				end
			end
		end
	end
end
-- 检测一个格子是否可以被召出召唤生物
function CBM:gridOKforSC(gd)
	if next(gd) then
		if self.mapData[gd[1]][gd[2]][1] == 0 and self.mapData[gd[1]][gd[2]][2] then
			return true
		end
	end
	return false
end
-- 检测该格是否有地雷
function CBM:isThereTrap(row,col)
	if self.mapData[row][col][1] < 0 then
		return true
	end
	return false
end
-- 检测path路径上,角色(单双格)是否会踩到地雷(i从2开始),并返回地雷格(一格或两格)；
function CBM:trapDetect(ro,gds,pathType,parabolic)
	local result = {}
	local bro = false
	pathType = CALC_3(pathType==false,false,true)
	parabolic = checkbool(parabolic or false)
	local sti = CALC_3(pathType,3,1)
	if ro and next(gds) then
		local rvo = ro:getRoleVo()
		local len = #gds
		if ro:isFly() or parabolic then
			if self:isThereTrap(gds[len][1],gds[len][2]) then
				Push(result,gds[len])
			end
			if rvo.occupy == 2 then
				if self:isThereTrap(gds[len][1],gds[len][2] + 1) then
					Push(result,{gds[len][1],gds[len][2] + 1})
				end
			end
		else
			for i=sti,len do
				if self:isThereTrap(gds[i][1],gds[i][2]) then
					Push(result,gds[i])
					bro = true
				end
				if rvo.occupy == 2 then
					if self:isThereTrap(gds[i][1],gds[i][2] + 1) then
						Push(result,{gds[i][1],gds[i][2] + 1})
						bro = true
					end
				end
				if bro then
					break
				end
			end
		end
	end
	return result
end
-- 检测一个path内，角色(单双格)是否踩中地雷并返回修改后的值:新path
function CBM:trapDetectResult(ro,gds,pathType,parabolic)
	local result = gds
	pathType = CALC_3(pathType==false,false,true)
	parabolic = checkbool(parabolic or false)
	if ro and next(gds) then
		if not ro:isFly() and not parabolic then
			local sti = 0
			if pathType then
				sti = 3
			else
				sti = 1
			end
			local step = sti
			for i=sti,#result do
				if self.mapData[result[i][1]][result[i][2]][1] < 0 then
					step = i
					break
				end
				if ro:getRoleVo().occupy == 2 and self.mapData[result[i][1]][result[i][2]+1][1] < 0 then
					step = i
					break
				end
			end
			local movcs = 0
			-- print(step,#result)
			if step < #result then
				for i=#result,step+1,-1 do
					movcs = movcs + self.mapData[result[i][1]][result[i][2]][3]
					table.remove(result)
				end
			end
			if pathType then
				result[1] = result[1] + movcs
			end
		end
	end
	return result
end
--- 返回角色身后的格子集合
function CBM:getBehindArea( ro,range,hollow,includeself,reverse )
	hollow = checknumber(hollow or 0)
	includeself = checkbool(includeself)
	local result = nil
	local inside = nil
	local index = 0
	local rvo = ro:getRoleVo()
	local dirbo = rvo.direct=="left"
	if checkbool(reverse) then dirbo = not dirbo end
	index = CALC_3(dirbo,4,1)
	local pos = CALC_3(rvo.occupy==1,{rvo.row,rvo.col},CALC_3(rvo.direct =="right",{rvo.row,rvo.col},{rvo.row,rvo.col+1})) 
	local presetclose,hollowline
	if index == 1 then
		inside = {pos[1],pos[2] - 1}
		presetclose = ASconcat(self:getaline(pos, 2, 0, range, true),self:getaline(pos, 6, 0, range, false))
		if hollow>0 then
			hollowline = ASconcat(self:getaline(pos, 2, 0, hollow, false),self:getaline(pos, 6, 0, hollow, false))
		end
	elseif index == 4 then
		inside = {pos[1],pos[2] + 1}
		presetclose = ASconcat(self:getaline(pos, 3, 0, range, true),self:getaline(pos, 5, 0, range, false))
		if hollow > 0 then
			hollowline = ASconcat(self:getaline(pos, 3, 0, hollow, false),self:getaline(pos, 5, 0, hollow, false))
		end
	end
	if self:isValidGrid(inside) then
		if hollow>0 then
			result = self:getshotArea({inside}, range-1, hollow-1, false, presetclose)
		else
			result = self:getshotArea({inside}, range-1, 0, true, presetclose)
		end
	else
		result = presetclose
	end
	if hollowline and next(hollowline) then
		result = nonIntersection2D(result,hollowline)
	end
	if not includeself then
		result = nonIntersection2D(result,{{ro:getRow(),ro:getCol()}})
	end
	return result
end
-- 得到一个无视地形的射程图,注意pos数组是二维数组，为了双格单位(起点，射程，中空，是否包含自身,预先设置closelist)
function CBM:getshotArea(pos,range,hollow,includeself,presetclose)
	self.starr = {}
	self.openlist = {}
	self.closelist = {}
	presetclose = checktable(presetclose)
	if next(presetclose) then
		self.closelist = presetclose
	end
	local limit = clone(self.closelist)
	local result = {}
	local hol = checkint(hollow or 0)
	local fran = range
	includeself = CALC_3(includeself==false,false,true)
	for i=1,#pos do
		Push(self.starr,pos[i])
	end
	self.openlist = clone(self.starr)
	local tmpar = {}
	local nextar = {}
	while fran>0 do
		for i=1,#self.openlist do
			tmpar = self:getAround(self.openlist[i], true)
			for j=1,#tmpar do
				uniqPush(nextar,tmpar[j])
			end
		end
		self.openlist = nextar
		for i=1,#nextar do
			self.closelist[#self.closelist+1] = nextar[i]
		end
		if hol>0 then
			hol = hol - 1
		else
			for i=1,#nextar do
				limit[#limit+1] = nextar[i]
			end
		end
		nextar = {}
		fran = fran - 1
	end
	if includeself then
		for i=1,#self.starr do
			limit[#limit+1] = self.starr[i]
		end
		result = limit
	else
		result = limit
	end
	return result
end
-- 返回一个对于该角色所能到达的范围的点集
function CBM:getMoveArea(arr,rolevo,mpReplaced,removeBarrier)
	self:destroyData()
	mpReplaced = checkint(mpReplaced or 0)
	removeBarrier = checkbool(removeBarrier or false)
	self:updateMapData(arr,rolevo,nil,removeBarrier)
	local result ={}
	local mp = rolevo.movepoint
	if mpReplaced ~= 0 then
		mp = mpReplaced;
	end
	if rolevo.haltednum > 0 then
		mp = 0
	end
	if rolevo.occupy == 1 then
		Push(self.starr,{rolevo.row,rolevo.col})
	elseif rolevo.occupy == 2 then
		Push(self.starr,{rolevo.row,rolevo.col})
		Push(self.starr,{rolevo.row,rolevo.col+1})
	end
	self.openlist = clone(self.starr)
	for i=1,#self.openlist do
		local newarr = {mp,self.openlist[i]};
		Push(self.allpath,newarr)
	end

	local tmpar = {}
	local nextar = {}
	local opls = self.openlist
	local isflybo = rolevo.flynum>0 or (rolevo.flynum == 0 and rolevo.fly_default)
	while #opls > 0 do
		for i=1,#opls do
			-- print("开始寻路")
			tmpar = self:getAround(opls[i], isflybo)
			self:xujie(self.allpath, opls[i], tmpar, rolevo.occupy)
			for j=1,#tmpar do
				if self:IsXujieAble(tmpar[j]) then
					uniqPush(nextar,tmpar[j])
				end
			end
		end
		opls = nextar
		for i=1,#nextar do
			self.closelist[#self.closelist+1] = nextar[i]
		end
		nextar = {}
	end
	if isflybo then
		self.closelist = self:ridOfImpassable(self.closelist)
	end
	for i=1,#self.starr do
		self.closelist[#self.closelist+1] = self.starr[i]
	end
	result = self.closelist
	-- print(os.difftime(t2, t1),os.difftime(t3, t2),os.difftime(t4, t3),os.difftime(t5, t4))
	-- dump(self.mapData)
	-- dump(self.allpath)
	return result
end
-- 返回一条剩余行动力最多的路径(最易到达)，参数（目的地，左右偏移量，左负右正）返回形式[剩余行动力，起点，后续坐标点...] plural返回所有可能路径
function CBM:getPath(des,offset,plural)
	local result = {}
	local paths = {}
	local mvn = {}
	offset = checkint(offset or 0)
	plural = checkbool(plural or false)
	for i=1,#self.allpath do
		local elem = self.allpath[i]
		if elem[#elem][1] == des[1] and elem[#elem][2] == des[2] then
			Push(paths,elem)
		end
	end
	table.sort(paths,Sort2Dimen)
	result = paths[#paths]
	-- 路径的左右偏移量，通常提供给两格单位使用
	if offset ~= 0 then
		for i=2,#result do
			result[2] = result[2] + offset
		end
	end
	if plural then
		result = paths
	end
	return result
end
function CBM:getAround(apos,ignpass,ignStartCloselist)
	ignpass = checkbool(ignpass)
	ignStartCloselist = checkbool(ignStartCloselist)
	local result = {}
	local Dir = CALC_3(apos[1]%2~=0,self.aDir,self.bDir)
	for i=1,#Dir do
		local xp = apos[1] + Dir[i][1]
		local yp = apos[2] + Dir[i][2]
		if self:IsOutRange({xp,yp}) or (not ignpass and not self:IsPass({xp,yp})) or not ignStartCloselist and (self:IsStart({xp,yp}) or self:IsInClose({xp,yp})) then
				
		else
			Push(result,{xp,yp})
		end
		-- if not ignpass then
		-- 	if self:IsOutRange({xp,yp}) or self:IsStart({xp,yp}) or not self:IsPass({xp,yp}) or self:IsInClose({xp,yp}) then
				
		-- 	else
		-- 		Push(result,{xp,yp})
		-- 	end
		-- else
		-- 	if self:IsOutRange({xp,yp}) or self:IsStart({xp,yp}) or self:IsInClose({xp,yp}) then
				
		-- 	else
		-- 		Push(result,{xp,yp})
		-- 	end
		-- end
	end
	return result
end
--- 注意，for循环动态添加元素至table末尾可导致长度不断增加，无法结束循环
function CBM:xujie(arr,s,ra,occupy)
	occupy = checkint(occupy or 1)
	local newpaths = {}
	for i=1,#arr do
		if arr[i][#arr[i]][1] == s[1] and arr[i][#arr[i]][2] == s[2] then
			-- print(#arr,"剩余行动力"..arr[i][1])
			if arr[i][1] <= 0 then
				
			else
				for j=1,#ra do
					local newar = clone(arr[i])
					local cost = self.mapData[ra[j][1]][ra[j][2]][3]
					local aft = newar[1] - cost
					local bo = true
					-- 占两格的单位，需要判断：如果起始格为左边，则判断每一步的右边是否可通过，反之亦然；
					if occupy == 2 then
						if arr[j][2][1] == self.starr[1][1] and arr[j][2][2] == self.starr[1][2] then
							if not self.mapData[ra[j][1]][ra[j][2] + 1][2] then
								bo = false
							end
						elseif arr[j][2][1] == self.starr[2][1] and arr[j][2][2] == self.starr[2][2] then
							if not self.mapData[ra[j][1]][ra[j][2] - 1][2] then
								bo = false
							end
						end
					end
					if bo and aft >= -1 then
						newar[1] = aft
						Push(newar,ra[j])
						Push(newpaths,newar)
					end
				end
			end
		end
	end
	-- self.allpath = ASconcat(arr,newpaths) 替换为下
	for i=1,#newpaths do
		self.allpath[#self.allpath+1] = newpaths[i]
	end
end

function CBM:IsXujieAble( tail )
	-- print("tail is ",unpack(tail))
	for i=1,#self.allpath do
		-- print(dump(self.allpath[i]),#(self.allpath[i]))
		if self.allpath[i][#self.allpath[i]][1] == tail[1] and self.allpath[i][#self.allpath[i]][2] == tail[2] then
			return true
		end
	end
	return false
end

function CBM:ridOfImpassable( gds )
	local result = {}
	local dd
	if next(gds) ~= nil then
		while #gds > 0 do
			dd = table.remove(gds)
			if self.mapData[dd[1]][dd[2]][2] then
				Push(result,dd)
			end
		end
	end
	return result
end

function CBM:IsOutRange( apos )
	if apos[1] < 1 or apos[1] > self.rows or apos[2] < 1 or apos[2] > self.cols then
		return true
	end
	return false
end
function CBM:IsStart( apos )
	for i=1,#self.starr do
		if apos[1] == self.starr[i][1] and apos[2] == self.starr[i][2] then
			return true
		end
	end
	return false
end
function CBM:IsPass( apos )
	if self:IsOutRange(apos) then
		return false
	else
		return self.mapData[apos[1]][apos[2]][2]
	end
end
function CBM:IsInClose( apos )
	local bo = false
	for i=1,#self.closelist do
		if apos[1] == self.closelist[i][1] and apos[2] == self.closelist[i][2] then
			bo = true
			break
		end
	end
	return bo
end
--- 伪A星寻路(不考虑通过代价，只选择最近的路线)
-- function CBM:astarPath(startpos,endpos)
-- 	local openlist = {}
-- 	local closelist = {startpos}
	
-- 	local pt2 = self:getPos(endpos[1],endpos[2])
-- 	local dis = {}
-- 	for j=1,self.rows+sel.cols do
-- 		local tmpar = self:getAround(startpos)
-- 		for i=1,#tmpar do
-- 			local pt1 = self:getPos(tmpar[i][1], tmpar[i][2])
-- 			dis[#dis+1] = {cc.pGetDistance(pt1, pt2),tmpar[i]}
-- 		end
-- 		table.sort(dis,Sort2Dimen)
-- 		if isEqual(dis[1][2],endpos) then
-- 			return closelist
-- 		end
-- 		local distm = self:getAround(dis[1][2])
-- 		if #distm>0 then
-- 			Push(closelist,dis[1][2])
-- 		end
-- 	end
-- end
-- 对于多个目标点，找到剩余行动力最多(或最小)的一点，并返回到达的路径
function CBM:optimalPath(arr,maxMpRemain)
	local daxiao = {}
	local paths = {}
	maxMpRemain = CALC_3(maxMpRemain==false,false,true)
	for i=1,#arr do
		local np = self:getPath(arr[i])
		Push(paths,np)
	end
	table.sort(paths,Sort2Dimen)
	if maxMpRemain then
		return paths[#paths]
	else
		return paths[1]
	end
end

-- 检查ro1是否在ro2的角色攻击范围之内
function CBM:isInFireRange(ro1,ro2)
	local bo = false
	local pos_2 = occupy1or2(ro2)
	local sa = self:getshotArea(pos_2,ro2:getRoleVo().firerange,ro2:getRoleVo().hindrance,false)
	local pos_1 = occupy1or2(ro1)
	local cross = intersection2D(pos_1,sa)
	if next(cross) then
		bo = true
	end
	return bo
end
-- 得到两个格子间真正的数值距离
function CBM:realDistance(gd1,gd2)
	local pt1 = self:getPos(gd1[1], gd1[2])
	local pt2 = self:getPos(gd2[1], gd2[2])
	return cc.pGetDistance(pt1, pt2)
end
-- 清空各数组
function CBM:destroyData()
	self.openlist = {}
	self.closelist = {}
	self.starr = {}
	self.allpath = {}
	self.mapData = {}
end

function CBM:reset()
	self.rpvect = {}
	self.rpcenter = {}
	self:destroyData()
	CBM.sceneobj = {}
end

return CBM