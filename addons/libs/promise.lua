local promise = {};

function promise:resolve(...)
    if (self._resolved) then
        error('Promise cannot be resolved more than once');
    end
    if (self._rejected) then
        error('Promise cannot be resolved once rejected.');
    end

    self._resolved = true;

    self._args = T { ... }; -- Save these for later, in case someone tries to use after resolved

    for _, cb in ipairs(self._resolveCb) do
        cb(...);
    end

    -- Clear pending callbacks
    self._rejectCb = {};
    self._resolveCb = {};
end

function promise:reject(...)
    if (self._resolved) then
        error('Promise cannot be rejected once resolved.');
    end
    if (self._rejected) then
        error('Promise cannot be rejected more than once');
    end

    self._rejected = true;

    self._args = T { ... };

    for _, cb in ipairs(self._rejectCb) do
        cb(...);
    end

    -- Clear pending callbacks
    self._rejectCb = {};
    self._resolveCb = {};
end

function promise:andThen(onSuccess)
    local res = promise:new();

    if (self._resolved) then
        res:resolve(onSuccess(self._args:unpack()));
    elseif (self._rejected) then
        res:reject(self._args:unpack());
    else
        self._resolveCb:append(function(...)
            onSuccess(...);
            res:resolve(...);
        end);
        self._rejectCb:append(function(...)
            res:reject(...);
        end)
    end

    return res;
end

function promise:orElse(onFailure)
    local res = promise:new();

    if (self._rejected) then
        onFailure(res:reject(self._args:unpack()));
    elseif (self._resolved) then
        res:resolve(self._args:unpack());
    else
        self._resolveCb:append(function(...)
            res:resolve(...);
        end);
        self._rejectCb:append(function(...)
            onFailure(...);
            res:reject(...);
        end)
    end

    return res;
end

function promise:new()
    return setmetatable(
        {
            _args = T {},
            _rejectCb = T {},
            _resolveCb = T {}
        },
        {
            __index = promise
        });
end

return promise;
