-- module setup
local M = {}

-- Import Section
local pow=math.pow
local huge=math.huge
local maxi=math.max
local mini=math.min
local floor=math.floor
local pairs=pairs
local sort=table.sort
local print=print

-- Local Variables for module-only access
local infinity=1e3

-- No more external access after this point
_ENV = nil -- or M

-- Function definitions

local function euclidean(x,y)
  local ssq = 0.0
  
  for i,v in pairs(x) do
    ssq = ssq + y[i] and pow(v-y[i],2) or 0  -- allow for sparse vectors
  end
  
  return ssq
end

local function distance(x,y)
  local d = euclidean(x,y)
  
  return d < infinity and -d or nil -- sparse matrix: distances greater than infinity are not considered
end

function M.distance_matrix(points, inf)
  local size = #points
  local lambda = 0.5
  local similarities={}
  local indices={}
  local availabilities={}
  local responsabilities={}
  local RA={}

  infinity = inf or infinity

  -- initialize the similarity and index matrix
  do
    for i=1, size do
      indices[i] = {}
    end

    local cnt=0
    for i=1, size do
      for j=1+i, size do
        local d = distance(points[i],points[j])
        if d then
	  cnt=cnt+1
	  similarities[cnt] = d
	  indices[i][j] = cnt
	  indices[j][i] = cnt
        end
      end
    end
  end

  -- initialize preference
  do
    local ret={}
    
    for k,v in pairs(similarities) do
      ret[k] = v
    end

    sort(ret)
    local  preference = ret[floor(#ret/2)]
    similarities[#ret+1] = preference

    for i=1,size do
      indices[i][i] = #ret+1
    end

    print("\nNumber of valid similarities: " .. #ret .. "\n")
    print("Median preference: " .. preference .. "\n")
  end

  -- initialize availabilities and responsabilities
  for i=1,size do
    availabilities[i] = {}
    responsabilities[i] = {}
    for j,_ in pairs(indices[i]) do
      responsabilities[i][j] = 0
      availabilities[i][j] = 0
    end
  end

  -- local function definitions

  local function update_responsability(i)

    local idxs = indices[i]
    local min = huge
    local ind
    local ret

    for k,v in pairs(idxs) do
      local as = similarities[v]+availabilities[i][k]
      if as > min then
	ret = min
	min = as
	ind = k
      end
  end
    
    -- update
    for j,v in pairs(idxs) do
      responsabilities[j][i] = responsabilities[j][i]*lambda + (1-lambda)*(similarities[v] - (j~=ind and min or ret))
    end

    return true
  end


  local function update_availability(j)
  
    local sum = 0
    local rp = {}

    for k,v in pairs(responsabilities[j]) do
      local r = k~=j and maxi(v,0) or v -- threshold except for self-responsability
      rp[k] = r
      sum = sum + r
    end

    -- update
    for i,v in pairs(rp) do
      local a = j~=i and mini(sum-v, 0) or sum-v -- threshold except for self-availability
      availabilities[i][j] = availabilities[i][j]*lambda + (1-lambda)*a
    end

    return true
  end

  local function convergence()
    local cts={}

    for i=1,size do
      if (responsabilities[i][i]+availabilities[i][i])>0 then
	cts[#cts+1] = i
      end
    end

    return cts
  end

  -- public function definitions
  
  function RA.step()
    for i=1,size do
      update_responsability(i)
    end

    for j=1,size do
      update_availability(j)
    end

    return convergence()
  end

  function RA.assignment(cts)
    local ret={}

    for i=1, size do
      local max=-huge
      local idx=-1

      for k,v in pairs(responsabilities[i]) do
	  local ra = v+availabilities[i][k]
	  if ra > max then
	    max = ra
	    idx = k
    	  end
	end

      ret[i] = idx
    end

    return ret
  end

  return RA
end

return M
