-- module setup
local M = {}

-- Import Section
local random=math.random
local floor=math.floor
local flines=io.lines
local gmatch=string.gmatch
local unpack=table.unpack

-- Local Variables for module-only access

-- No more external access after this point
_ENV = nil -- or M

-- Function definitions

-- shuffle returns a vector of #(m or size) indices in random order
local function shuffle(size, m)
  local indices = {}
  local j

  for i=1, m or size do
    j = random(i, size-i+1)  -- taken from libsvm file: svm.cpp || size
    indices[i], indices[j] = indices[j] or j, indices[i] or i
  end

  return m and {unpack(indices, 1, m)} or indices
end

-- random sample returns #(m or points) in random order (shuffled)
function M.sample(points, m)
  local ans = {}
  local size = #points
  local indices = shuffle(size, m)

  for i=1, m or size do
    ans[i] = points[indices[i]]
  end

  return ans
end

local function match(s,p)
  local ans={}

  for w in gmatch(s,p) do
    ans[#ans+1]=w
  end

  return ans
end

-- open a file and reads all lines into a table
function M.slurp(fname,pattern)
  local ret={}
  local p=pattern or "(-?%d+.%d+)" -- numbers

  for line in flines(fname) do
    ret[#ret+1]=match(line,p)
  end

  return ret
end

return M
