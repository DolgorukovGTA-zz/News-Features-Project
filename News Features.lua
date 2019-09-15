script_name("News Features")
script_author("dolgorukov")
script_version("16.09.2019")

local encoding = require "encoding"
encoding.default = "UTF-8"
cyr = encoding.CP1251
local adsAccCounter, adsRejCounter = 0, 0
local changeStatus = false

local function loadLibsAndFont()
    if isSampLoaded() or isSampfuncsLoaded() then
        local sampev = require "lib.samp.events"
        local inicfg = require "inicfg"
        local direction = "News Features Settings.ini"
        local set = inicfg.load({
            MessageSettings = {
                IgnoringStateAdvertising = false, -- игнорирование гос. рекламы
                IgnoringRegularAdvertising = false, -- игнорирование рекламы стран US, AF, RC
                IgnoringRadioBroadcasts = false, -- игнорирование радиоэфиров
                IgnoringNotifications = false -- игнорирование уведомлений о поступивших в редакцию объявлениях
            },

            AdSettings = {
                AutoAdmod = false, -- автоматический /admod
                AdTextInDialogBox = false -- текст объявления в поле диалога при редактировании
            },

            Statistics = {
                AdsPerAllTime = 0, -- реклама за всё время
                Money = 0 -- заработанные деньги на редакции объявлений
            },

            AdmodRenderSettings = { -- настройки информационного рендера
                Status = true, -- вкл/выкл
                Font = "Arial",
                Size = 12,
                PosX = 10,
                PosY = 400,
                RenderCurSessionAds = true,
                RenderAllAds = true,
                RenderRejAds = true,
                RenderEarnedMoney = true
            }
        }, direction)

        local fontFlag = require("moonloader").font_flag
        local renderFont = renderCreateFont(set.AdmodRenderSettings.Font, set.AdmodRenderSettings.Size, 4 + 1 + 8)
        return inicfg, direction, set, renderFont
    end
    return nil
end

if loadLibsAndFont() ~= nil then
    local inicfg, direction, set, renderFont = loadLibsAndFont()

    function main()
        while not isSampAvailable() do wait(100) end

        autoupdate("https://raw.githubusercontent.com/DolgorukovGTA/News-Features-Project/master/script-update.json", '['..string.upper(thisScript().name)..']: ', "https://raw.githubusercontent.com/DolgorukovGTA/News-Features-Project/master/News%20Features.lua")
        sampRegisterChatCommand("nhelp", function()
            if isPlayerOnTrinity() then
                if sampIsDialogActive() then 
                    sampAddChatMessage(cyr("Закройте текущие диалоговые окна для открытие нового окна."), -1)
                elseif isSampfuncsConsoleActive() then 
                    sampAddChatMessage(cyr("Закройте консоль SAMPFUNCS перед открытием диалогового окна."), -1)
                else 
                    showMenu() 
                end
            else
                sampAddChatMessage(cyr("Команда {87CEEB}«/nhelp»{FFFFFF} функционирует только на серверах проекта Trinity GTA."), -1)
            end
        end)

        sampRegisterChatCommand("cht", function()
            if isPlayerOnTrinity() then
                if sampIsDialogActive() then 
                    sampAddChatMessage(cyr("Закройте текущие диалоговые окна для открытие нового окна."), -1)
                elseif isSampfuncsConsoleActive() then 
                    sampAddChatMessage(cyr("Закройте консоль SAMPFUNCS перед открытием диалогового окна."), -1)
                elseif not set.AdmodRenderSettings.Status then 
                    sampAddChatMessage(cyr("Включите рендер ADMOD'а в настройках «/nhelp» для редактирования его позиции."), -1)
                else 
                    changeTextPos()
                end
            else
                sampAddChatMessage(cyr("Команда {87CEEB}«/cht»{FFFFFF} функционирует только на серверах проекта Trinity GTA."), -1)
            end
        end)

        repeat
            wait(0)
        until sampIsLocalPlayerSpawned() and isPlayerOnTrinity()
        mainRender()
        wait(-1)
    end

    function isPlayerOnTrinity()
        local _, serverPort = sampGetCurrentServerAddress() 
        local serverName = sampGetCurrentServerName()
        if serverName:find(cyr("|%s+Trinity Roleplay  №%d%s+|")) or serverName:find(cyr("|%s+Trinity RPG%s+|")) and serverPort == 7777 then 
            return true
        end
        return false
    end

    function mainRender()
        while true do
            if not changeStatus and isPlayerOnTrinity() and set.AdmodRenderSettings.Status then
                local renderText = "ADMOD:\n"
                if set.AdmodRenderSettings.RenderCurSessionAds then renderText = renderText.."За текущую сессию: {87CEEB}"..adsAccCounter.."\n{FFFFFF}" end
                if set.AdmodRenderSettings.RenderAllAds then renderText = renderText.."За всё время: {87CEEB}"..set.Statistics.AdsPerAllTime.."\n{FFFFFF}" end
                if set.AdmodRenderSettings.RenderRejAds then renderText = renderText.."Отклонено: {87CEEB}"..adsRejCounter.."\n{FFFFFF}" end
                if set.AdmodRenderSettings.RenderEarnedMoney then renderText = renderText.."Заработано: {33aa33}"..set.Statistics.Money.." $\n{FFFFFF}" end
                renderFontDrawText(renderFont, cyr(renderText), set.AdmodRenderSettings.PosX, set.AdmodRenderSettings.PosY, 0xFFFFFFFF)
            end
            wait(0)
        end
    end

    function changeTextPos()
        if sampIsChatInputActive() then sampSetChatInputEnabled(false) end
        changeStatus = true
        lua_thread.create(function()
            local posX, posY
            repeat
                posX, posY = getCursorPos()
                if sampGetCursorMode() ~=2 then sampSetCursorMode(2) end
                local renderText = "ADMOD:\n"
                if set.AdmodRenderSettings.RenderCurSessionAds then renderText = renderText.."За текущую сессию: {87CEEB}"..adsAccCounter.."\n{FFFFFF}" end
                if set.AdmodRenderSettings.RenderAllAds then renderText = renderText.."За всё время: {87CEEB}"..set.Statistics.AdsPerAllTime.."\n{FFFFFF}" end
                if set.AdmodRenderSettings.RenderRejAds then renderText = renderText.."Отклонено: {87CEEB}"..adsRejCounter.."\n{FFFFFF}" end
                if set.AdmodRenderSettings.RenderEarnedMoney then renderText = renderText.."Заработано: {33aa33}"..set.Statistics.Money.." $\n{FFFFFF}" end
                renderFontDrawText(renderFont, cyr(renderText), posX, posY, 0xFFFFFFFF)
                wait(0)
            until isKeyJustPressed(2) or sampIsChatInputActive() or isSampfuncsConsoleActive()

            set.AdmodRenderSettings.PosX = posX; set.AdmodRenderSettings.PosY = posY 
            inicfg.save(set, direction)
            changeStatus = false
            sampSetCursorMode(0)
            mainRender()
        end)
    end

    local scriptDialogsWorking = false
    function showMenu()
        scriptDialogsWorking = true
        local boolShowMenu = true
        lua_thread.create(function()
            local show6409 = false
            while true do
                if boolShowMenu then
                    local dialogText = cyr("{87CEEB}1.{FFFFFF} Отображение сообщений\n{87CEEB}2.{FFFFFF} Работа с объявлениями\n{87CEEB}3.{FFFFFF} Отредактированные объявления\n{87CEEB}4.{FFFFFF} ADMOD-рендер")
                    sampShowDialog(6405, cyr("{87CEEB}News — Главное меню{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Отмена"), 2)
                    while sampIsDialogActive(6405) do wait(100) end
                    local result, button, list, _ = sampHasDialogRespond(6405)
                    if result then
                        if button == 1 then
                            if list == 0 then
                                boolShowMenu = false
                                while not boolShowMenu do

                                    local renderStatus = {}
                                    if set.MessageSettings.IgnoringStateAdvertising then renderStatus[1] = "{33aa33}[ON]" else renderStatus[1] = "{ff6347}[OFF]" end
                                    if set.MessageSettings.IgnoringRegularAdvertising then renderStatus[2] = "{33aa33}[ON]" else renderStatus[2] = "{ff6347}[OFF]" end
                                    if set.MessageSettings.IgnoringRadioBroadcasts then renderStatus[3] = "{33aa33}[ON]" else renderStatus[3] = "{ff6347}[OFF]" end
                                    if set.MessageSettings.IgnoringNotifications then renderStatus[4] = "{33aa33}[ON]" else renderStatus[4] = "{ff6347}[OFF]" end

                                    local dialogText = cyr("{87CEEB}1.{FFFFFF} Игнорирование гос.рекламы\t\t\t\t"..renderStatus[1].."{ffffff}\n{87CEEB}2.{FFFFFF} Игнорирование рекламы US, AF, RC\t\t\t"..renderStatus[2].."\n{87CEEB}3.{FFFFFF} Игнорирование радиоэфиров\t\t\t\t"..renderStatus[3].."\n{87CEEB}4.{FFFFFF} Игнорирование уведомлений о новых объявлениях\t"..renderStatus[4])
                                    sampShowDialog(6406, cyr("{87CEEB}News — Отображение сообщений{FFFFFF}"), dialogText, cyr("ОК"), cyr("Отмена"), DIALOG_STYLE_LIST)
                                    while sampIsDialogActive(6406) do wait(100) end
                                    local result, button, list, _ = sampHasDialogRespond(6406)
                                    if result then
                                        if button == 1 then
                                            if list == 0 then set.MessageSettings.IgnoringStateAdvertising = not set.MessageSettings.IgnoringStateAdvertising; inicfg.save(set, direction)
                                            elseif list == 1 then set.MessageSettings.IgnoringRegularAdvertising = not set.MessageSettings.IgnoringRegularAdvertising; inicfg.save(set, direction)
                                            elseif list == 2 then set.MessageSettings.IgnoringRadioBroadcasts = not set.MessageSettings.IgnoringRadioBroadcasts; inicfg.save(set, direction)
                                            elseif list == 3 then set.MessageSettings.IgnoringNotifications = not set.MessageSettings.IgnoringNotifications; inicfg.save(set, direction) 
                                            end
                                        else sampCloseCurrentDialogWithButton(0); boolShowMenu = true 
                                        end
                                    end
                                end
                            elseif list == 1 then
                                boolShowMenu = false
                                while not boolShowMenu do

                                    local renderStatus = {}
                                    if set.AdSettings.AutoAdmod then renderStatus[1] = "{33aa33}[ON]" else renderStatus[1] = "{ff6347}[OFF]" end
                                    if set.AdSettings.AdTextInDialogBox then renderStatus[2] = "{33aa33}[ON]" else renderStatus[2] = "{ff6347}[OFF]" end

                                    local dialogText = cyr("{87CEEB}1.{FFFFFF} Автоматический /admod\t\t\t"..renderStatus[1].."\n{87CEEB}2.{FFFFFF} Текст объявления в поле диалога \t\t"..renderStatus[2])
                                    sampShowDialog(6407, cyr("{87CEEB}News — Работа с объявлениями{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Назад"), 2)
                                    while sampIsDialogActive(6407) do wait(100) end
                                    local result, button, list, _ = sampHasDialogRespond(6407)
                                    if result then
                                        if button == 1 then
                                            if list == 0 then
                                                set.AdSettings.AutoAdmod = not set.AdSettings.AutoAdmod
                                                inicfg.save(set, direction)
                                            elseif list == 1 then
                                                set.AdSettings.AdTextInDialogBox = not set.AdSettings.AdTextInDialogBox
                                                inicfg.save(set, direction)
                                            end
                                        else
                                            sampCloseCurrentDialogWithButton(0)
                                            boolShowMenu = true
                                        end
                                    end
                                end
                            elseif list == 2 then
                                boolShowMenu = false
                                while not boolShowMenu do
                                    local dialogText = cyr("{FFFFFF}За текущую сессию: "..adsAccCounter.."\nЗа всё время: "..set.Statistics.AdsPerAllTime.."\nОтклонено: "..adsRejCounter.."\nЗаработано средств: {33aa33}"..set.Statistics.Money.." ${ffffff}")
                                    sampShowDialog(6408, cyr("{87CEEB}News — /admod{FFFFFF}"), dialogText, cyr("Сбросить"), cyr("Назад"), 0)
                                    while sampIsDialogActive(6408) do wait(100) end
                                    local result, button, list, _ = sampHasDialogRespond(6408)
                                    if result then
                                        if button == 1 then
                                            if set.Statistics.AdsPerAllTime ~= 0 then
                                                local dialogText = cyr("{FFFFFF}Вы действительно хотите сбросить свои\nпоказатели по отредактированным объявлениям?")
                                                sampShowDialog(6409, cyr("{FFFFFF}News — Подтвердите своё действие"), dialogText, cyr("Да"), cyr("Нет"), 0)
                                                while sampIsDialogActive(6409) do wait(100) end
                                                local result, button, list, _ = sampHasDialogRespond(6409)
                                                if result then
                                                    if button == 1 then
                                                        adsAccCounter = 0; set.Statistics.AdsPerAllTime = 0; set.Statistics.Money = 0; inicfg.save(set, direction)
                                                        sampAddChatMessage(cyr("Вы успешно сбросили счётчик отредактированных объявлений и заработанных денежных средств."), -1)
                                                    else
                                                        sampCloseCurrentDialogWithButton(0)
                                                    end
                                                end
                                            else
                                                sampAddChatMessage(cyr("Бесмысленно сбрасывать, ведь Вы не отредактировали ни одного объявления."), -1)
                                            end
                                            sampCloseCurrentDialogWithButton(0)
                                        else
                                            sampCloseCurrentDialogWithButton(0); boolShowMenu = true
                                        end
                                    end
                                end
                            elseif list == 3 then
                                boolShowMenu = false
                                while not boolShowMenu or show6409 do
                                    local renderStatus;
                                    if set.AdmodRenderSettings.Status then renderStatus = "{33aa33}[ON]" else renderStatus = "{ff6347}[OFF]" end
                                    local dialogText = cyr("{87CEEB}1.{FFFFFF} Состояние: "..renderStatus.."\n{87CEEB}2.{FFFFFF} Шрифт: {6495ED}"..set.AdmodRenderSettings.Font.."\n{87CEEB}3.{FFFFFF} Размер шрифта: {6495ED}"..set.AdmodRenderSettings.Size.."\n{87CEEB}4.{FFFFFF} Настройки содержимого")
                                    sampShowDialog(6409, cyr("{87CEEB}News — ADMOD-рендер{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Назад"), 2)
                                    while sampIsDialogActive(6409) do wait(100) end
                                    local result, button, list, _ = sampHasDialogRespond(6409)
                                    if result then
                                        if button == 1 then
                                            if list == 0 then
                                                set.AdmodRenderSettings.Status = not set.AdmodRenderSettings.Status; inicfg.save(set, direction)
                                            elseif list == 1 then
                                                if set.AdmodRenderSettings.Status then
                                                    local dialogText = cyr("{FFFFFF}Текущий шрифт: {6495ED}"..set.AdmodRenderSettings.Font.."{FFFFFF}.\n\nВведите название нового шрифта в поле диалога ниже,\nесли шрифт не поменяется, значит таковой отсутствует\nна Вашем компьютере.")
                                                    sampShowDialog(6410, cyr("{87CEEB}News — Настройка шрифта{FFFFFF}"), dialogText, cyr("ОК"), cyr("Назад"), 1)
                                                    while sampIsDialogActive(6410) do wait(100) end
                                                    local result, button, _, input = sampHasDialogRespond(6410)
                                                    if result then
                                                        if button == 1 then
                                                            if input ~= "" then
                                                                if input:find("^.+[^%s]$") then
                                                                    if not input:find("^%d+$") then
                                                                        if input ~= set.AdmodRenderSettings.Font then
                                                                            set.AdmodRenderSettings.Font = input; inicfg.save(set, direction)
                                                                            renderFont = renderCreateFont(set.AdmodRenderSettings.Font, set.AdmodRenderSettings.Size, 4 + 1 + 8)
                                                                        else
                                                                            sampAddChatMessage(cyr("В текущий момент итак установлен шрифт "..input.."."), -1)
                                                                        end
                                                                    else
                                                                        sampAddChatMessage(cyr("Название шрифта не может состоять только из цифр, здесь что-то не так. :thinking:"), -1)
                                                                    end
                                                                else
                                                                    sampAddChatMessage(cyr("В названии шрифта присутствуют пробелы в конце, укажите наименование корректно."), -1)
                                                                end
                                                            else
                                                                sampAddChatMessage(cyr("Вы ничего не ввели!"), -1)
                                                            end
                                                        else
                                                            sampCloseCurrentDialogWithButton(0)
                                                        end
                                                    end
                                                else
                                                    sampAddChatMessage(cyr("Для кастомизации рендера ADMOD'а, необходимо его включить."), -1)
                                                end
                                            elseif list == 2 then
                                                if set.AdmodRenderSettings.Status then
                                                    local dialogText = cyr("{FFFFFF}Текущий размер шрифта: {6495ED}"..set.AdmodRenderSettings.Size.."{FFFFFF}.\nРазмер шрифта задаётся исключительно в целочисленном формате!")
                                                    sampShowDialog(6411, cyr("{87CEEB}News — Настройка размера шрифта{FFFFFF}"), dialogText, cyr("ОК"), cyr("Назад"), 1)
                                                    while sampIsDialogActive(6411) do wait(100) end
                                                    local result, button, _, input = sampHasDialogRespond(6411)
                                                    if result then
                                                        if button == 1 then
                                                            if input ~= "" then
                                                                if input:find("^%d+$") then
                                                                    local input = tonumber(input)
                                                                    if input ~= set.AdmodRenderSettings.Size then
                                                                        if input <= 45 then
                                                                            if input ~= 0 then
                                                                                if input >= 6 then
                                                                                    set.AdmodRenderSettings.Size = input; inicfg.save(set, direction)
                                                                                    renderFont = renderCreateFont(set.AdmodRenderSettings.Font, set.AdmodRenderSettings.Size, 4 + 1 + 8)
                                                                                else
                                                                                    sampAddChatMessage(cyr("Слишком маленький шрифт. «Глаза же испортишь, зрение нужно беречь с молодости» — (с) Мама."), -1)
                                                                                end
                                                                            else
                                                                                sampAddChatMessage(cyr("Серьёзно? 0? Ты совсем сошёл с катушек?"), -1)
                                                                            end
                                                                        else
                                                                            sampAddChatMessage(cyr("Такие большие масштабы нам ни к чему."), -1)
                                                                        end
                                                                    else
                                                                        sampAddChatMessage(cyr("В текущий момент итак установлено данное значение ("..input..")."), -1)
                                                                    end
                                                                else
                                                                    sampAddChatMessage(cyr("Данные введены в неверном формате или найдены несоответствующие символы."), -1)
                                                                end
                                                            else
                                                                sampAddChatMessage(cyr("Вы ничего не ввели!"), -1)
                                                            end
                                                        else
                                                            sampCloseCurrentDialogWithButton(0)
                                                        end
                                                    end
                                                else
                                                    sampAddChatMessage(cyr("Для кастомизации рендера ADMOD'а, необходимо его включить."), -1)
                                                end
                                            elseif list == 3 then
                                                if set.AdmodRenderSettings.Status then
                                                    while not show6409 do
                                                        local renderStatus = {}
                                                        if set.AdmodRenderSettings.RenderCurSessionAds then renderStatus[1] = "{33aa33}[ON]" else renderStatus[1] = "{ff6347}[OFF]" end
                                                        if set.AdmodRenderSettings.RenderAllAds then renderStatus[2] = "{33aa33}[ON]" else renderStatus[2] = "{ff6347}[OFF]" end
                                                        if set.AdmodRenderSettings.RenderRejAds then renderStatus[3] = "{33aa33}[ON]" else renderStatus[3] = "{ff6347}[OFF]" end
                                                        if set.AdmodRenderSettings.RenderEarnedMoney then renderStatus[4] = "{33aa33}[ON]" else renderStatus[4] = "{ff6347}[OFF]" end

                                                        local dialogText = cyr("Отображать количество объявлений, отредактированных за текущую сессию\t"..renderStatus[1].."\nОтображать количество объявлений, отредактированных за всё время\t\t"..renderStatus[2].."\nОтображать количество отклонённых объявлений\t\t\t\t\t"..renderStatus[3].."\nОтображать количество заработанных денег при помощи редакции\t\t\t"..renderStatus[4])
                                                        sampShowDialog(6412, cyr("{87CEEB}News — Содержимое ADMOD-рендера{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Назад"), 2)
                                                        while sampIsDialogActive(6412) do wait(100) end
                                                        local result, button, list, _ = sampHasDialogRespond(6412)
                                                        if result then
                                                            if button == 1 then
                                                                if list == 0 then set.AdmodRenderSettings.RenderCurSessionAds = not set.AdmodRenderSettings.RenderCurSessionAds; inicfg.save(set, direction)
                                                                elseif list == 1 then set.AdmodRenderSettings.RenderAllAds = not set.AdmodRenderSettings.RenderAllAds; inicfg.save(set, direction)
                                                                elseif list == 2 then set.AdmodRenderSettings.RenderRejAds = not set.AdmodRenderSettings.RenderRejAds; inicfg.save(set, direction)
                                                                elseif list == 3 then set.AdmodRenderSettings.RenderEarnedMoney = not set.AdmodRenderSettings.RenderEarnedMoney; inicfg.save(set, direction)
                                                                end
                                                            else
                                                                sampCloseCurrentDialogWithButton(0); show6409 = true
                                                            end
                                                        end
                                                    end
                                                else
                                                    sampAddChatMessage(cyr("Для кастомизации рендера ADMOD'а, необходимо его включить."), -1)
                                                end
                                            end
                                        else
                                            sampCloseCurrentDialogWithButton(0); boolShowMenu = true; show6409 = false
                                        end
                                    end
                                end
                            end
                        else
                            sampCloseCurrentDialogWithButton(0)
                            boolShowMenu = false
                            scriptDialogsWorking = false
                        end
                    end
                end
                wait(10)
            end  
        end)
    end

    local sampev = require "lib.samp.events"
    function sampev.onServerMessage(color, text)
        if isPlayerOnTrinity() and color == -290866945 then
            if set.AdSettings.AutoAdmod and text:find(cyr("На модерацию поступило новое объявление%. .+")) and not isGamePaused() then 
                if not sampIsDialogActive() then 
                    sampSendChat("/admod")
                else
                    -- local noAdmodInputIds = {3420, 3422, 3423, 3425, 3421}
                    local AdmodInfo = true
                    for _, v in pairs({3420, 3422, 3423, 3425, 3421}) do
                        if sampGetCurrentDialogId() == v then
                            noAdmodInfo = false; break
                        end
                    end
                    if noAdmodInfo and not scriptDialogsWorking then
                        sampAddChatMessage(cyr("Автоматический /admod отклонен, открыто другое диалоговое окно."), -1)
                    end
                end
            elseif set.MessageSettings.IgnoringStateAdvertising and text:find(cyr("^%[Гос. реклама%].+")) then return false
            elseif set.MessageSettings.IgnoringRegularAdvertising and text:find(cyr("^%[Реклама %a+%].+")) then return false
            elseif set.MessageSettings.IgnoringRadioBroadcasts and text:find(cyr("^%[Радио %a+%] .+")) then return false
            elseif set.MessageSettings.IgnoringNotifications and text:find(cyr("На модерацию поступило новое объявление%. .+")) then return false 
            end
        end
    end

    function sampev.onShowDialog(id, style, _, b1, b2, text)
        -- print(id, text) 3420, 3422, 3423, 3425, 3421
        if isPlayerOnTrinity() then
            if set.AdSettings.AdTextInDialogBox and id == 3423 and style == 1 and b1 == cyr("Отправить") and b2 == cyr("Назад") then
                if text:find(cyr("{ffffff}Текст:{abcdef} .+{ffffff}")) then
                    local textDialog = text:match(cyr("{ffffff}Текст:{abcdef} (.+){ffffff}"))
                    lua_thread.create(function()
                        repeat
                            local result = sampIsDialogActive(); wait(0)
                        until result
                        sampSetCurrentDialogEditboxText(textDialog)
                    end)
                end
            elseif id == 3421 and text:find(cyr("^Объявление успешно отредактировано и отправлено в очередь на публикацию%.$")) then
                set.Statistics.AdsPerAllTime = set.Statistics.AdsPerAllTime + 1
                set.Statistics.Money = set.Statistics.Money + 2; inicfg.save(set, direction)
                adsAccCounter = adsAccCounter + 1
            end
        end
    end

    function sampev.onSendDialogResponse(id, button, list)
        if (id == 3420 or id == 3425) and button == 1 then
            set.Statistics.AdsPerAllTime = set.Statistics.AdsPerAllTime + 1
            set.Statistics.Money = set.Statistics.Money + 2; inicfg.save(set, direction)
            adsAccCounter = adsAccCounter + 1
        elseif id == 3422 and button == 1 and list == 0 then
            adsRejCounter = adsRejCounter + 1
        end
    end

    function autoupdate(json_url, prefix, url)
        local dlstatus = require("moonloader").download_status
        local json = getWorkingDirectory() .. "\\"..thisScript().name.."-version.json"
        if doesFileExist(json) then os.remove(json) end

        downloadUrlToFile(json_url, json, function(id, status, p1, p2)
            if status == dlstatus.STATUSEX_ENDDOWNLOAD then
                if doesFileExist(json) then
                    local f = io.open(json, "r")
                    if f then
                        local info = decodeJson(f:read("*a"))
                        updatelink = info.updateurl
                        updateversion = info.latest
                        f:close()
                        os.remove(json)
                        if updateversion ~= thisScript().version then
                            lua_thread.create(function(prefix)
                                local dlstatus = require("moonloader").download_status
                                local color = -1
                                sampAddChatMessage(cyr((prefix.."Обнаружено обновление. Попытка обновить версию с "..thisScript().version.." на "..updateversion..".")), color)
                                wait(250)
                                downloadUrlToFile(updatelink, thisScript().path, function(id3, status1, p13, p23)
                                    if status1 == dlstatus.STATUS_DOWNLOADINGDATA then
                                        sampAddChatMessage(cyr(string.format("Загружено %d из %d.", p13, p23)), -1)
                                    elseif status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
                                        sampAddChatMessage(cyr((prefix.."Обновление завершено!")), color)
                                        goupdatestatus = true
                                        lua_thread.create(function() wait(500) thisScript():reload() end)
                                    elseif status1 == dlstatus.STATUSEX_ENDDOWNLOAD then
                                        if goupdatestatus == nil then
                                            sampAddChatMessage(cyr((prefix.." Обновление прошло неудачно.")), -1)
                                            update = false
                                        end
                                    end
                                end)
                            end, prefix)
                        else
                            update = false
                            sampAddChatMessage(cyr(prefix.."v"..thisScript().version.." – обновление не требуется."), -1)
                        end
                    end
                else
                    sampAddChatMessage(cyr(prefix.."v"..thisScript().version.." – не получилось обработать информацию о новых обновлениях."..url), -1)
                    update = false
                end -- does file exist
            end -- status == dlstatus.STATUSEX_ENDDOWNLOAD
        end) -- function in download
        while update ~= false do 
            wait(100) 
        end
    end
else
    thisScript():unload()
end
