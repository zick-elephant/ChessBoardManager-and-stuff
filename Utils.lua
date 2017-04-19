--
-- Author: zick_elephant
-- Date: 2015-12-14&H:31:04
--
---三元运算符
CALC_3 = function(exp, result1, result2) if(checkbool(exp))then return result1; else return result2; end end

--- 三维数组，按每个元素里第一个table的长度来排序
Sort3Dimen = function (a,b) return #a[1] < #b[1] end
--- 按table里的每一项的[1](二维)的大小来排序，升序  param:排序table,每一项中的第1个
Sort2Dimen = function ( a,b ) return a[1] < b[1] end

Sort2DEnd = function ( a,b ) return a[#a] < b[#b] end

SortPriority = function ( a,b ) return a:getPriority() < b:getPriority() end
-- 按每个Node的Y值进行排序
SortPosY = function (a,b)
	return a:getPositionY() > b:getPositionY()
end
-- 按每个Node的wipemark排序
SortWipe = function (a,b) return a.wipemark < b.wipemark end

-- 随机乱序数组(lua里的sort并不可用，排序不稳定，无法用来快速排序)
SortRandom = function ( a,b )
	return math.random()>0.5
end
--洗牌算法，用于将一组数据等概率随机打乱。等概率算法。
ShuffleFunc = function (t)
	if not t then print("Shuffle里的table为空") return end
	local cnt = #t
	for i=1,cnt do
		local j = math.random(i,cnt)
		t[i],t[j] = t[j],t[i]
	end
end
--- indexof查看元素在table里的索引，如果无则返回-1(注意索引不要使用-1,混淆)
IndexOf = function ( tbl,elem )
	local result = -1
	if next(tbl) ~= nil and elem ~= nil then
		for k,v in pairs(tbl) do
			if v == elem then
				return k
			end
		end
	end
	return result
end
--- AS 里的数组push操作
Push = function (tbl,elem,...)
	tbl[#tbl + 1] = elem
	for i=1,#arg do
		tbl[#tbl + 1] = arg[i]
	end
end
--- 查看两个非空table的元素是否全都k,v相同,位置索引也相同
isEqual = function (tbl1,tbl2)
	local bo = false
	if tbl1 and tbl2 and next(tbl1) ~= nil and next(tbl2) ~= nil then
		bo = true
		for k,v in pairs(tbl1) do
			if tbl2.k ~= v then
				bo = false
				break
			end
		end
	end
	return bo
end
--- 唯一添加 i数组(二维数组)操作,返回boolean，true表示成功添加，false为不成功，即非Unique或有table为空
uniqPush = function ( tbl,elem )
	for i=1,#tbl do
		if elem[1] == tbl[i][1] and elem[2] == tbl[i][2] then
			return false
		end
	end
	tbl[#tbl + 1] = elem
	return true
end
--- 将后一个数组的全部元素插入到tbl1的末尾，相当于AS的concat ，返回修改后的结果副本（注意！），不改变原数组
ASconcat = function ( tbl1,tbl2,... )
	local result = clone(tbl1)
	-- for k,v in pairs(tbl2) do
	-- 	result[#result + 1] = v
	-- end
	for i=1,#tbl2 do
		result[#result + 1] = tbl2[i]
	end
	for i=1,#arg do
		for j=1,#arg[i] do
			result[#result + 1] = arg[i][j]
		end
	end
	return result
end
-- 得到两个二维数组的无重复合集(ar1和ar2不可为null)
combine2D = function (ar1,ar2)
	local result = {}
	if ar1 and ar2 then
		result = CALC_3(#ar1>0,ar1,ar2)
		if #ar1>0 and #ar2>0 then
			for i=1,#ar2 do
				uniqPush(result,ar2[i])
			end
		end
	end
	return result
end


-- 找出两个二维数组中值相同的交集
intersection2D = function (ma,sa)
	local result = {}
	if ma and next(ma) and sa and next(sa) then
		for i=1,#sa do
			for j=1,#ma do
				if ma[j][1] == sa[i][1] and ma[j][2] == sa[i][2] then
					Push(result,sa[i])
				end
			end
		end
	end
	return result
end

-- 查看一个点(一维)是否在另一个点集数组(二维)当中，是intersection功能的简化版
contain2D = function (gd,gds)
	if gd and gds and next(gd) and next(gds) then
		for i=1,#gds do
			if gd[1] == gds[i][1] and gd[2] == gds[i][2] then
				return true
			end
		end
	end
	return false
end

-- 取两个二维数组的非交集
nonIntersection2D = function (ma,sa)
	local result = {}
	if ma and sa then
		for i=1,#ma do
			if not contain2D(ma[i],sa) then
				Push(result,ma[i])
			end
		end
		for i=1,#sa do
			if not contain2D(sa[i],ma) then
				Push(result,sa[i])
			end
		end
	end
	return result
end
--- 返回倒序数组副本，不影响原数组
ReverseTable = function ( tbl )
	local result = {}
	for i=#tbl,1,-1 do
		result[#result + 1] = tbl[i]
	end
	return result
end
-- 按照字符长度返回字号大小
GetSizeByLength = function ( str )
	local off = CALC_3(device.model == "ipad",-4,0)
	if string.len(str)<=10 then
		return 20
	elseif string.len(str) <= 20 then
		return 18+off
	else
		return 16+off
	end
end
-- 用英文作为备用语
BackUpTrans = function (index1,index2,index3)
	local str
	if index1 and index2 then
		if index3 then
			if GameData.translation[index1][index2][index3] then
				str = GameData.translation[index1][index2][index3]
			else
				str = Translation_English[index1][index2][index3]
			end
		else
			if GameData.translation[index1][index2] then
				str = GameData.translation[index1][index2]
			else
				str = Translation_English[index1][index2]
			end
		end
	end
	if not str then
		str = ""
	end
	return str
end

-- 从1到maxNum中取一个长度为len的不重复随机整数数组
UnRepeatRandomNum = function (len,maxNum)
	local result ={}
	local arr = {}
	for i=1,maxNum do
		arr[#arr+1] = i
	end
	if len <= maxNum then
		ShuffleFunc(arr)
		for i=1,len do
			result[#result+1] = arr[i]
		end
	else
		print("长度超出最大数--UnRepeatRandomNum")
	end
	return result
end

OddJudge = function (odd)
	if odd <= 0 then
		return false
	end
	local bo = math.random()*100 < odd
	return bo
end

RemindOn = function (str,stage,diffPosition)
	local txt = cc.ui.UILabel.new({UILabelType = 2,text = str,size = 20,color = cc.c3b(255, 255, 255),align = cc.TEXT_ALIGNMENT_CENTER})
	txt:setAnchorPoint(cc.p(0.5, 0))
	txt:addTo(stage,999,999)
	txt:enableOutline(cc.c4b(255,125,0,255),6)
	if diffPosition then
		txt:setPosition(diffPosition.x, diffPosition.y)
	else
		txt:center()
	end
	local fade = cc.FadeOut:create(4)
	local callback = cc.CallFunc:create(function ( txt )
		txt:removeFromParent()
		-- print("淡出结束，查找目标txt:",self.stage_:getChildByTag(999))
	end)
	local seq = cc.Sequence:create(fade,callback)
	txt:runAction(seq)
end