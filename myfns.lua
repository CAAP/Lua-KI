-- module setup
local M = {}

-- Import Section
local huge=math.huge
local maxi=math.max
local mini=math.min
local sqrt=math.sqrt
local concat=table.concat
local pairs=pairs
local print=print
local next=next

-- Local Variables for module-only access

-- No more external access after this point
_ENV = nil -- or M

-- Function definitions

local function maximal(points)
    local max = -huge
    local ind = -1
    local max2 = -huge
    
    for k,v in pairs(points) do
        if v>=max2 then
            max2=v
            if v>max then
                max2=max
                max=v
                ind=k
            end
        end
    end
    
    return max,ind,max2
end

--local pts={}
--assert(maximal(pts) == -huge,-1,-huge)
--pts={9}
--assert(maximal(pts) == 9,1,-inf)
--pts={9,9}
--assert(maximal(pts) == 9,1,9)
--pts={10,4,6,2,9,1,2,4,5,6,8,2,19}
--assert(maximal(pts) == 19,13,10)
--pts={4,6,2,9,1,2,4,5,6,8,2,9}
--assert(maximal(pts) == 9,4,9)
--pts={10,4,6,2,9,1,2,4,5,6,8,2,19}
--assert(maximal(pts) == 19,13,10)

local function addition(points,max,ind,max2)
    local ret = {}
    
    for k,v in pairs(points) do
        ret[k] = v + (k~=ind and max or max2)
    end

    return ret
end

local function positivity(points,except)
    local ps = {}
    local sum = 0
    local sum2 = 0
    
    for k,v in pairs(points) do
        local p = k~=except and maxi(v,0) or v
        ps[k] = p
        sum = sum + p
    end
    
    for _,v in pairs(ps) do
        sum2 = sum2+v
    end

    print('Result:',concat(ps,', '))
    print('Sums:',sum,sum2)
    
    return ps,sum,sum2
end

local function same(x,y)
    local ans = true
    local cx,cy = 0,0
    
    --for _ in pairs(y) do
    --    cy = cy + 1
    --end
    --
    --for _ in pairs(x) do
    --    cx= cx + 1
    --end
    --
    --ans = cx==cy
    
    if ans then
        for i,_ in pairs(x) do
            if not(y[i]) then
                ans = false
                break
            end
        end
    end

    return ans
end

function M.unique(histos)
    local ret = {}
    local uqs = {}
    local all = {}
    
    for i,k in pairs(histos) do
        ret[i] = k
    end
    
    local i,h = next(ret)
    while h do
        uqs[#uqs+1] = i
        all[i] = i
        ret[i] = nil
        for j,v in pairs(ret) do
            if same(h,v) then
                ret[j] = nil
                all[j] = i
            end
        end
        
        i,h = next(ret)
    end
    
    return uqs, all
end

function M.bhistogram(points)
    local ret = {}
    
    for i,kk in pairs(points) do
        local h = {}
        
        for _,k in pairs(kk) do
            h[k] = true
        end
        
        ret[i] = h
    end
    
    return ret
end

function M.histogram(points)
    local ret = {}
    
    for i,kk in pairs(points) do
        local h = {}
        
        for _,k in pairs(kk) do
            h[k] = (h[k] or 0) + 1
        end
        
        ret[i] = h
    end
    
    return ret
end

function M.stats(points)
    local ret = {}
    
    for ii,v in pairs(points) do
        local cnt = #v
        local sum = 0
        local sumsq = 0
        
        for _,x in pairs(v) do
            sum = sum + x
            sumsq = sumsq + x*x
        end
        
        local mean = sum/cnt
        ret[ii] = {mean, sqrt(sumsq/cnt-mean*mean)}
    end
    
    return ret
end

M.same=same
M.maximal=maximal
M.addition=addition
M.positivity=positivity

return M