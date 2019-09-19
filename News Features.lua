script_author("dolgorukov")
script_version("16.09.2019")

local script = thisScript()

if isSampLoaded() and isSampfuncsLoaded() then

    local script_name = script.name

    if script_name ~= "News Features.lua" then
        sampAddChatMessage(cyr("Скрипт будет выгружен, так как его оригинальное название было переименовано."), -1)
        sampAddChatMessage(cyr("Поменяйте название на исходное и перезапустите скрипт."), -1)
        script:unload()
    else
        local function doesSampLuaExist()
            local m = 0
            local game_path = getGameDirectory()
            if doesDirectoryExist(game_path.."\\moonloader\\lib\\samp\\events") then
                local items = {"events", "raknet", "synchronization"}
                for _, item in ipairs(items) do
                    if doesFileExist(game_path.."\\moonloader\\lib\\samp\\"..item..".lua") then
                        m = m + 1
                    end
                end
                if m == 3 then
                    return true
                end
                return false
            end
        end

        local encoding = require "encoding"
        encoding.default = "UTF-8"
        local cyr = encoding.CP1251

        local result_samp_lua = doesSampLuaExist()
        if not result_samp_lua then
            sampAddChatMessage(cyr("Модуль SAMP.Lua не установлен, либо находится в неполном объёме."), -1)
            sampAddChatMessage(cyr("Установите данный модуль и перезапустите скрипт."), -1)
            script:unload()
            script = nil
        else
            script_name = script_name:gsub("%.lua", "")
            local sampev = require "lib.samp.events"
            local inicfg = require "inicfg"
            local direction = script_name.." Settings.ini"
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

            function main()
                while not isSampAvailable() do wait(100) end
                local json_file_url = "https://raw.githubusercontent.com/DolgorukovGTA/News-Features-Project/master/script-update.json"
                local script_file_url = "https://raw.githubusercontent.com/DolgorukovGTA/News-Features-Project/master/News%20Features.lua"
                autoupdate(json_file_url, "["..script_name.."]: ", script_file_url)

                sampRegisterChatCommand("nhelp", function()
                    if isPlayerOnTrinity() then
                        if sampIsDialogActive() then
                            sampAddChatMessage(cyr("Закройте текущие диалоговые окна для открытия нового."), -1)
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
                            sampAddChatMessage(cyr("Закройте текущие диалоговые окна для открытия нового."), -1)
                        elseif not sampIsLocalPlayerSpawned() then
                            sampAddChatMessage(cyr("Дождитесь, пока Ваш персонаж будет заспавнен."), -1)
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

            local font_flag = require("moonloader").font_flag
            local renderFont = renderCreateFont(set.AdmodRenderSettings.Font, set.AdmodRenderSettings.Size, font_flag.BOLD + font_flag.BORDER + font_flag.SHADOW)
            local ads_acc_counter, ads_rej_counter = 0, 0 -- счётчик принятых и отклонённых объявлений за текущую сессию соответственно
            local change_pos_status = false -- изменение позиции рендер-текста

            function isPlayerOnTrinity()
                local _, server_port = sampGetCurrentServerAddress() 
                local server_name = sampGetCurrentServerName()
                if server_name:find(cyr("|%s+Trinity Roleplay  №%d%s+|")) or server_name:find(cyr("|%s+Trinity RPG%s+|")) and server_port == 7777 then return true end
                return false
            end

            function mainRender()
                while true do
                    if not change_pos_status and isPlayerOnTrinity() and set.AdmodRenderSettings.Status and sampIsLocalPlayerSpawned() then
                        local render_text = "ADMOD:\n"
                        if set.AdmodRenderSettings.RenderCurSessionAds then 
                            render_text = render_text.."За текущую сессию: {87CEEB}"..ads_acc_counter.."\n{FFFFFF}" 
                        end
                        if set.AdmodRenderSettings.RenderAllAds then 
                            render_text = render_text.."За всё время: {87CEEB}"..set.Statistics.AdsPerAllTime.."\n{FFFFFF}" 
                        end
                        if set.AdmodRenderSettings.RenderRejAds then 
                            render_text = render_text.."Отклонено: {87CEEB}"..ads_rej_counter.."\n{FFFFFF}" 
                        end
                        if set.AdmodRenderSettings.RenderEarnedMoney then 
                            render_text = render_text.."Заработано: {33aa33}"..set.Statistics.Money.." $\n{FFFFFF}" 
                        end
                        render_text = cyr(render_text)
                        renderFontDrawText(renderFont, render_text, set.AdmodRenderSettings.PosX, set.AdmodRenderSettings.PosY, 0xFFFFFFFF)
                    end
                    wait(0)
                end
            end

            function changeTextPos()
                if sampIsChatInputActive() then
                    sampSetChatInputEnabled(false) 
                end
                change_pos_status = true
                lua_thread.create(function()
                    local m_pos_x, m_pos_y
                    repeat
                        m_pos_x, m_pos_y = getCursorPos()
                        if sampGetCursorMode() ~=2 then sampSetCursorMode(2) end
                        local render_text = "ADMOD:\n"
                        if set.AdmodRenderSettings.RenderCurSessionAds then 
                            render_text = render_text.."За текущую сессию: {87CEEB}"..ads_acc_counter.."\n{FFFFFF}"
                        end
                        if set.AdmodRenderSettings.RenderAllAds then 
                            render_text = render_text.."За всё время: {87CEEB}"..set.Statistics.AdsPerAllTime.."\n{FFFFFF}" 
                        end
                        if set.AdmodRenderSettings.RenderRejAds then 
                            render_text = render_text.."Отклонено: {87CEEB}"..ads_rej_counter.."\n{FFFFFF}" 
                        end
                        if set.AdmodRenderSettings.RenderEarnedMoney then 
                            render_text = render_text.."Заработано: {33aa33}"..set.Statistics.Money.." $\n{FFFFFF}" 
                        end
                        render_text = cyr(render_text)
                        renderFontDrawText(renderFont, render_text, m_pos_x, m_pos_y, 0xFFFFFFFF)
                        wait(0)
                    until isKeyJustPressed(2) or sampIsChatInputActive() or isSampfuncsConsoleActive() or not sampIsLocalPlayerSpawned()
                    set.AdmodRenderSettings.PosX = m_pos_x; set.AdmodRenderSettings.PosY = m_pos_y
                    inicfg.save(set, direction)
                    change_pos_status = false
                    sampSetCursorMode(0)
                    mainRender()
                end)
            end

            local is_script_dialogs_working = false
            function showMenu()
                is_script_dialogs_working = true
                local show_main_dialog = true
                lua_thread.create(function()
                    local show_dialog_6409 = false
                    while true do
                        if show_main_dialog then
                            local dialogText = cyr("{87CEEB}1.{FFFFFF} Отображение сообщений\n{87CEEB}2.{FFFFFF} Работа с объявлениями\n{87CEEB}3.{FFFFFF} Отредактированные объявления\n{87CEEB}4.{FFFFFF} ADMOD-рендер")
                            sampShowDialog(6405, cyr("{87CEEB}"..script_name.." — Главное меню{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Отмена"), 2)
                            while sampIsDialogActive(6405) do wait(100) end
                            local result, button, list, _ = sampHasDialogRespond(6405)
                            if result then
                                if button == 1 then
                                    show_main_dialog = false
                                    while not show_main_dialog do
                                        if list == 0 then
                                            local render_info = {}
                                            render_info[1] = set.MessageSettings.IgnoringStateAdvertising and "{33aa33}[ON]" or "{ff6347}[OFF]"
                                            render_info[2] = set.MessageSettings.IgnoringRegularAdvertising and "{33aa33}[ON]" or "{ff6347}[OFF]"
                                            render_info[3] = set.MessageSettings.IgnoringRadioBroadcasts and "{33aa33}[ON]" or "{ff6347}[OFF]"
                                            render_info[4] = set.MessageSettings.IgnoringNotifications and "{33aa33}[ON]" or "{ff6347}[OFF]"

                                            local dialogText = cyr("{87CEEB}1.{FFFFFF} Игнорирование гос.рекламы\t\t\t\t"..render_info[1].."{ffffff}\n{87CEEB}2.{FFFFFF} Игнорирование рекламы US, AF, RC\t\t\t"..render_info[2].."\n{87CEEB}3.{FFFFFF} Игнорирование радиоэфиров\t\t\t\t"..render_info[3].."\n{87CEEB}4.{FFFFFF} Игнорирование уведомлений о новых объявлениях\t"..render_info[4])
                                            sampShowDialog(6406, cyr("{87CEEB}"..script_name.." — Отображение сообщений{FFFFFF}"), dialogText, cyr("ОК"), cyr("Отмена"), DIALOG_STYLE_LIST)
                                            while sampIsDialogActive(6406) do wait(100) end
                                            local result, button, list, _ = sampHasDialogRespond(6406)
                                            if result then
                                                if button == 1 then
                                                    if list == 0 then 
                                                        set.MessageSettings.IgnoringStateAdvertising = not set.MessageSettings.IgnoringStateAdvertising
                                                    elseif list == 1 then 
                                                        set.MessageSettings.IgnoringRegularAdvertising = not set.MessageSettings.IgnoringRegularAdvertising
                                                    elseif list == 2 then 
                                                        set.MessageSettings.IgnoringRadioBroadcasts = not set.MessageSettings.IgnoringRadioBroadcasts
                                                    elseif list == 3 then 
                                                        set.MessageSettings.IgnoringNotifications = not set.MessageSettings.IgnoringNotifications
                                                    end
                                                    inicfg.save(set, direction)
                                                else 
                                                    sampCloseCurrentDialogWithButton(0)
                                                    show_main_dialog = true 
                                                end
                                            end
                                        elseif list == 1 then

                                            local render_info = {}
                                            render_info[1] = set.AdSettings.AutoAdmod and "{33aa33}[ON]" or "{ff6347}[OFF]"
                                            render_info[2] = set.AdSettings.AdTextInDialogBox and "{33aa33}[ON]" or "{ff6347}[OFF]"

                                            local dialogText = cyr("{87CEEB}1.{FFFFFF} Автоматический /admod\t\t\t"..render_info[1].."\n{87CEEB}2.{FFFFFF} Текст объявления в поле диалога \t\t"..render_info[2])
                                            sampShowDialog(6407, cyr("{87CEEB}"..script_name.." — Работа с объявлениями{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Назад"), 2)
                                            while sampIsDialogActive(6407) do wait(100) end
                                            local result, button, list, _ = sampHasDialogRespond(6407)
                                            if result then
                                                if button == 1 then
                                                    if list == 0 then 
                                                        set.AdSettings.AutoAdmod = not set.AdSettings.AutoAdmod 
                                                    elseif list == 1 then 
                                                        set.AdSettings.AdTextInDialogBox = not set.AdSettings.AdTextInDialogBox
                                                    end
                                                    inicfg.save(set, direction)
                                                else
                                                    sampCloseCurrentDialogWithButton(0)
                                                    show_main_dialog = true
                                                end
                                            end
                                        elseif list == 2 then
                                            local dialogText = cyr("{FFFFFF}За текущую сессию: "..ads_acc_counter.."\nЗа всё время: "..set.Statistics.AdsPerAllTime.."\nОтклонено: "..ads_rej_counter.."\nЗаработано средств: {33aa33}"..set.Statistics.Money.." ${ffffff}")
                                            sampShowDialog(6408, cyr("{87CEEB}"..script_name.." — /admod{FFFFFF}"), dialogText, cyr("Сбросить"), cyr("Назад"), 0)
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
                                                                ads_acc_counter = 0
                                                                set.Statistics.AdsPerAllTime = 0
                                                                set.Statistics.Money = 0
                                                                inicfg.save(set, direction)
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
                                                    sampCloseCurrentDialogWithButton(0)
                                                    show_main_dialog = true
                                                end
                                            end
                                        elseif list == 3 then
                                            while not show_main_dialog or show_dialog_6409 do

                                                local render_info = {}
                                                render_info[1] = set.AdmodRenderSettings.Status and "{33aa33}[ON]" or "{ff6347}[OFF]"
                                                render_info[2] = set.AdmodRenderSettings.Font
                                                render_info[3] = set.AdmodRenderSettings.Size

                                                local dialogText = cyr("{87CEEB}1.{FFFFFF} Состояние: "..render_info[1].."\n{87CEEB}2.{FFFFFF} Шрифт: {6495ED}"..render_info[2].."\n{87CEEB}3.{FFFFFF} Размер шрифта: {6495ED}"..render_info[3].."\n{87CEEB}4.{FFFFFF} Настройки содержимого")
                                                sampShowDialog(6409, cyr("{87CEEB}"..script_name.." — ADMOD-рендер{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Назад"), 2)
                                                while sampIsDialogActive(6409) do wait(100) end
                                                local result, button, list, _ = sampHasDialogRespond(6409)
                                                if result then
                                                    if button == 1 then
                                                        if list == 0 then
                                                            set.AdmodRenderSettings.Status = not set.AdmodRenderSettings.Status
                                                            inicfg.save(set, direction)
                                                        elseif list == 1 then
                                                            if set.AdmodRenderSettings.Status then
                                                                local dialogText = cyr("{FFFFFF}Текущий шрифт: {6495ED}"..set.AdmodRenderSettings.Font.."{FFFFFF}.\n\nВведите название нового шрифта в поле диалога ниже,\nесли шрифт не поменяется, значит таковой отсутствует\nна Вашем компьютере.")
                                                                sampShowDialog(6410, cyr("{87CEEB}"..script_name.." — Настройка шрифта{FFFFFF}"), dialogText, cyr("ОК"), cyr("Назад"), 1)
                                                                while sampIsDialogActive(6410) do wait(100) end
                                                                local result, button, _, input = sampHasDialogRespond(6410)
                                                                if result then
                                                                    if button == 1 then
                                                                        if input ~= "" then
                                                                            if input:find("^[^%s^%d+].+[^%s]$") then
                                                                                if input ~= set.AdmodRenderSettings.Font then

                                                                                    local function stringToArray(str)
                                                                                        local t = {}
                                                                                        for i = 1, #str do
                                                                                            t[i] = str:sub(i, i)
                                                                                        end
                                                                                        return t
                                                                                    end
                                                                                    
                                                                                    local str_table = stringToArray(input)
                                                                                    local input = string.upper(str_table[1])
                                                                                    table.remove(str_table, 1)
                                                                                    for _, v in pairs(str_table) do
                                                                                        input = input..v
                                                                                    end

                                                                                    set.AdmodRenderSettings.Font = input:gsub("[%./:%?%*%-%+%%%^%$]", ""); inicfg.save(set, direction)
                                                                                    renderFont = renderCreateFont(set.AdmodRenderSettings.Font, set.AdmodRenderSettings.Size, font_flag.BOLD + font_flag.BORDER + font_flag.SHADOW)
                                                                                else
                                                                                    sampAddChatMessage(cyr("В текущий момент итак установлен шрифт "..set.AdmodRenderSettings.Font.."."), -1)
                                                                                end
                                                                            else
                                                                                sampAddChatMessage(cyr("В названии шрифта присутствуют некорректные символы, либо же в строке находятся лишние пробелы. Укажите наименование корректно."), -1)
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
                                                                local dialogText = cyr("{FFFFFF}Текущий размер шрифта: {6495ED}"..set.AdmodRenderSettings.Size.."{FFFFFF}.\nРазмер шрифта задаётся исключительно в целочисленном формате.\nРазмер шрифта НЕ может быть меньше {6495ED}6{FFFFFF} и больше {6495ED}45{FFFFFF}.")
                                                                sampShowDialog(6411, cyr("{87CEEB}"..script_name.." — Настройка размера шрифта{FFFFFF}"), dialogText, cyr("ОК"), cyr("Назад"), 1)
                                                                while sampIsDialogActive(6411) do wait(100) end
                                                                local result, button, _, input = sampHasDialogRespond(6411)
                                                                if result then
                                                                    if button == 1 then
                                                                        if input ~= "" then
                                                                            if input:find("^%d+$") then
                                                                                local input = tonumber(input)
                                                                                if input ~= set.AdmodRenderSettings.Size then
                                                                                    if input <= 45 and input >= 6 then
                                                                                        set.AdmodRenderSettings.Size = input
                                                                                        inicfg.save(set, direction)
                                                                                        renderFont = renderCreateFont(set.AdmodRenderSettings.Font, set.AdmodRenderSettings.Size, font_flag.BOLD + font_flag.BORDER + font_flag.SHADOW)
                                                                                    else
                                                                                        sampAddChatMessage(cyr("Размер шрифта должен быть не меньше 6 и не больше 45 пунктов."), -1)
                                                                                    end
                                                                                else
                                                                                    sampAddChatMessage(cyr("В текущий момент итак установлено данное значение ("..set.AdmodRenderSettings.Font..")."), -1)
                                                                                end
                                                                            else
                                                                                sampAddChatMessage(cyr("Данные введены в неверном формате или найдены некорректные для размера шрифта символы."), -1)
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
                                                                show_dialog_6409 = false
                                                                while not show_dialog_6409 do

                                                                    local render_info = {}
                                                                    render_info[1] = set.AdmodRenderSettings.RenderCurSessionAds and "{33aa33}[ON]" or "{ff6347}[OFF]" 
                                                                    render_info[2] = set.AdmodRenderSettings.RenderAllAds and "{33aa33}[ON]" or "{ff6347}[OFF]"
                                                                    render_info[3] = set.AdmodRenderSettings.RenderRejAds and "{33aa33}[ON]" or "{ff6347}[OFF]"
                                                                    render_info[4] = set.AdmodRenderSettings.RenderEarnedMoney and "{33aa33}[ON]" or "{ff6347}[OFF]"

                                                                    local dialogText = cyr("Отображать количество объявлений, отредактированных за текущую сессию\t"..render_info[1].."\nОтображать количество объявлений, отредактированных за всё время\t\t"..render_info[2].."\nОтображать количество отклонённых объявлений\t\t\t\t\t"..render_info[3].."\nОтображать количество заработанных денег при помощи редакции\t\t\t"..render_info[4])
                                                                    sampShowDialog(6412, cyr("{87CEEB}"..script_name.." — Содержимое ADMOD-рендера{FFFFFF}"), dialogText, cyr("Выбор"), cyr("Назад"), 2)
                                                                    while sampIsDialogActive(6412) do wait(100) end
                                                                    local result, button, list, _ = sampHasDialogRespond(6412)
                                                                    if result then
                                                                        if button == 1 then
                                                                            if list == 0 then 
                                                                                set.AdmodRenderSettings.RenderCurSessionAds = not set.AdmodRenderSettings.RenderCurSessionAds
                                                                            elseif list == 1 then 
                                                                                set.AdmodRenderSettings.RenderAllAds = not set.AdmodRenderSettings.RenderAllAds
                                                                            elseif list == 2 then 
                                                                                set.AdmodRenderSettings.RenderRejAds = not set.AdmodRenderSettings.RenderRejAds
                                                                            elseif list == 3 then 
                                                                                set.AdmodRenderSettings.RenderEarnedMoney = not set.AdmodRenderSettings.RenderEarnedMoney
                                                                            end
                                                                            inicfg.save(set, direction)
                                                                        else
                                                                            sampCloseCurrentDialogWithButton(0)
                                                                            show_dialog_6409 = true
                                                                        end
                                                                    end
                                                                end
                                                            else
                                                                sampAddChatMessage(cyr("Для кастомизации рендера ADMOD'а, необходимо его включить."), -1)
                                                            end
                                                        end
                                                    else
                                                        sampCloseCurrentDialogWithButton(0)
                                                        show_main_dialog = true
                                                        show_dialog_6409 = false
                                                    end
                                                end
                                            end
                                        end
                                        wait(15)
                                    end
                                else
                                    sampCloseCurrentDialogWithButton(0)
                                    show_main_dialog = false
                                    is_script_dialogs_working = false
                                end
                            end
                        end
                        wait(15)
                    end  
                end)
            end

            function sampev.onServerMessage(color, text)
                if isPlayerOnTrinity() and color == -290866945 then
                    if set.AdSettings.AutoAdmod and text:find(cyr("На модерацию поступило новое объявление%. .+")) and not isGamePaused() then 
                        if not sampIsDialogActive() then 
                            sampSendChat("/admod")
                        else
                            local AdmodInfo = true
                            for _, v in pairs({3420, 3422, 3423, 3425, 3421}) do
                                if sampGetCurrentDialogId() == v then
                                    noAdmodInfo = false; break
                                end
                            end
                            if noAdmodInfo and not is_script_dialogs_working then
                                sampAddChatMessage(cyr("Автоматический /admod отклонен, открыто другое диалоговое окно."), -1)
                            end
                        end
                    elseif set.MessageSettings.IgnoringStateAdvertising and text:find(cyr("^%[Гос. реклама%].+")) then 
                        return false
                    elseif set.MessageSettings.IgnoringRegularAdvertising and text:find(cyr("^%[Реклама %a+%].+")) then 
                        return false
                    elseif set.MessageSettings.IgnoringRadioBroadcasts and text:find(cyr("^%[Радио %a+%] .+")) then 
                        return false
                    elseif set.MessageSettings.IgnoringNotifications and text:find(cyr("На модерацию поступило новое объявление%. .+")) then 
                        return false 
                    end
                end
            end

            function sampev.onShowDialog(id, style, _, b1, b2, text)
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
                        ads_acc_counter = ads_acc_counter + 1
                    end
                end
            end

            function sampev.onSendDialogResponse(id, button, list)
                if (id == 3420 or id == 3425) and button == 1 then
                    set.Statistics.AdsPerAllTime = set.Statistics.AdsPerAllTime + 1
                    set.Statistics.Money = set.Statistics.Money + 2; inicfg.save(set, direction)
                    ads_acc_counter = ads_acc_counter + 1
                elseif id == 3422 and button == 1 and list == 0 then
                    ads_rej_counter = ads_rej_counter + 1
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
                                            if status1 == dlstatus.STATUS_ENDDOWNLOADDATA then
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
                            sampAddChatMessage(cyr(prefix.."v"..thisScript().version.." – не получилось обработать информацию о новых обновлениях."), -1)
                            update = false
                        end -- does file exist
                    end -- status == dlstatus.STATUSEX_ENDDOWNLOAD
                end) -- function in download
                while update ~= false do 
                    wait(100) 
                end
            end
        end
    end
else
    script:unload()
end
