local cities = {
    "Ru'Lude Gardens",
    "Upper Jeuno",
    "Lower Jeuno",
    "Port Jeuno",
    "Port Windurst",
    "Windurst Waters",
    "Windurst Woods",
    "Windurst Walls",
    "Heavens Tower",
    "Port San d'Oria",
    "Northern San d'Oria",
    "Southern San d'Oria",
    "Chateau d'Oraguille",
    "Port Bastok",
    "Bastok Markets",
    "Bastok Mines",
    "Metalworks",
    "Aht Urhgan Whitegate",
    "The Colosseum",
    "Tavanazian Safehold",
    "Nashmau",
    "Selbina",
    "Mhaura",
    "Rabao",
    "Norg",
    "Kazham",
    "Eastern Adoulin",
    "Western Adoulin",
    "Celennia Memorial Library",
    "Mog Garden",
    "Leafallia"
};

local res = T {};
for _, v in ipairs(cities) do
    res[v] = v;
end

return res;