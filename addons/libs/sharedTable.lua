local ffi = require("ffi")
local mp = require("MessagePack")

ffi.cdef [[
    void* CreateFileMappingA(void* hFile, void* lpAttributes, unsigned long flProtect,
                             unsigned long dwMaxSizeHigh, unsigned long dwMaxSizeLow,
                             const char* lpName);
    void* OpenFileMappingA(unsigned long dwDesiredAccess, int bInheritHandle, const char* lpName);
    void* MapViewOfFile(void* hFileMappingObject, unsigned long dwDesiredAccess,
                        unsigned long dwFileOffsetHigh, unsigned long dwFileOffsetLow,
                        size_t dwNumberOfBytesToMap);
    int UnmapViewOfFile(void* lpBaseAddress);
    int CloseHandle(void* hObject);
    void* CreateMutexA(void* lpMutexAttributes, int bInitialOwner, const char* lpName);
    int ReleaseMutex(void* hMutex);
    int WaitForSingleObject(void* hHandle, unsigned long dwMilliseconds);
    void* memcpy(void* dest, const void* src, size_t count);
    void* memset(void* dest, int c, size_t count);
    unsigned long GetLastError();
    void* GetCurrentProcess();
    int DuplicateHandle(void* hSourceProcessHandle, void* hSourceHandle,
                        void* hTargetProcessHandle, void** lpTargetHandle,
                        unsigned long dwDesiredAccess, int bInheritHandle,
                        unsigned long dwOptions);
]]

local PAGE_READWRITE = 0x04;
local FILE_MAP_ALL_ACCESS = 0xF001F;
local WAIT_OBJECT_0 = 0;
local HANDLE_FLAG_CLOSE = 1;
local WAIT_ABANDONED = 0x80;

local int_size = ffi.sizeof("uint32_t"); -- Size of the length field

local flatten
flatten = function(t, path, res)
    res = res or {};
    for k, v in pairs(t) do
        if (type(v) == 'table') then
            flatten(v, path .. '_' .. k, res);
            res[path .. '_' .. k] = {};
        else
            res[path .. '_' .. k] = v;
            -- print(path .. '_' .. k)
        end
    end
    return res;
end

local function sharedTable(name, size)
    size = size or 16384
    local mutexName = "Global\\sharedTable_" .. name .. "_mutex";
    local shmName = "Global\\sharedTable_" .. name;

    -- Open or create the shared memory region
    local fileMapping = ffi.C.OpenFileMappingA(FILE_MAP_ALL_ACCESS, 0, shmName)
    local isNew = false;
    if fileMapping == nil then
        fileMapping = ffi.C.CreateFileMappingA(nil, nil, PAGE_READWRITE, 0, size, shmName)
        isNew = true;
    end

    local sharedMem = ffi.C.MapViewOfFile(fileMapping, FILE_MAP_ALL_ACCESS, 0, 0, size)

    -- If mapping failed, release the old mapping and reallocate
    if sharedMem == nil then
        print("Shared memory mapping failed, reinitializing...")

        local currentProcess = ffi.C.GetCurrentProcess()
        local duplicateHandle = ffi.new("void*[1]") -- Storage for duplicated handle

        local success = ffi.C.DuplicateHandle(
            currentProcess, fileMapping,     -- Source process & handle
            currentProcess, duplicateHandle, -- Target process & handle
            0, false, HANDLE_FLAG_CLOSE      -- Close the handle
        )

        if fileMapping ~= nil then
            ffi.C.CloseHandle(fileMapping)
        end

        if success == 0 then
            print("DuplicateHandle failed with error:", ffi.C.GetLastError())
        else
            print("Successfully duplicated handle for closure.")
            ffi.C.CloseHandle(duplicateHandle[0])
        end

        -- Forcefully create a new file mapping
        fileMapping = ffi.C.CreateFileMappingA(nil, nil, PAGE_READWRITE, 0, size, shmName)
        if fileMapping == nil then
            error("Failed to create file mapping.")
        end

        -- Retry mapping
        sharedMem = ffi.C.MapViewOfFile(fileMapping, FILE_MAP_ALL_ACCESS, 0, 0, size)
        if sharedMem == nil then
            error("Failed to re-map shared memory.")
        end

        isNew = true -- Mark it as a fresh allocation
    end

    -- Open or create the mutex
    local mutex = ffi.C.CreateMutexA(nil, 0, mutexName)
    if mutex == nil then
        error("Failed to create/open mutex.")
    end

    local function lock()
        if ffi.C.WaitForSingleObject(mutex, 5000) ~= WAIT_OBJECT_0 then
            error("Mutex lock timeout.")
        end
    end

    local function unlock()
        ffi.C.ReleaseMutex(mutex)
    end

    -- **Ensure memory is initialized** (if first process)
    do
        lock()

        -- Read stored length
        local data_len = ffi.new("uint32_t[1]")
        ffi.copy(data_len, sharedMem, int_size)

        local stored_length = data_len[0]

        -- Validate length (should be within shared memory bounds)
        if stored_length <= 0 or stored_length > (size - int_size) then
            stored_length = 0 -- Mark as invalid
        end

        local raw_data = ""
        if stored_length > 0 then
            -- Attempt to read the stored data
            raw_data = ffi.string(ffi.cast("uint8_t*", sharedMem) + int_size, stored_length)

            -- Validate MessagePack decoding
            local success, decoded = pcall(mp.unpack, raw_data)
            if not success then
                stored_length = 0 -- Mark as invalid
            end
        end

        if isNew or stored_length == 0 then
            -- Reset shared memory with an empty table `{}` and store length
            local serialized = mp.pack({})
            local serialized_len = #serialized

            ffi.C.memset(sharedMem, 0, size)                                      -- Clear shared memory
            ffi.copy(sharedMem, ffi.new("uint32_t[1]", serialized_len), int_size) -- Store length
            ffi.C.memcpy(ffi.cast("uint8_t*", sharedMem) + int_size, serialized, serialized_len)
        end

        unlock()
    end

    local function getTable()
        lock()
        local data_len = ffi.new("uint32_t[1]")
        ffi.copy(data_len, sharedMem, int_size) -- Read the stored length

        local raw_data = ffi.string(ffi.cast("uint8_t*", sharedMem) + int_size, data_len[0])
        unlock()
        -- Handle corruption by returning `{}` if unpacking fails
        local success, unpacked = pcall(mp.unpack, raw_data)
        if not success then
            print('corruption detected')
            return {} -- Reset table on error
        end
        return unpacked
    end


    local function subTable(keypath)
        keypath = keypath or 'root'

        local methods = T {};

        function methods:ipairs_read()
            local flat_table = getTable();

            local t = T {};

            local i = 0;
            while (true) do
                i = i + 1;
                local path = keypath .. '_' .. i;
                local val = flat_table[path];
                if (val) then
                    t[i] = val;
                else
                    break;
                end
            end

            return ipairs, t, 0
        end

        function methods:flat_list()
            local flat_table = getTable();

            local t = T {};

            local i = 0;
            while (true) do
                i = i + 1;
                local path = keypath .. '_' .. i;
                local val = flat_table[path];
                if (val) then
                    t[i] = val;
                else
                    break;
                end
            end

            return t;
        end

        function methods:flat_list_map(key)
            local flat_table = getTable();

            local t = T {};

            key = '_' .. key

            local i = 0;
            while (true) do
                i = i + 1;
                local path = keypath .. '_' .. i .. key;
                local val = flat_table[path];
                if (val) then
                    t[i] = val;
                else
                    break;
                end
            end

            return t;
        end

        -- Table proxy to interact with shared memory
        return setmetatable({}, {
            __index = function(t, key)
                local flat_table = getTable()
                local path = keypath .. '_' .. key;

                if (flat_table[path] ~= nil) then
                    if (type(flat_table[path]) == 'table') then
                        return subTable(path);
                    else
                        return flat_table[path];
                    end
                end

                return methods[key] or table[key];
            end,

            __newindex = function(t, key, value)
                lock()
                local data_len = ffi.new("uint32_t[1]")
                ffi.copy(data_len, sharedMem, int_size) -- Read the stored length

                local raw_data = ffi.string(ffi.cast("uint8_t*", sharedMem) + int_size, data_len[0])
                local success, flat_table = pcall(mp.unpack, raw_data)
                if not success then
                    flat_table = {}; -- Reset table on error
                end

                local path = keypath .. '_' .. key;

                if (flat_table[path]) then
                    flat_table[path] = nil;
                    local subPath = path .. '_';
                    for k, v in pairs(flat_table) do
                        if (k:startswith(subPath)) then
                            -- print(('deleting key %s, path %s'):format(k, path));
                            -- if (path == 'root_Jyouyoyo') then
                            --     error('yoyo')
                            -- end
                            flat_table[k] = nil;
                        end
                    end
                end

                if (type(value) == 'table') then
                    flat_table[path] = {};
                    flatten(value, path, flat_table)
                else
                    flat_table[path] = value;
                end

                local serialized = mp.pack(flat_table);
                local data_len = #serialized;

                if (data_len > size - int_size) then
                    error('shared table out of memory');
                end

                ffi.C.memset(sharedMem, 0, size)                                               -- Clear shared memory before writing
                ffi.copy(sharedMem, ffi.new('uint32_t[1]', data_len), int_size);
                ffi.C.memcpy(ffi.cast("uint8_t*", sharedMem) + int_size, serialized, data_len) -- Copy serialized data

                unlock()
            end,

            __gc = function()
                ffi.C.UnmapViewOfFile(sharedMem)
                ffi.C.CloseHandle(fileMapping)
                ffi.C.CloseHandle(mutex)
            end,

            __len = function()
                local flat_table = getTable();

                local prefix = keypath .. "_"
                local i = 1;

                while (flat_table[prefix + tostring(i)] ~= nil) do
                    i = i + 1;
                end

                return i - 1;
            end,

            -- Pairs iteration is not thread safe, but it's probably fine?
            __pairs = function(self)
                local flat_table = getTable()

                -- Extract only the direct children of keypath
                local prefix = keypath .. "_"
                local prefix_len = #prefix

                local function iter(_, i)
                    -- Expand the key to the full key
                    local flat_key = i and prefix .. i;
                    flat_key, _ = next(flat_table, flat_key);

                    while flat_key
                        and ((not flat_key:startswith(prefix))
                            or flat_key:sub(prefix_len + 1):find("_")) do
                        -- print(k and prefix .. k);
                        flat_key, _ = next(flat_table, flat_key);
                    end

                    local short_key = flat_key and flat_key:sub(prefix_len + 1)
                    return short_key, short_key and self[short_key];
                end

                return iter, self, nil;
            end,

            __ipairs = function(self)
                local flat_table = getTable();
                local function iter(tbl, i)
                    i = i + 1
                    local path = keypath .. '_' .. i;
                    local val = self[i];
                    if (tbl[path] and val) then
                        return i, val;
                    end
                end
                return iter, flat_table, 0
            end
        })
    end

    return subTable('root');
end

local function sharedTable2(name, size)
    size = size or 16384
    local mutexName = "Global\\sharedTable_" .. name .. "_mutex";
    local shmName = "Global\\sharedTable_" .. name;

    -- Open or create the shared memory region
    local fileMapping = ffi.C.OpenFileMappingA(FILE_MAP_ALL_ACCESS, 0, shmName)
    local isNew = false;
    if fileMapping == nil then
        fileMapping = ffi.C.CreateFileMappingA(nil, nil, PAGE_READWRITE, 0, size, shmName)
        isNew = true;
    end

    local sharedMem = ffi.C.MapViewOfFile(fileMapping, FILE_MAP_ALL_ACCESS, 0, 0, size)

    -- If mapping failed, release the old mapping and reallocate
    if sharedMem == nil then
        print("Shared memory mapping failed, reinitializing...")

        local currentProcess = ffi.C.GetCurrentProcess()
        local duplicateHandle = ffi.new("void*[1]") -- Storage for duplicated handle

        local success = ffi.C.DuplicateHandle(
            currentProcess, fileMapping,     -- Source process & handle
            currentProcess, duplicateHandle, -- Target process & handle
            0, false, HANDLE_FLAG_CLOSE      -- Close the handle
        )

        if fileMapping ~= nil then
            ffi.C.CloseHandle(fileMapping)
        end

        if success == 0 then
            print("DuplicateHandle failed with error:", ffi.C.GetLastError())
        else
            print("Successfully duplicated handle for closure.")
            ffi.C.CloseHandle(duplicateHandle[0])
        end

        -- Forcefully create a new file mapping
        fileMapping = ffi.C.CreateFileMappingA(nil, nil, PAGE_READWRITE, 0, size, shmName)
        if fileMapping == nil then
            error("Failed to create file mapping.")
        end

        -- Retry mapping
        sharedMem = ffi.C.MapViewOfFile(fileMapping, FILE_MAP_ALL_ACCESS, 0, 0, size)
        if sharedMem == nil then
            error("Failed to re-map shared memory.")
        end

        isNew = true -- Mark it as a fresh allocation
    end

    -- Open or create the mutex
    local mutex = ffi.C.CreateMutexA(nil, 0, mutexName)
    if mutex == nil then
        error("Failed to create/open mutex.")
    end

    local function lock()
        if ffi.C.WaitForSingleObject(mutex, 5000) ~= WAIT_OBJECT_0 then
            error("Mutex lock timeout.")
        end
    end

    local function unlock()
        ffi.C.ReleaseMutex(mutex)
    end

    -- **Ensure memory is initialized** (if first process)
    do
        lock()

        -- Read stored length
        local data_len = ffi.new("uint32_t[1]")
        ffi.copy(data_len, sharedMem, int_size)

        local stored_length = data_len[0]

        -- Validate length (should be within shared memory bounds)
        if stored_length <= 0 or stored_length > (size - int_size) then
            stored_length = 0 -- Mark as invalid
        end

        local raw_data = ""
        if stored_length > 0 then
            -- Attempt to read the stored data
            raw_data = ffi.string(ffi.cast("uint8_t*", sharedMem) + int_size, stored_length)

            -- Validate MessagePack decoding
            local success, decoded = pcall(mp.unpack, raw_data)
            if not success then
                stored_length = 0 -- Mark as invalid
            end
        end

        if isNew or stored_length == 0 then
            -- Reset shared memory with an empty table `{}` and store length
            local serialized = mp.pack({})
            local serialized_len = #serialized

            ffi.C.memset(sharedMem, 0, size)                                      -- Clear shared memory
            ffi.copy(sharedMem, ffi.new("uint32_t[1]", serialized_len), int_size) -- Store length
            ffi.C.memcpy(ffi.cast("uint8_t*", sharedMem) + int_size, serialized, serialized_len)
        end

        unlock()
    end

    local function getTable()
        lock()

        local data_len = ffi.new("uint32_t[1]")
        ffi.copy(data_len, sharedMem, int_size) -- Read the stored length

        local raw_data = ffi.string(ffi.cast("uint8_t*", sharedMem) + int_size, data_len[0])

        unlock()
        -- Handle corruption by returning `{}` if unpacking fails
        local success, unpacked = pcall(mp.unpack, raw_data)
        if not success then
            print('corruption detected')
            return {} -- Reset table on error
        end
        return unpacked
    end

    local function resolveKeypath(t, path)
        for _, k in ipairs(path) do
            t = t[k];
            if (t == nil) then
                return nil;
            end
        end

        if (type(t) ~= 'table') then
            print('keypath error');
            return nil;
        end

        return t;
    end

    -- Deeply nested tables are slower to read
    local function subTable(keypath)
        keypath = keypath or T {};

        return setmetatable({}, {
            __index = function(t, key)
                local res = getTable();

                res = resolveKeypath(res, keypath);

                res = res[key];

                if (type(res) == 'table') then
                    keypath:insert(key);
                    return subTable(keypath);
                else
                    return res;
                end
            end,
            __newindex = function(t, key, value)
                lock()
                local data_len = ffi.new("uint32_t[1]")
                ffi.copy(data_len, sharedMem, int_size) -- Read the stored length

                local raw_data = ffi.string(ffi.cast("uint8_t*", sharedMem) + int_size, data_len[0])
                local success, tableFromMemory = pcall(mp.unpack, raw_data)
                if not success then
                    tableFromMemory = {}; -- Reset table on error
                end

                local res = resolveKeypath(tableFromMemory, keypath);

                res[key] = value;

                local serialized = mp.pack(res);
                local data_len = #serialized;

                if (data_len > size - int_size) then
                    error('shared table out of memory');
                end

                ffi.C.memset(sharedMem, 0, size)                                               -- Clear shared memory before writing
                ffi.copy(sharedMem, ffi.new('uint32_t[1]', data_len), int_size);
                ffi.C.memcpy(ffi.cast("uint8_t*", sharedMem) + int_size, serialized, data_len) -- Copy serialized data

                unlock()
            end,

            __gc = function()
                ffi.C.UnmapViewOfFile(sharedMem)
                ffi.C.CloseHandle(fileMapping)
                ffi.C.CloseHandle(mutex)
            end,

            __len = function()
                local res = getTable();

                res = resolveKeypath(res, keypath);

                return #res;
            end,

            -- Pairs iteration is not thread safe, but it's probably fine?
            __pairs = function(self)
                local res = getTable();

                res = resolveKeypath(res, keypath);

                local function iter(_, k)
                    return next(res, k)
                end

                return iter, self, nil;
            end,

            __ipairs = function(self)
                local res = getTable();

                res = resolveKeypath(res, keypath);

                local function iter(tbl, i)
                    i = i + 1;
                    if (tbl[i] ~= nil) then
                        return i, tbl[i];
                    end
                end

                return iter, res, 0
            end
        });
    end
end

return sharedTable
