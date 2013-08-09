-- module setup
local M = {}

-- Import Section
local huge=math.huge
local maxi=math.max
local mini=math.min
local concat=table.concat
local pairs=pairs
local print=print

-- Local Variables for module-only access
local lambda=0.8

-- No more external access after this point
_ENV = nil -- or M

-- Function definitions

local function propagation(similarities, availabilities, responsabilities)
  
    local MM = {}
  
    -- Private function definitions --
  
    local function send_responsabilities()
        for i,v in pairs(similarities) do
            -- find cluster k that maximize a+s        
            local max = -huge
            local ind = -1
            local max2 = -huge
            
            --print('Start:',i)
            
            for k,s in pairs(v) do
                local as = availabilities[i][k]+s
                if availabilities[k] == nil then print(k) end
                if as >= max2 then
                    max2 = as
                    if as > max then
                        max2 = max
                        max = as
                        ind = k
                    end
                end
            end
            
            --print(i,ind)
            
            -- update responsabilities
            for k,s in pairs(v) do
                responsabilities[k][i] = responsabilities[k][i]*lambda + (1-lambda)*(s - (k~=ind and max or max2))
            end
            
            --print('Done:',i)
        end
        
        return true
    end
    
    local function send_availabilities()
        for k,v in pairs(responsabilities) do
            -- sum positive responsabilities exemplar k receives from i's
            local sum = 0
            local rp = {}
            
            for i,r in pairs(v) do
                local rr = k~=i and maxi(r,0) or r -- except for self-responsability
                rp[i] = rr
                sum = sum + rr
            end
            
            -- update availability of center k to i's; limit strong influence of incoming positive responsability
            for i,r in pairs(rp) do
                local a = k~=i and mini(sum-r, 0) or (sum-r) -- except for self-availability
                availabilities[i][k] = availabilities[i][k]*lambda + (1-lambda)*a
            end
        end
        
        return true
    end
  
    -- Method definitions --

    function MM.responsability(i,j)
        return responsabilities[i][j]
    end
    
    function MM.constants()
        print('Damping/lambda:',lambda)
        print('Preference:',similarities[1][1])  -- assume share preference
        return true
    end
  
    function MM.step()
        send_responsabilities()
        send_availabilities()
        return true
    end

    function MM.assignment()
    --    local ret = {}
        local exps = {}  -- exemplars k
        local pts = {}  -- points i
        local spexp = 0  -- similarity of points to exemplars
        local expref = 0  -- exemplar preference sum
    
        -- identify centers
        for i,ss in pairs(similarities) do
            if (responsabilities[i][i]+availabilities[i][i])>0 then
                exps[#exps+1] = i
               expref = expref + ss[i]  -- center preference/self-similarity
    --            ret[i] = #exps  -- save assignment
            else
                pts[#pts+1] = i
            end
        end

        if #exps>0 then
            -- find most similar exemplar k to each point i
            for _,i in pairs(pts) do
                local max = -huge
                local idx = -1
                
                for c,k in pairs(exps) do
                    local s = similarities[i][k] or -huge
                    if s > max then
                        max = s
                        idx = c
                    end
                end
    
                if max==-huge then print(i) end  -- DEBUG
                
                spexp = spexp + max  -- add similarity to sum
    --            ret[i] = idx  -- save center assignment
            end
    
            print(concat(exps,', '))
            print('Clusters found:', #exps)
            print('Fitness/Net similarity:\n\t', expref+spexp)
            print('Similarity of data points to exemplars:\n\t', spexp)
            print('Exemplar preference:\n\t', expref)
        else
            print('No clusters found!\n')
        end
    
        return exps, spexp, expref
    end

  return MM
end

function M.cluster(exemplars, points, fdis)
    local ret = {}
    
    for i,h in pairs(points) do
        local max = -huge
        local idx = -1
        
        for k,hh in pairs(exemplars) do
            local s = -fdis(h,hh)
            if s > max then
                max = s
                idx = k
            end
        end
        
        if max==-huge then print(i) end  -- DEBUG
        ret[i] = idx  -- save center assignment 
    end
    
    return ret
end

-- Public function definitions

function M.initialize(similarities, preference, damping)
    local availabilities={}
    local responsabilities={}

    lambda = damping or lambda
    
    -- initialize preferences
    for i,v in pairs(similarities) do
        similarities[i][i] = preference
    end
    
    -- initialize availabilities and responsabilities
    for i,v in pairs(similarities) do
        availabilities[i] = {}
        responsabilities[i] = {}
        for j,s in pairs(v) do
            responsabilities[i][j] = 0
            availabilities[i][j] = 0
        end
    end
      
  return propagation(similarities, availabilities, responsabilities)
end

return M
