require('sugar');

local Q = T {};

function Q:peek() 
    return Q[self.front];
end

function Q:push(value)
    Q[self.back] = value;
    self.back = self.back + 1;
end

function Q:pop()
    local val = Q[self.front];
    Q[self.front] = nil;
    self.front = self.front + 1;

    return val;
end

function Q:isEmpty()
    return self.front == self.back;
end

return function(t)
    t.front = 1;
    t.back = #t + 1;

    return setmetatable(t, { __index = Q });
end

