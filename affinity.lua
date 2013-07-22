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
local infinity=huge

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
  local lambda = 0.8
  local similarities={}
  local indices={}
  local availabilities={}
  local responsabilities={}
  local RA={}

  infinity = inf or infinity

  -- initialize the similarity and index matrices
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
    local ret = {}
    
    for k,v in pairs(similarities) do
      ret[k] = v
    end

    sort(ret)
    local N = #ret+1
    local pref = ret[floor(N/2)] -- preference set to median
    similarities[N] =  pref -- add preference at end of similarity matrix

    for i=1,size do
      indices[i][i] = N -- add index of preference to matrix
    end

    print("\nNumber of valid similarities: " .. N .. "\n")
    print("Median similarity: " .. pref)
    print("Minimum similarity: " .. ret[1])
    print("Maximum similarity: " .. ret[N-1])
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

  local function send_responsability(i)

    local sims = {}
    local max = -huge
    local ind
    local ret

    -- find cluster k that maximize a+s
    for k,v in pairs(indices[i]) do
      local sim = similarities[v]
      sims[k] = sim
      local as = availabilities[i][k]+sim
      if as > max then
	ret = max
	max = as
	ind = k
      end
    end
    
    -- update: input similarity minus largest of a+s
    for k,ss in pairs(sims) do
      responsabilities[k][i] = responsabilities[k][i]*lambda + (1-lambda)*(ss - (k~=ind and max or ret))
    end

    return true
  end


  local function send_availability(k)
  
    local sum = 0
    local rp = {}

    -- sum of positive responsability exemplar k receives from i's
    for i,r in pairs(responsabilities[k]) do
      local rr = k~=i and maxi(r,0) or r -- except for self-responsability
      rp[i] = rr
      sum = sum + rr
    end

    -- update: limit strong influence of incoming positive responsability
    for i,r in pairs(rp) do
      local a = k~=i and mini(sum-r, 0) or sum-r -- except for self-availability
      availabilities[i][k] = availabilities[i][k]*lambda + (1-lambda)*a
    end

    return true
  end

  -- public function definitions
  
  function RA.step()
    for i=1,size do
      send_responsability(i)
    end

    for k=1,size do
      send_availability(k)
    end

    return true
  end

  function RA.convergence()
    local cts={}

    for i=1,size do
      if (responsabilities[i][i]+availabilities[i][i])>0 then
	cts[#cts+1] = i
      end
    end

    return cts
  end
  
  function RA.assignment()
    local ret = {}
    local cts = {}
    
    -- identify centers
    for i=1,size do
      if (responsabilities[i][i]+availabilities[i][i])>0 then
	cts[#cts+1] = i
      end
    end

    for i=1, size do
      local max = -huge
      local idx = -1
      
      -- find center k that maximize r+a
      for c,k in pairs(cts) do
	  local ra = responsabilities[i][k]+availabilities[i][k]
	  if ra > max then
	    max = ra
	    idx = c
    	  end
	end

      ret[i] = idx
    end

    return ret
  end

  return RA
end

return M
