local wheel = T {
    Light = 'Dark',
    Dark = 'Light',
    Fire = 'Water',
    Water = 'Thunder',
    Thunder = 'Earth',
    Earth = 'Wind',
    Wind = 'Ice',
    Ice = 'Fire',
};

local function getObiBonus()
    local action = gData.GetAction();
    local environment = gData.GetEnvironment();

    local element = action.Element;

    local day = environment.DayElement;
    local weather = environment.WeatherElement;
    local doubleWeather = environment.Weather:contains('x2') and 0.15 or 0;

    local bonus = 0;
    if (element == day) then
        bonus = bonus + 0.1;
    elseif (wheel[element] == day) then
        bonus = bonus - 0.1;
    end

    if (element == weather) then
        bonus = bonus + 0.1 + doubleWeather;
    elseif (wheel[element] == weather) then
        bonus = bonus - 0.1 - doubleWeather;
    end

    return bonus;
end

return getObiBonus;