-- module setup
local M = {}

-- Import Section
local pow=math.pow
local huge=math.huge
local abs=math.abs
local ceil=math.ceil
local mini=math.min
local sort=table.sort
local print=print
local pairs=pairs
local next=next

-- Local Variables for module-only access
local tolerance=1e-3

-- No more external access after this point
_ENV = nil -- or M

-- Function definitions
-- Public function definitions

function M.similarity(points,dfun)
    local size = #points
    local sims = {}
    
    for i=1,size do
        sims[i] = {}
    end
    
    for i=1,size do
        for j=i+1,size do
            local d = dfun(points[i], points[j])
            sims[i][j] = -d  -- similarity is negative of distance metric
            sims[j][i] = -d
        end
    end
    
    return sims
end

function M.similarities(points,dfun)
    local size = #points
    local sims = {}
    
    for i=1,size do
        sims[i] = {}
    end
    
    for i=1,size do
        for j=i+1,size do
            sims[i][j] = -dfun(points[i], points[j])  -- similarity is negative of distance metric
            sims[j][i] = -dfun(points[j], points[i])
        end
    end
    
    return sims
end

-- Method's function definitions

function M.extrema(sims)
    local ret = {}
    
    for _,v in pairs(sims) do
        for _,vv in pairs(v) do
            ret[#ret+1] = vv
        end
    end

    local N = #ret
    
    sort(ret)
    
    local mdn = N%2==1 and ret[ceil(N/2)] or (ret[N/2]+ret[N/2+1])/2

    return {size=N, min=ret[1], max=ret[N], median=mdn}
end

function M.euclidean(x,y)
  local ssq = 0.0
  
  for i,v in pairs(x) do
    ssq = ssq + (y[i] and pow(v-y[i],2) or 0)  -- allow for sparse vectors
  end
  
  return ssq
end

function M.taxicab(x, y)
  local sum=0
  
  for i,v in pairs(x) do
    sum = sum + (y[i] and abs(v - y[i]) or 0)  -- allow for sparse vectors
  end
  
  return sum
end

function M.intersection(x, y)
    local sum=0
    local xsum=0
    
    for i,v in pairs(x) do
        sum = sum + (y[i] and mini(v,y[i]) or 0)  -- allow for sparse vectors
        xsum = xsum + v
    end
    
    --print(sum,xsum)
    
    return 1-sum/xsum
end

function M.bintersection(x,y)
    local sum = 0
    local xsum = 0
    
    for i,_ in pairs(x) do
        sum = sum + (y[i] and 1 or 0)
        xsum = xsum + 1
    end
    
    return 1-sum/xsum
end

return M
