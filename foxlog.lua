script_name('FoxLog')
script_author('Raccoon')
script_version("1.0")

local imgui_check, imgui			= pcall(require, 'mimgui')
local samp_check, samp				= pcall(require, 'samp.events')
local effil_check, effil			= pcall(require, 'effil')
local requests_check, requests   = pcall(require, 'requests')
local ffi							= require('ffi')
ffi.cdef 'void __stdcall ExitProcess(unsigned int)'
local dlstatus						= require('moonloader').download_status
local encoding						= require('encoding')
encoding.default					= 'CP1251'
u8 = encoding.UTF8

-->> Main Check Libs
if not imgui_check or not samp_check or not effil_check or not requests_check then 
	function main()
		if not isSampfuncsLoaded() or not isSampLoaded() then return end
		while not isSampAvailable() do wait(100) end
		local libs = {
			['Mimgui'] = imgui_check,
			['SAMP.Lua'] = samp_check,
			['Effil'] = effil_check,
         ['Requests'] = requests_check,
		}
		local libs_no_found = {}
		for k, v in pairs(libs) do
			if not v then sampAddChatMessage('[Fox-Log]{FFFFFF} У Вас отсутствует библиотека {FFBF00}' .. k .. '{FFFFFF}. Без неё скрипт {FFBF00}не будет {FFFFFF}работать!', 0xFFBF00); table.insert(libs_no_found, k) end
		end
		sampShowDialog(18364, '{FFBF00}Fox-Log', string.format('{FFFFFF}В Вашей сборке {FFBF00}нету необходимых библиотек{FFFFFF} для работы скрипта.', table.concat(libs_no_found, '\n{FFFFFF}- {7172ee}')), 'Принять', '', 0)
		thisScript():unload()
	end
	return
end

if not doesDirectoryExist(u8(getWorkingDirectory()..'\\foxlog')) then
   if not doesDirectoryExist(getWorkingDirectory()..'\\foxlog\\logo.png') and not doesDirectoryExist(getWorkingDirectory()..'\\foxlog\\EagleSans-Regular.ttf') then
      function main()
	   	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	   	while not isSampAvailable() do wait(100) end
	   	sampAddChatMessage('[Fox-Log]{FFFFFF} Вы не установили файлы для корректной работы скрипта! Установить их можно в BlastHack.', 0x308ad9)
	   	thisScript():unload()
	   end
	   return
   end
end

-->> JSON
function table.assign(target, def, deep)
   for k, v in pairs(def) do
       if target[k] == nil then
           if type(v) == 'table' then
               target[k] = {}
               table.assign(target[k], v)
           else  
               target[k] = v
           end
       elseif deep and type(v) == 'table' and type(target[k]) == 'table' then 
           table.assign(target[k], v, deep)
       end
   end 
   return target
end

function json(path)
	createDirectory(u8(getWorkingDirectory() .. '/FoxLog'))
	local path = u8(getWorkingDirectory() .. '/FoxLog/' .. path)
	local class = {}

	function class:save(array)
		if array and type(array) == 'table' and encodeJson(array) then
			local file = io.open(path, 'w')
			file:write(encodeJson(array))
			file:close()
		else
			msg('Ошибка при сохранении файла конфига!')
		end
	end

	function class:load(array)
		local result = {}
		local file = io.open(path)
		if file then
			result = decodeJson(file:read()) or {}
		end

		return table.assign(result, array, true)
	end

	return class
end

-->> Local Settings
local new = imgui.new
local WinState = new.bool()
local updateFrame = new.bool()
local tab = 1
local updateid
local bankDep = 0
local bankMoney = 0
local givedDep = 0
local givedMoney = 0
local eatKd = false
local lastCall = os.clock()
local launcher = false

local jsonConfig = json('Config.json'):load({ 
   ['notifications'] = {
		inputToken = '',
		inputUser = '',
      join = false,
      damage = false,
      die = false,
      logChat = false,
      dial = false,
      givedItems = false,
      sellCR = false,
      buyLavCR = false,
      buyCR = false,
	  sellLavCR = false,
      payDay = false,
      logAllChat = false,
      hungry = false,
      logCalls = false,
      logpaybank = false,
      logtakebank = false,
      logitemrent = false,
      logitemrentartem = false,
      logcarrent = false,
	  ------------------
		inputTokenST = '7774436858:AAGZzOKByVaApfkDAXkvxbTp_HhsIKhZOhM',
		inputUserST = '-1002451750918',
		usernameicrST = '',
		usernameSTGL = '',
		inputTokenSTVR = '7695278354:AAEU0K9cZAMsJKfPtpRLiDmMGm2OxHPPi3M',
		inputUserSTVR = '-4801289528',
		TokenArtem = '8434435964:AAECjLS4Qx-BWDiMQGHXBYbzEXjPIG2Q-b0',
		UserArtem = '-1003192061539',
      logsellr = true,
	  logfwarn = true,
	  loginv = true,
	  logrank = true,
	  logtag = true,
	  logorgkazna = true,
	  logids = true,
	  logfamkazna = true,
	  other = true,
		usernameST1 = 'Tom_Demure',
		usernameST2 = 'Hazard_Demure',
		usernameST3 = 'Feo_Zotti',
		usernameST4 = 'Vanusha_Demure',
		usernameST5 = 'Baxtovik_Demure',
		usernameST6 = 'Raccoon_Demure',
   },
   ['settings'] = {
      autoQ = false,
      autoOff = false,
      statsCmd = false,
      offCmd = false,
      qCmd = false,
      sendCmd = false,
      eatCmd = false,
   }
})

-->> Notifications Settings
local inputToken, inputUser = imgui.new.char[128](jsonConfig['notifications'].inputToken), imgui.new.char[128](jsonConfig['notifications'].inputUser)
local join = new.bool(jsonConfig['notifications'].join)
local damage = new.bool(jsonConfig['notifications'].damage)
local die = new.bool(jsonConfig['notifications'].die)
local dial = new.bool(jsonConfig['notifications'].dial)
local logChat = new.bool(jsonConfig['notifications'].logChat)
local givedItems = new.bool(jsonConfig['notifications'].givedItems)
local logAllChat = new.bool(jsonConfig['notifications'].logAllChat)
local hungry = new.bool(jsonConfig['notifications'].hungry)
local sellCR = new.bool(jsonConfig['notifications'].sellCR)
local buyLavCR = new.bool(jsonConfig['notifications'].buyLavCR)
local sellLavCR = new.bool(jsonConfig['notifications'].sellLavCR)
local buyCR = new.bool(jsonConfig['notifications'].buyCR)
local payDay = new.bool(jsonConfig['notifications'].payDay)
local logCalls = new.bool(jsonConfig['notifications'].logCalls)
local logpaybank = new.bool(jsonConfig['notifications'].logpaybank)
local logtakebank = new.bool(jsonConfig['notifications'].logtakebank)
local logitemrent = new.bool(jsonConfig['notifications'].logitemrent)
local logitemrentartem = new.bool(jsonConfig['notifications'].logitemrentartem)
local logcarrent = new.bool(jsonConfig['notifications'].logcarrent)
----------------------------------------------------------------
local inputTokenST, inputUserST, usernameicrST = imgui.new.char[128](jsonConfig['notifications'].inputTokenST), imgui.new.char[128](jsonConfig['notifications'].inputUserST), imgui.new.char[128](jsonConfig['notifications'].usernameicrST)
local usernameSTGL = imgui.new.char[128](jsonConfig['notifications'].usernameSTGL)
local usernameST1, usernameST2, usernameST3, usernameST4, usernameST5, usernameST6 = imgui.new.char[128](jsonConfig['notifications'].usernameST1), imgui.new.char[128](jsonConfig['notifications'].usernameST2), imgui.new.char[128](jsonConfig['notifications'].usernameST3), imgui.new.char[128](jsonConfig['notifications'].usernameST4), imgui.new.char[128](jsonConfig['notifications'].usernameST5), imgui.new.char[128](jsonConfig['notifications'].usernameST6)
local inputTokenSTVR, inputUserSTVR = imgui.new.char[128](jsonConfig['notifications'].inputTokenSTVR), imgui.new.char[128](jsonConfig['notifications'].inputUserSTVR)
local TokenArtem, inputUserSTVR = imgui.new.char[128](jsonConfig['notifications'].UserArtem), imgui.new.char[128](jsonConfig['notifications'].inputUserSTVR)
local logsellr = new.bool(jsonConfig['notifications'].logsellr)
local logfwarn = new.bool(jsonConfig['notifications'].logfwarn)
local loginv = new.bool(jsonConfig['notifications'].loginv)
local logrank = new.bool(jsonConfig['notifications'].logrank)
local logtag = new.bool(jsonConfig['notifications'].logtag)
local logorgkazna = new.bool(jsonConfig['notifications'].logorgkazna)
local logfamkazna = new.bool(jsonConfig['notifications'].logfamkazna)
local other = new.bool(jsonConfig['notifications'].other)
----------------------------------------------------------------
local autoQ = new.bool(jsonConfig['settings'].autoQ)
local autoOff = new.bool(jsonConfig['settings'].autoOff)
local statsCmd = new.bool(jsonConfig['settings'].statsCmd)
local qCmd = new.bool(jsonConfig['settings'].qCmd)
local offCmd = new.bool(jsonConfig['settings'].offCmd)
local sendCmd = new.bool(jsonConfig['settings'].sendCmd)
local eatCmd = new.bool(jsonConfig['settings'].eatCmd)

-->> Main
function main()

	sampRegisterChatCommand("lsell", lsell)

	if not isSampfuncsLoaded() or not isSampLoaded() then return end
	while not isSampAvailable() do wait(100) end
   if doesFileExist(getGameDirectory()..'\\_CoreGame.asi') then
      launcher = true
   end
   while not sampIsLocalPlayerSpawned() do wait(5000) end
	sampAddChatMessage('{FFBF00}[Fox-Log] {FFFFFF}Запущен для активации меню, отправьте в чат {FFBF00}/fl',-1)
	sampRegisterChatCommand('fl', function() WinState[0] = not WinState[0] end)
	while true do wait(0)
	end
end

imgui.OnInitialize(function()
	imgui.GetIO().IniFilename = nil
	getTheme()

   fonts = {}
	local glyph_ranges = imgui.GetIO().Fonts:GetGlyphRangesCyrillic()

   -->> Default Font
	imgui.GetIO().Fonts:Clear()
	imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/FoxLog/EagleSans-Regular.ttf'), 20, nil, glyph_ranges)

   -->> Other Fonts
	for k, v in ipairs({15, 18, 20, 25, 30}) do
		fonts[v] = imgui.GetIO().Fonts:AddFontFromFileTTF(u8(getWorkingDirectory() .. '/FoxLog/EagleSans-Regular.ttf'), v, nil, glyph_ranges)
	end

   -->> Logo
	logo = imgui.CreateTextureFromFile(u8(getWorkingDirectory() .. '/FoxLog/logo.png'))
end)

imgui.OnFrame(function() return WinState[0] end,
   function(player)
      imgui.SetNextWindowPos(imgui.ImVec2(select(1, getScreenResolution()) / 2, select(2, getScreenResolution()) / 2), imgui.Cond.FirstUseEver, imgui.ImVec2(0.5, 0.5))
	  	imgui.SetNextWindowSize(imgui.ImVec2(1000, 475), imgui.Cond.FirstUseEver)
      imgui.Begin(thisScript().name, window, imgui.WindowFlags.NoResize + imgui.WindowFlags.NoCollapse + imgui.WindowFlags.NoTitleBar + imgui.WindowFlags.AlwaysUseWindowPadding)
      imgui.BeginGroup()
         imgui.SetCursorPosY(30 / 2)
         imgui.Image(logo, imgui.ImVec2(200, 130))
         imgui.SetCursorPosY(160)
         if imgui.AnimButton(u8'Уведомления ST', imgui.ImVec2(200,40), 30) then tab = 1 end
         if imgui.AnimButton(u8'Уведомления USER', imgui.ImVec2(200,40), 30) then tab = 2 end
         if imgui.AnimButton(u8'Обновления', imgui.ImVec2(200,40), 30) then tab = 3 end
         if imgui.AnimButton(u8'Настройки', imgui.ImVec2(200,40), 30) then tab = 4 end
         if imgui.AnimButton(u8'Автор', imgui.ImVec2(200,40), 30) then tab = 5 end
      imgui.EndGroup()
      imgui.SameLine()
      imgui.BeginChild('##right', imgui.ImVec2(-1, -1), true, imgui.WindowFlags.NoScrollbar)
      if tab == 1 then
		imgui.PushFont(fonts[30])
				imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8('Cкрипт: Fox-Log')).x) / 2)
				imgui.Text(u8('Скрипт:'))
				imgui.SameLine()
				imgui.TextColoredRGB('{FFBF00}Fox-Log')
			imgui.PopFont()
		imgui.PushFont(fonts[15])
			imgui.Text(u8('1 Шаг: Открываем Telegram и заходим в чат: Demure | Логи'))
			imgui.Text(u8('2 Шаг: Открываем закреплённые сообщение'))
			imgui.Text(u8('3 Шаг: Копируем: "Токен" вставляем в 1 строчку'))
			imgui.Text(u8('4 Шаг: Копируем: "Юзер ID" вставляем в 2 строчку'))
			imgui.Text(u8('5 Шаг: В 3 поле напишите своё ник без фамилии и _'))
			imgui.Text(u8('6 Шаг: Нажмите на Тестовое сообщение и проверьте чат: Demure | Логи'))
			imgui.PopFont()
			imgui.NewLine()
			imgui.SetCursorPosY(240)
			imgui.CenterText(u8(' Данные для бота:'))
         imgui.SetCursorPosX((imgui.GetWindowWidth() - 300) / 2)
			imgui.BeginGroup()
				imgui.PushItemWidth(300)
					if imgui.InputTextWithHint('##inputTokenST', u8('Введите токен'), inputTokenST, ffi.sizeof(inputTokenST), imgui.InputTextFlags.Password) then
						jsonConfig['notifications'].inputTokenST = ffi.string(inputTokenST)
						json('Config.json'):save(jsonConfig)
					end
					if imgui.InputTextWithHint('##inputUserST', u8('Введите ID юзера'), inputUserST, ffi.sizeof(inputUserST), imgui.InputTextFlags.Password) then
						jsonConfig['notifications'].inputUserST = ffi.string(inputUserST)
						json('Config.json'):save(jsonConfig)
					end
					if imgui.InputTextWithHint('##usernameicrST', u8('Введите свой TAG'), usernameicrST, ffi.sizeof(usernameicrST)) then
						jsonConfig['notifications'].usernameicrST = ffi.string(usernameicrST)
						json('Config.json'):save(jsonConfig)
					end
					if imgui.InputTextWithHint('##usernameSTGL', u8('Введите свой ник с _'), usernameSTGL, ffi.sizeof(usernameSTGL)) then
						jsonConfig['notifications'].usernameSTGL = ffi.string(usernameSTGL)
						json('Config.json'):save(jsonConfig)
					end
				imgui.PopItemWidth()
				if imgui.AnimButton(u8('Тестовое сообщение'), imgui.ImVec2(300), 30) then
					sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ': Тестовое сообщение! V1.0')
				end
			imgui.EndGroup()
      elseif tab == 2 then
		imgui.PushFont(fonts[30])
				imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8('Cкрипт: Fox-Log')).x) / 2)
				imgui.Text(u8('Скрипт:'))
				imgui.SameLine()
				imgui.TextColoredRGB('{FFBF00}Fox-Log')
			imgui.PopFont()
		imgui.PushFont(fonts[15])
			imgui.Text(u8('1 Шаг: Открываем Telegram и заходим в бота «@BotFather»')); imgui.SameLine(); imgui.Link('(https://t.me/BotFather)', 'https://t.me/BotFather')
			imgui.Text(u8('2 Шаг: Вводим команду «/newbot» и следуем инструкциям'))
			imgui.Text(u8('3 Шаг: После успешного создания бота Вы получите токен')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Пример сообщения с токеном:')); imgui.SameLine(); imgui.TextDisabled('Use this token to access the HTTP API: 6123464634:AAHgee28hWg5yCFICHfeew231pmKhh19c')
			imgui.Text(u8('4 Шаг: Переходим в бота и жмём кнопку "старт"'))
			imgui.Text(u8('5 Шаг: Вам нужно узнать ID своего юзера. Для этого я использовал бота «@getmyid_bot»')); imgui.SameLine(); imgui.Link('(https://t.me/getmyid_bot)', 'https://t.me/getmyid_bot')
			imgui.Text(u8('6 Шаг: Пишем боту «@getmyid_bot» в личку и Вам отправится ID Вашего юзера в поле «Your user ID»')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Пример сообщения с ID юзера:')); imgui.SameLine(); imgui.TextDisabled('Your user ID: 1950130')
			imgui.Text(u8('7 Шаг: Теперь нам нужно ввести токен и ID юзера в поля ниже. После нажмите на кнопку «Тестовое сообщение» в скрипте')); imgui.NewLine(); imgui.SameLine(20); imgui.Text(u8('· Если Вам в личку отправится сообщение, то Вы всё сделали правильно'))
			imgui.PopFont()
			imgui.NewLine()
			imgui.SetCursorPosY(300)
			imgui.CenterText(u8(' Данные для бота:'))
         imgui.SetCursorPosX((imgui.GetWindowWidth() - 300) / 2)
			imgui.BeginGroup()
				imgui.PushItemWidth(300)
					if imgui.InputTextWithHint('##inputToken', u8('Введите токен'), inputToken, ffi.sizeof(inputToken), imgui.InputTextFlags.Password) then
						jsonConfig['notifications'].inputToken = ffi.string(inputToken)
						json('Config.json'):save(jsonConfig)
					end
					if imgui.InputTextWithHint('##inputUser', u8('Введите ID юзера'), inputUser, ffi.sizeof(inputUser), imgui.InputTextFlags.Password) then
						jsonConfig['notifications'].inputUser = ffi.string(inputUser)
						json('Config.json'):save(jsonConfig)
					end
				imgui.PopItemWidth()
				if imgui.AnimButton(u8('Тестовое сообщение'), imgui.ImVec2(300), 30) then
					sendTelegramNotification('Fox-Log\n\nТестовое сообщение!')
				end
			imgui.EndGroup()
      elseif tab == 3 then
         imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Список Обновлений:'), 30).x) / 2 )
			imgui.FText(u8('Список Обновлений:'), 30)
         imgui.BeginChild('news', imgui.ImVec2(-1, -1), false)
            imgui.BeginChild('##update6.0', imgui.ImVec2(-1, 80), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.6'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.6'), 30)
            imgui.FText(u8'- Добавлена логирование прочее', 18)
            date_text = u8('От ') .. '03.08.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update5.0', imgui.ImVec2(-1, 80), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.5'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.5'), 30)
            imgui.FText(u8'- Добавлена строчка 5 зама', 18)
            date_text = u8('От ') .. '26.07.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update4.2', imgui.ImVec2(-1, 120), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.4.2'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.4.2'), 30)
            imgui.FText(u8'- Убрана команда /lsell', 18)
            imgui.FText(u8'- Добавлены в настройки: UNLog LIST', 18)
            imgui.FText(u8'- В меню ST добавлена функция ввода своего ника', 18)
            date_text = u8('От ') .. '13.06.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update4.1', imgui.ImVec2(-1, 120), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.4.1'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.4.1'), 30)
            imgui.FText(u8'- Убраны лишние строчки логов (переведены в один синхрон)', 18)
            imgui.FText(u8'- Переделана система логирование продажи рангов', 18)
            imgui.FText(u8'- Для логирования продажи рангов добавлена команда: /lsell', 18)
            date_text = u8('От ') .. '11.06.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update4', imgui.ImVec2(-1, 140), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.4'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.4'), 30)
            imgui.FText(u8'- Исправлен баг с ошибочным легированием предметов которых вы не скупали', 18)
            imgui.FText(u8'- Добавлена система логирования банка Получение/Отправление денег', 18)
            imgui.FText(u8'- Добавлена система логирования аренды', 18)
            imgui.FText(u8'- Исправлен баг с системой PayDay', 18)
            date_text = u8('От ') .. '08.06.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update3', imgui.ImVec2(-1, 90), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.3'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.3'), 30)
            imgui.FText(u8'- Добавлена система логирования казны семьи пополнение/снятие', 18)
            imgui.FText(u8'- Исправлена ошибка логирования своего ид', 18)
            date_text = u8('От ') .. '10.01.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update2', imgui.ImVec2(-1, 90), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.2'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.2'), 30)
            imgui.FText(u8'- Добавлена система логирования фракции', 18)
            imgui.FText(u8'- В пункт: Уведомления добавлена функция ввода тега', 18)
            date_text = u8('От ') .. '08.01.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
			   imgui.EndChild()
            imgui.BeginChild('##update1', imgui.ImVec2(-1, 70), true)
            imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Обновление #0.1'), 30).x) / 2 )
            imgui.FText(u8('Обновление #0.1'), 30)
            imgui.FText(u8'- Взята основа от автора: nist1', 18)
            date_text = u8('От ') .. '05.01.2025'
				imgui.SetCursorPos(imgui.ImVec2(imgui.GetWindowWidth() - getSize(date_text, 18).x - 5, 5))
				imgui.FText('{TextDisabled}' .. date_text, 18)
            imgui.EndChild()
         imgui.EndChild()
      elseif tab == 5 then
         imgui.PushFont(fonts[30])
				imgui.SetCursorPosX((imgui.GetWindowWidth() - imgui.CalcTextSize(u8('Автор скрипта: Raccoon')).x) / 2)
				imgui.Text(u8('Автор скрипта:'))
				imgui.SameLine()
				imgui.TextColoredRGB('{209ac9}Raccoon')
			imgui.PopFont()
			imgui.SameLine()
         imgui.SetCursorPos(imgui.ImVec2((imgui.GetWindowWidth() * 1.5 - 700) / 2, (imgui.GetWindowHeight() - 250) / 2))
			imgui.BeginChild('Other', imgui.ImVec2(300, 120), true)
				imgui.CenterText(u8('Небольшая информация:'))
				if imgui.AnimButton(u8('Telegram аккаунт'), imgui.ImVec2(-1, 77.5), 30) then os.execute('explorer https://t.me/yutoraccoon') end
			imgui.EndChild()
		   imgui.SetCursorPosY(imgui.GetWindowHeight() * 0.875)
		   imgui.CenterText(u8('Нашли баг/недоработку?'))
		   imgui.CenterText(u8('Свяжитесь с Автором с помощью Telegram.'))
      elseif tab == 4 then
         imgui.SetCursorPosX((imgui.GetWindowWidth() - getSize(u8('Настройки скрипта:'), 30).x) / 2 )
         imgui.FText(u8('Настройки скрипта:'), 30)
         imgui.PushFont(fonts[18])
			imgui.SetCursorPosX((imgui.GetWindowWidth() * 1.5 - 1150) / 2 - 5)
         imgui.BeginChild('settingsNotf', imgui.ImVec2(365, 419), false)
            imgui.StripChild()
            imgui.BeginChild('settingsNotfUnder', imgui.ImVec2(-1, -1), false)
			      imgui.CenterText(u8('Настройки уведомлений:'))
               if imgui.Checkbox(u8' Логирование входа/выхода из игры', join) then
                  jsonConfig['notifications'].join = join[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('join', u8'При входе/выходе в игру\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8' Логирование здоровья персонажа', damage) then
                  jsonConfig['notifications'].damage = damage[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('damage', u8'При изменении здоровья\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8' Логирование смерти персонажа', die) then
                  jsonConfig['notifications'].die = die[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('die', u8'При смерти персонажа\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8' Логирование RP/NRP чата', logChat) then
                  if jsonConfig['notifications'].logAllChat then
                     logAllChat[0] = false
                     jsonConfig['notifications'].logChat = logChat[0]
                     jsonConfig['notifications'].logAllChat = logAllChat[0]
                     json('Config.json'):save(jsonConfig)
                     msg('Вы не можете одновременно включить эти две функции!')
                  elseif not jsonConfig['notifications'].logAllChat then
                     jsonConfig['notifications'].logChat = logChat[0]
                     json('Config.json'):save(jsonConfig)
                  end
               end
               imgui.Hint('logChat', u8'Отправляет RP и NonRP чат в Telegram.')
               if imgui.Checkbox(u8" Логирование всего чата", logAllChat) then
                  if jsonConfig['notifications'].logChat then
                     logChat[0] = false
                     jsonConfig['notifications'].logChat = logChat[0]
                     jsonConfig['notifications'].logAllChat = logAllChat[0]
                     json('Config.json'):save(jsonConfig)
                     msg('Вы не можете одновременно включить эти две функции!')
                  elseif not jsonConfig['notifications'].logChat then
                     jsonConfig['notifications'].logAllChat = logAllChat[0]
                     json('Config.json'):save(jsonConfig)
                  end
               end
               imgui.Hint('logAllChat', u8"Абсолютно все сообщения из чата\nбудут отправлены в Telegram.")
               if imgui.Checkbox(u8' Логирование открывающихся диалогов', dial) then 
                  jsonConfig['notifications'].dial = dial[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('dial', u8'При открытии диалога Вы получите \nсообщение в Telegram с его содержимым.')
               if imgui.Checkbox(u8' Логирование полученных вещей', givedItems) then
                  jsonConfig['notifications'].givedItems = givedItems[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('givedItems', u8'При получении какого-либо предмета\nВы получите сообщение в Telegram с названием предмета.')
               if imgui.Checkbox(u8' Логирование проданых вещей', sellCR) then
                  jsonConfig['notifications'].sellCR = sellCR[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('sellCR', u8'При продажи какого-либо предмета в лавке\nВы получите сообщение в Telegram с названием предмета и ценой.')
               if imgui.Checkbox(u8' Логирование скупаемых вещей', buyLavCR) then
                  jsonConfig['notifications'].buyLavCR = buyLavCR[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('buyLavCR', u8'При скупки какого-либо предмета в лавке\nВы получите сообщение в Telegram с названием предмета и ценой.')
               if imgui.Checkbox(u8' Логирование купленых вещей', buyCR) then
                  jsonConfig['notifications'].buyCR = buyCR[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('buyCR', u8'При покупки какого-либо предмета с лавки\nВы получите сообщение в Telegram с названием предмета и ценой.')
               if imgui.Checkbox(u8' Логирование проданых вещей в лавку', sellLavCR) then
                  jsonConfig['notifications'].sellLavCR = sellLavCR[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('sellLavCR', u8'При продажи какого-либо предмета в лавку\nВы получите сообщение в Telegram с названием предмета и ценой.')
               if imgui.Checkbox(u8" Логирование получения PayDay'ев", payDay) then
                  jsonConfig['notifications'].payDay = payDay[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('payDay', u8"При получении PayDay'я Вы получите\nсообщение в Telegram с статистикой.")
               if imgui.Checkbox(u8" Логирование голодания персонажа", hungry) then
                  jsonConfig['notifications'].hungry = hungry[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('hungry', u8"Если Вы проголодаетесь, то получите сообщение в Telegram.")
               if imgui.Checkbox(u8' Логирование получение денег на банк', logpaybank) then
                  jsonConfig['notifications'].logpaybank = logpaybank[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('logpaybank', u8'При получение денег на банк от игрока\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8' Логирование перевода денег с банка', logtakebank) then
                  jsonConfig['notifications'].logtakebank = logtakebank[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('logtakebank', u8'При переводе денег с банка игроку\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8' Логирование сдачи аренды ITEM', logitemrent) then
                  jsonConfig['notifications'].logitemrent = logitemrent[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('logitemrent', u8'При сдачи в аренду предметов игрокам\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8' Логирование сдачи аренды CARS', logcarrent) then
                  jsonConfig['notifications'].logcarrent = logcarrent[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('logcarrent', u8'При сдачи в аренду машины игроку\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8' Логирование сдачи аренды ITEM (Artem)', logitemrentartem) then
                  jsonConfig['notifications'].logitemrentartem = logitemrentartem[0]
                  json('Config.json'):save(jsonConfig)
               end
               imgui.Hint('logitemrentartem', u8'При сдачи в аренду машины игроку\nВы получите сообщение в Telegram.')
               if imgui.Checkbox(u8" Логирование входящих вызовов", logCalls) then
                  if launcher then
                     jsonConfig['notifications'].logCalls = logCalls[0]
                     json('Config.json'):save(jsonConfig)
                  elseif not launcher then
                     msg('Данная функция доступна только с лаунчера!')
                     logCalls[0] = false
                  end
               end
               imgui.Hint('logCalls', u8"Если Вам позвонят, то получите сообщение\nв Telegram с именем позвонившего человека.")
            imgui.EndChild()
         imgui.EndChild()

         imgui.SameLine()

         imgui.SetCursorPosX((imgui.GetWindowWidth() * 1.5 - 380) / 2 - 5)
         imgui.BeginChild('settings', imgui.ImVec2(380, 419), false)
            imgui.StripChild()
            imgui.BeginChild('settingsUnder', imgui.ImVec2(-1, -1), false)
            imgui.CenterText(u8('Настройки логера:'))
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: Продажи рангов", logsellr) then
				if jsonConfig['notifications'].logsellr then
                    logsellr[0] = true
                    jsonConfig['notifications'].logsellr = logsellr[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].logsellr then
                    jsonConfig['notifications'].logsellr = logsellr[0]
                    json('Config.json'):save(jsonConfig)
				end
            end
            imgui.Hint('logsellr', u8"Если Вы продадите ранг то получите сообщение в Telegram.")
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: fwarn", logfwarn) then
                if jsonConfig['notifications'].logfwarn then
                    logfwarn[0] = true
                    jsonConfig['notifications'].logfwarn = logfwarn[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].logfwarn then
                    jsonConfig['notifications'].logfwarn = logfwarn[0]
                    json('Config.json'):save(jsonConfig)
				end
			end
            imgui.Hint('logfwarn', u8"Если Вы выдадите игроку выговор то получите сообщение в Telegram.")
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: invite", loginv) then
                if jsonConfig['notifications'].loginv then
                    loginv[0] = true
                    jsonConfig['notifications'].loginv = loginv[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].loginv then
                    jsonConfig['notifications'].loginv = loginv[0]
                    json('Config.json'):save(jsonConfig)
				end
			end
            imgui.Hint('loginv', u8"Если Вы примите игроку в организацию то получите сообщение в Telegram.")
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: giverank", logrank) then
                if jsonConfig['notifications'].logrank then
                    logrank[0] = true
                    jsonConfig['notifications'].logrank = logrank[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].logrank then
                    jsonConfig['notifications'].logrank = logrank[0]
                    json('Config.json'):save(jsonConfig)
				end
			end
            imgui.Hint('logrank', u8"Если Вы понизите игрока то получите сообщение в Telegram.")
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: settag", logtag) then
                if jsonConfig['notifications'].logtag then
                    logtag[0] = true
                    jsonConfig['notifications'].logtag = logtag[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].logtag then
                    jsonConfig['notifications'].logtag = logtag[0]
                    json('Config.json'):save(jsonConfig)
				end
			end
            imgui.Hint('logtag', u8"Если Вы удалите игроку тег то получите сообщение в Telegram.")
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: ORG Казны", logorgkazna) then
                if jsonConfig['notifications'].logorgkazna then
                    logorgkazna[0] = true
                    jsonConfig['notifications'].logorgkazna = logorgkazna[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].logorgkazna then
                    jsonConfig['notifications'].logorgkazna = logorgkazna[0]
                    json('Config.json'):save(jsonConfig)
				end
			end
            imgui.Hint('logorgkazna', u8"Если игрок снимет с счёта организации то вы получите сообщение в Telegram.")
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: FAM Казны", logfamkazna) then
                if jsonConfig['notifications'].logfamkazna then
                    logfamkazna[0] = true
                    jsonConfig['notifications'].logfamkazna = logfamkazna[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].logfamkazna then
                    jsonConfig['notifications'].logfamkazna = logfamkazna[0]
                    json('Config.json'):save(jsonConfig)
				end
			end
            imgui.Hint('logfamkazna', u8"Если игрок пополнит счёт семьи то вы получите сообщение в Telegram.")
			----------------------------------------------------------------------------
            if imgui.Checkbox(u8" Логирование: Прочее", other) then
                if jsonConfig['notifications'].other then
                    other[0] = true
                    jsonConfig['notifications'].other = other[0]
                    json('Config.json'):save(jsonConfig)
                    msg('Куда это мы лезим!!! Ты что проблем захотел?')
                elseif not jsonConfig['notifications'].other then
                    jsonConfig['notifications'].other = other[0]
                    json('Config.json'):save(jsonConfig)
				end
			end
            imgui.Hint('other', u8"Логирование прочих действий")
			----------------------------------------------------------------------------
			imgui.CenterText(u8('Настройки UNLog LIST:'))
			if imgui.InputTextWithHint('##usernameST1', u8('Введите ник заместителя 1'), usernameST1, ffi.sizeof(usernameST1)) then
				jsonConfig['notifications'].usernameST1 = ffi.string(usernameST1)
				json('Config.json'):save(jsonConfig)
			end
			----------------------------------------------------------------------------
			if imgui.InputTextWithHint('##usernameST2', u8('Введите ник заместителя 2'), usernameST2, ffi.sizeof(usernameST2)) then
				jsonConfig['notifications'].usernameST2 = ffi.string(usernameST2)
				json('Config.json'):save(jsonConfig)
			end
			----------------------------------------------------------------------------
			if imgui.InputTextWithHint('##usernameST3', u8('Введите ник заместителя 3'), usernameST3, ffi.sizeof(usernameST3)) then
				jsonConfig['notifications'].usernameST3 = ffi.string(usernameST3)
				json('Config.json'):save(jsonConfig)
			end
			----------------------------------------------------------------------------
			if imgui.InputTextWithHint('##usernameST4', u8('Введите ник заместителя 4'), usernameST4, ffi.sizeof(usernameST4)) then
				jsonConfig['notifications'].usernameST4 = ffi.string(usernameST4)
				json('Config.json'):save(jsonConfig)
			end
			----------------------------------------------------------------------------
			if imgui.InputTextWithHint('##usernameST5', u8('Введите ник заместителя 5'), usernameST5, ffi.sizeof(usernameST5)) then
				jsonConfig['notifications'].usernameST5 = ffi.string(usernameST5)
				json('Config.json'):save(jsonConfig)
			end
			----------------------------------------------------------------------------
			if imgui.InputTextWithHint('##usernameST6', u8('Введите ник лидера'), usernameST6, ffi.sizeof(usernameST6)) then
				jsonConfig['notifications'].usernameST6 = ffi.string(usernameST6)
				json('Config.json'):save(jsonConfig)
			end
			----------------------------------------------------------------------------
            imgui.EndChild()
         imgui.EndChild()
         imgui.PopFont()
      end
      imgui.PushFont(fonts[40])
		imgui.SetCursorPosX(imgui.GetWindowWidth() - 55)
		imgui.SetCursorPosY(5)
		if imgui.AnimButton('X', imgui.ImVec2(50), 30) then WinState[0] = false end
		imgui.PopFont()
      imgui.EndChild()
      imgui.End()
   end
)

-->> Mimgui Snippets
function bringVec4To(from, to, start_time, duration)
   local timer = os.clock() - start_time
   if timer >= 0.00 and timer <= duration then
       local count = timer / (duration / 100)
       return imgui.ImVec4(
           from.x + (count * (to.x - from.x) / 100),
           from.y + (count * (to.y - from.y) / 100),
           from.z + (count * (to.z - from.z) / 100),
           from.w + (count * (to.w - from.w) / 100)
       ), true
   end
   return (timer > duration) and to or from, false
end

function imgui.AnimButton(label, size, duration)
   if type(duration) ~= "table" then
       duration = { 1.0, 0.3 }
   end

   local cols = {
       default = imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.Button]),
       hovered = imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.ButtonHovered]),
       active  = imgui.ImVec4(imgui.GetStyle().Colors[imgui.Col.ButtonActive])
   }

   if UI_ANIMBUT == nil then
       UI_ANIMBUT = {}
   end
   if not UI_ANIMBUT[label] then
       UI_ANIMBUT[label] = {
           color = cols.default,
           clicked = { nil, nil },
           hovered = {
               cur = false,
               old = false,
               clock = nil,
           }
       }
   end
   local pool = UI_ANIMBUT[label]

   if pool["clicked"][1] and pool["clicked"][2] then
       if os.clock() - pool["clicked"][1] <= duration[2] then
           pool["color"] = bringVec4To(
               pool["color"],
               cols.active,
               pool["clicked"][1],
               duration[2]
           )
           goto no_hovered
       end

       if os.clock() - pool["clicked"][2] <= duration[2] then
           pool["color"] = bringVec4To(
               pool["color"],
               pool["hovered"]["cur"] and cols.hovered or cols.default,
               pool["clicked"][2],
               duration[2]
           )
           goto no_hovered
       end
   end

   if pool["hovered"]["clock"] ~= nil then
       if os.clock() - pool["hovered"]["clock"] <= duration[1] then
           pool["color"] = bringVec4To(
               pool["color"],
               pool["hovered"]["cur"] and cols.hovered or cols.default,
               pool["hovered"]["clock"],
               duration[1]
           )
       else
           pool["color"] = pool["hovered"]["cur"] and cols.hovered or cols.default
       end
   end

   ::no_hovered::

   imgui.PushStyleColor(imgui.Col.Button, imgui.ImVec4(pool["color"]))
   imgui.PushStyleColor(imgui.Col.ButtonHovered, imgui.ImVec4(pool["color"]))
   imgui.PushStyleColor(imgui.Col.ButtonActive, imgui.ImVec4(pool["color"]))
   local result = imgui.Button(label, size or imgui.ImVec2(0, 0))
   imgui.PopStyleColor(3)

   if result then
       pool["clicked"] = {
           os.clock(),
           os.clock() + duration[2]
       }
   end

   pool["hovered"]["cur"] = imgui.IsItemHovered()
   if pool["hovered"]["old"] ~= pool["hovered"]["cur"] then
       pool["hovered"]["old"] = pool["hovered"]["cur"]
       pool["hovered"]["clock"] = os.clock()
   end

   return result
end

function imgui.Hint(str_id, hint_text, color, no_center)
   color = color or imgui.GetStyle().Colors[imgui.Col.PopupBg]
   local p_orig = imgui.GetCursorPos()
   local hovered = imgui.IsItemHovered()
   imgui.SameLine(nil, 0)

   local animTime = 0.2
   local show = true

   if not POOL_HINTS then POOL_HINTS = {} end
   if not POOL_HINTS[str_id] then
       POOL_HINTS[str_id] = {
           status = false,
           timer = 0
       }
   end

   if hovered then
       for k, v in pairs(POOL_HINTS) do
           if k ~= str_id and os.clock() - v.timer <= animTime  then
               show = false
           end
       end
   end

   if show and POOL_HINTS[str_id].status ~= hovered then
       POOL_HINTS[str_id].status = hovered
       POOL_HINTS[str_id].timer = os.clock()
   end

   local getContrastColor = function(col)
       local luminance = 1 - (0.299 * col.x + 0.587 * col.y + 0.114 * col.z)
       return luminance < 0.5 and imgui.ImVec4(0, 0, 0, 1) or imgui.ImVec4(1, 1, 1, 1)
   end

   local rend_window = function(alpha)
       local size = imgui.GetItemRectSize()
       local scrPos = imgui.GetCursorScreenPos()
       local DL = imgui.GetWindowDrawList()
       local center = imgui.ImVec2( scrPos.x - (size.x / 2), scrPos.y + (size.y / 2) - (alpha * 4) + 10 )
       local a = imgui.ImVec2( center.x - 7, center.y - size.y - 3 )
       local b = imgui.ImVec2( center.x + 7, center.y - size.y - 3)
       local c = imgui.ImVec2( center.x, center.y - size.y + 3 )
       local col = imgui.ColorConvertFloat4ToU32(imgui.ImVec4(color.x, color.y, color.z, alpha))

       DL:AddTriangleFilled(a, b, c, col)
       imgui.SetNextWindowPos(imgui.ImVec2(center.x, center.y - size.y - 3), imgui.Cond.Always, imgui.ImVec2(0.5, 1.0))
       imgui.PushStyleColor(imgui.Col.PopupBg, color)
       imgui.PushStyleColor(imgui.Col.Border, color)
       imgui.PushStyleColor(imgui.Col.Text, getContrastColor(color))
       imgui.PushStyleVarVec2(imgui.StyleVar.WindowPadding, imgui.ImVec2(8, 8))
       imgui.PushStyleVarFloat(imgui.StyleVar.WindowRounding, 6)
       imgui.PushStyleVarFloat(imgui.StyleVar.Alpha, alpha)

       local max_width = function(text)
           local result = 0
           for line in text:gmatch('[^\n]+') do
               local len = imgui.CalcTextSize(line).x
               if len > result then
                   result = len
               end
           end
           return result
       end

       local hint_width = max_width(hint_text) + (imgui.GetStyle().WindowPadding.x * 2)
       imgui.SetNextWindowSize(imgui.ImVec2(hint_width, -1), imgui.Cond.Always)
       imgui.Begin('##' .. str_id, _, imgui.WindowFlags.Tooltip + imgui.WindowFlags.NoResize + imgui.WindowFlags.NoScrollbar + imgui.WindowFlags.NoTitleBar)
           for line in hint_text:gmatch('[^\n]+') do
               if no_center then
                   imgui.Text(line)
               else
                   imgui.SetCursorPosX((hint_width - imgui.CalcTextSize(line).x) / 2)
                   imgui.Text(line)
               end
           end
       imgui.End()

       imgui.PopStyleVar(3)
       imgui.PopStyleColor(3)
   end

   if show then
       local between = os.clock() - POOL_HINTS[str_id].timer
       if between <= animTime then
           local s = function(f)
               return f < 0.0 and 0.0 or (f > 1.0 and 1.0 or f)
           end
           local alpha = hovered and s(between / animTime) or s(1.00 - between / animTime)
           rend_window(alpha)
       elseif hovered then
           rend_window(1.00)
       end
   end

   imgui.SetCursorPos(p_orig)
end

function imgui.StripChild()
	local dl = imgui.GetWindowDrawList()
	local p = imgui.GetCursorScreenPos()
	dl:AddRectFilled(imgui.ImVec2(p.x, p.y), imgui.ImVec2(p.x + 10, p.y + imgui.GetWindowHeight()), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonActive']]), 3, 5)
	imgui.Dummy(imgui.ImVec2(10, imgui.GetWindowHeight()))
	imgui.SameLine()
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function imgui.FText(text, font)
	assert(text)
	local render_text = function(stext)
		local text, colors, m = {}, {}, 1
		while stext:find('{%u%l-%u-%l-}') do
			local n, k = stext:find('{.-}')
			local color = imgui.GetStyle().Colors[imgui.Col[stext:sub(n + 1, k - 1)]]
			if color then
				text[#text], text[#text + 1] = stext:sub(m, n - 1), stext:sub(k + 1, #stext)
				colors[#colors + 1] = color
				m = n
			end
			stext = stext:sub(1, n - 1) .. stext:sub(k + 1, #stext)
		end
		if text[0] then
			for i = 0, #text do
				imgui.TextColored(colors[i] or colors[1], text[i])
				imgui.SameLine(nil, 0)
			end
			imgui.NewLine()
		else imgui.Text(stext) end
	end
	imgui.PushFont(fonts[font])
	render_text(text)
	imgui.PopFont()
end

function rainbow(speed)
   local r = math.floor(math.sin(os.clock() * speed) * 127 + 128) / 255
   local g = math.floor(math.sin(os.clock() * speed + 2) * 127 + 128) / 255
   local b = math.floor(math.sin(os.clock() * speed + 4) * 127 + 128) / 255
   return r, g, b, 1
end

function getSize(text, font)
	assert(text)
	imgui.PushFont(fonts[font])
	local size = imgui.CalcTextSize(text)
	imgui.PopFont()
	return size
end

function imgui.CenterText(text, size)
	local size = size or imgui.GetWindowWidth()
	imgui.SetCursorPosX((size - imgui.CalcTextSize(tostring(text)).x) / 2)
	imgui.Text(tostring(text))
end

function imgui.Link(name, link, size)
	local size = size or imgui.CalcTextSize(name)
	local p = imgui.GetCursorScreenPos()
	local p2 = imgui.GetCursorPos()
	local resultBtn = imgui.InvisibleButton('##'..link..name, size)
	if resultBtn then os.execute('explorer '..link) end
	imgui.SetCursorPos(p2)
	if imgui.IsItemHovered() then
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']], name)
		imgui.GetWindowDrawList():AddLine(imgui.ImVec2(p.x, p.y + size.y), imgui.ImVec2(p.x + size.x, p.y + size.y), imgui.GetColorU32Vec4(imgui.GetStyle().Colors[imgui.Col['ButtonHovered']]))
	else
		imgui.TextColored(imgui.GetStyle().Colors[imgui.Col['ButtonActive']], name)
	end
	return resultBtn
end

function imgui.TextColoredRGB(text)
   local style = imgui.GetStyle()
   local colors = style.Colors
   local ImVec4 = imgui.ImVec4
   local explode_argb = function(argb)
       local a = bit.band(bit.rshift(argb, 24), 0xFF)
       local r = bit.band(bit.rshift(argb, 16), 0xFF)
       local g = bit.band(bit.rshift(argb, 8), 0xFF)
       local b = bit.band(argb, 0xFF)
       return a, r, g, b
   end
   local getcolor = function(color)
       if color:sub(1, 6):upper() == 'SSSSSS' then
           local r, g, b = colors[1].x, colors[1].y, colors[1].z
           local a = tonumber(color:sub(7, 8), 16) or colors[1].w * 255
           return ImVec4(r, g, b, a / 255)
       end
       local color = type(color) == 'string' and tonumber(color, 16) or color
       if type(color) ~= 'number' then return end
       local r, g, b, a = explode_argb(color)
       return imgui.ImVec4(r/255, g/255, b/255, a/255)
   end
   local render_text = function(text_)
       for w in text_:gmatch('[^\r\n]+') do
           local text, colors_, m = {}, {}, 1
           w = w:gsub('{(......)}', '{%1FF}')
           while w:find('{........}') do
               local n, k = w:find('{........}')
               local color = getcolor(w:sub(n + 1, k - 1))
               if color then
                   text[#text], text[#text + 1] = w:sub(m, n - 1), w:sub(k + 1, #w)
                   colors_[#colors_ + 1] = color
                   m = n
               end
               w = w:sub(1, n - 1) .. w:sub(k + 1, #w)
           end
           if text[0] then
               for i = 0, #text do
                   imgui.TextColored(colors_[i] or colors[1], u8(text[i]))
                   imgui.SameLine(nil, 0)
               end
               imgui.NewLine()
           else imgui.Text(u8(w)) end
       end
   end
   render_text(text)
end

function asyncHttpRequest(method, url, args, resolve, reject)
   local request_thread = effil.thread(function (method, url, args)
      local requests = require 'requests'
      local result, response = pcall(requests.request, method, url, args)
      if result then
         response.json, response.xml = nil, nil
         return true, response
      else
         return false, response
      end
   end)(method, url, args)

   if not resolve then resolve = function() end end
   if not reject then reject = function() end end
   --lua_thread.create(function()
      local runner = request_thread
      while true do
         local status, err = runner:status()
         if not err then
            if status == 'completed' then
               local result, response = runner:get()
               if result then
                  resolve(response)
               else
                  reject(response)
               end
               return
            elseif status == 'canceled' then
               return reject(status)
            end
         else
            return reject(err)
         end
         wait(0)
      end
   --end)
end

-->> Other Function
function msg(text)
	sampAddChatMessage(string.format('[%s] {FFFFFF}%s', thisScript().name, text), 0xFFBF00)
end

function samp.onSetPlayerHealth(health)
	if health ~= lastHealth and jsonConfig['notifications'].damage and sampGetGamestate() == 3 then
		sendTelegramNotification('Ваше здоровье изменено!\nТекущее ХП: ' .. health)
	end
	lastHealth = health
end

samp.onShowDialog = function(dialogId, style, title, button1, button2, text)
   if jsonConfig['notifications'].dial and not stats then
      sendTelegramNotification('У вас открылся диалог!\n\n- Содержание диалога:\n'..text)
   end
   if stats and dialogId==235 then
      sendTelegramNotification(title..':\n\n'..text)
      stats = false
      lua_thread.create(function()
         wait(1)
         sampCloseCurrentDialogWithButton(0)
      end)
   end
end

function samp.onDisplayGameText(style, time, text)
   if jsonConfig['notifications'].hungry then
      if text:find('You are hungry!') then
         sendTelegramNotification('Ваш персонаж голоден!')
      elseif text:find('You are very hungry!') then
         sendTelegramNotification('Ваш персонаж сильно голоден!')
      end
   end
end

function samp.onServerMessage(color, text)
   if jsonConfig['settings'].eatCmd then
      if eatKd then
         if text:find('У вас нет мешка с мясом!') and not text:find('%[%d+%]') then
            sendTelegramNotification('У вас нет мешка с мясом!')
            eatKd = false
         end
         if text:find('Использовать мешок с мясом можно раз в 30 минут! Осталось ') and not text:find('%[%d+%]') then
            meatBagKd = text:match('Использовать мешок с мясом можно раз в 30 минут! Осталось (.+)')
            sendTelegramNotification('Вы не можете сейчас использовать мешок! Попробуйте через '..meatBagKd)
            eatKd = false
         end
         if text:find(myNick..' достал%(а%) из мешка за спиной кусок мяса и скушал%(а%)') and not text:find('%[%d+%]') then
            sendTelegramNotification('Вы покушали из мешка с мясом!')
            eatKd = false
         end
         if text:find('У тебя нет чипсов!') and not text:find('%[%d+%]') then
            sendTelegramNotification('У вас нет чипсов!')
            eatKd = false
         end
         if text:find(myNick..' скушал%(а%) пачку чипсов') and not text:find('%[%d+%]') then
            sendTelegramNotification('Вы покушали пачку чипсов!')
            eatKd = false
         end
         if text:find('У тебя нет жареного мяса оленины!') and not text:find('%[%d+%]') then
            sendTelegramNotification('У вас нет жареного мяса оленины!')
            eatKd = false
         end
         if text:find(myNick..' скушал%(а%) жареное мясо оленины') and not text:find('%[%d+%]') then
            sendTelegramNotification('Вы покушали жареное мясо оленины!')
            eatKd = false
         end
         if text:find('У тебя нет жареной рыбы') and not text:find('%[%d+%]') then
            sendTelegramNotification('У вас нет жареной рыбы!')
            eatKd = false
         end
         if text:find(myNick..' скушал%(а%) жареную рыбу') and not text:find('%[%d+%]') then
            sendTelegramNotification('Вы покушали жареную рыбу!')
            eatKd = false
         end
      end
   end
   if text:find('^%s*%(%( Через 30 секунд вы сможете сразу отправиться в больницу или подождать врачей %)%)%s*$') then
      if jsonConfig['notifications'].die then
         sendTelegramNotification('Ваш персонаж умер!')
      end
   end
   if text:find('Общая заработная плата: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         givedMoney = text:match('Общая заработная плата: (.+)')
      end
   end
   if text:find('Текущая сумма в банке: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         bankMoney = text:match('Текущая сумма в банке: (.+)')
      end
   end
   if text:find('Текущая сумма на депозите: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         bankDep = text:match('Текущая сумма на депозите: (.+)')
      end
   end
   if text:find('Депозит в банке: (.+)') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         givedDep = text:match('Депозит в банке: (.+)')
      end
   elseif text:find('Депозит в банке: (.+) %(из них ушло в бюджет семьи: (.+)%)') and not text:find('%[%d+%]') then 
      if jsonConfig['notifications'].payDay then
         givedDep  = text:match('Депозит в банке: (.+)')
      end
   end
   if text:find('__________________________________') and not text:find('%[%d+%]') then 
      if jsonConfig['notifications'].payDay then
         sendTelegramNotification('Вы получили PayDay!\n\nОрганизационная зарплата: '..givedMoney..'\nТекущая сумма в банке: '..bankMoney..'\nТекущая сумма на депозите: '..bankDep) 
      end
   end
   if text:find('Вы не получили зарплату с организации, так как вы сейчас не в рабочей форме!') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].payDay then
         sendTelegramNotification('Ваш персонаж не в рабочей форме!')
      end
   end
   if text:find("Вам был добавлен предмет '(.+)'. Чтобы открыть инвентарь используйте клавишу 'Y' или /invent")  and not text:find('%[%d+%]') and not text:find('говорит') then
      if jsonConfig['notifications'].givedItems then
         local givedItem = text:match("Вам был добавлен предмет '(.+)'. Чтобы открыть инвентарь используйте клавишу 'Y' или /invent")
         sendTelegramNotification('Вам был добавлен предмет "'..givedItem..'"!')
      end
   end
   if text:find("(.-) купил у вас (.-), вы получили (.+) от продажи") and not text:find('%[%d+%]') and not text:find('говорит') then
      if jsonConfig['notifications'].sellCR then
         local PlayerNameCR,ItemCR,MoneyCR = text:match("(.-) купил у вас (.-), вы получили (.+) от продажи")
         sendTelegramNotification('Fox-Log\n\nИгрок: '..PlayerNameCR..'\nКупил у вас: '..ItemCR..'\nВы получили: '..MoneyCR..'')
      end
   end
   if text:find("Вы купили (.-) у игрока (.-) за (.+)") and not text:find('%[%d+%]') and not text:find('говорит') then
      if jsonConfig['notifications'].buyLavCR then
         local ItemCR,PlayerNameCR,MoneyCR = text:match("Вы купили (.-) у игрока (.-) за (.+)")
         sendTelegramNotification('Fox-Log\n\nВы cкупили: '..ItemCR..'\nУ игрока: '..PlayerNameCR..'\nЗа: '..MoneyCR..'')
      end
   end
   if text:find("Вы успешно купили (.-) у (.-) за (.+)") and not text:find('%[%d+%]') and not text:find('говорит') then
      if jsonConfig['notifications'].buyCR then
         local ItemCR,PlayerNameCR,MoneyCR = text:match("Вы успешно купили (.-) у (.-) за (.+)")
         sendTelegramNotification('Fox-Log\n\n(Чужая лавка)\nКупил: '..ItemCR..'\nУ игрока: '..PlayerNameCR..'\nЗа: '..MoneyCR..'')
      end
   end
   if text:find("Вы успешно продали (.-) торговцу (.-) с продажи получили (.+)") and not text:find('%[%d+%]') and not text:find('говорит') then
      if jsonConfig['notifications'].sellLavCR then
         local ItemCR,PlayerNameCR,MoneyCR = text:match("Вы успешно продали (.-) торговцу (.-) с продажи получили (.+)")
         sendTelegramNotification('Fox-Log\n\nВы продали: '..ItemCR..'\nИгроку: '..PlayerNameCR..'\nЗа: '..MoneyCR..'')
      end
   end
   if text:find("Вам поступил перевод на ваш счет в размере (.+) от жителя (.+)") and not text:find('%[%d+%]') and not text:find('говорит') then
      if jsonConfig['notifications'].logpaybank then
         local Money,PlayerName = text:match("Вам поступил перевод на ваш счет в размере (.+) от жителя (.+)")
         sendTelegramNotification('Fox-Log\n\nВам поступил перевод: '..Money..'$\nОт игрока: '..PlayerName..'')
      end
   end
   if text:find("Вы перевели (.+) игроку (.+)") and not text:find('%[%d+%]') and not text:find('говорит') then 
      if jsonConfig['notifications'].logtakebank then
         local Money,PlayerName = text:match("Вы перевели (.+) игроку (.+)")
         sendTelegramNotification('Fox-Log\n\nВы перевели: '..Money..'$\nИгроку: '..PlayerName..'')
      end
   end
   if text:find("Вы успешно сдали предмет (.+) в аренду на (.-) часов за (.+)") and not text:find('говорит') then
      if jsonConfig['notifications'].logitemrent then
         local item,times,money = text:match("Вы успешно сдали предмет (.+) в аренду на (.-) часов за (.+)")
         sendTelegramNotification('Fox-Log\n\nВы сдали в аренду: '..item..'\nНа: '..times..' час(ов)|минут\nЗа: '..money..'')
      end
   end
   if text:find("Вы успешно сдали предмет (.+) в аренду на (.-) часов за (.+)") and not text:find('говорит') and not text:find('%[%d+%]') then
      if jsonConfig['notifications'].logitemrentartem then
         local item,times,money = text:match("Вы успешно сдали предмет (.+) в аренду на (.-) часов за (.+)")
         sendTelegramNotificationArtem('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nCдал в аренду: '..item..'\nНа: '..times..' час(ов)|минут\nЗа: '..money..'')
      end
   end
   if text:find("Вы передали (.+) в аренду игроку (.+) на (.-)ч за (.+)") and not text:find('говорит') then
      if jsonConfig['notifications'].logcarrent then
         local cars,PlayerName,times,money = text:match("Вы передали (.+) в аренду игроку (.+) на (.-)ч за (.+)")
         sendTelegramNotification('Fox-Log\n\nВы сдали в аренду: '..cars..'\nИгроку: '..PlayerName..'\nНа: '..times..' час(ов)|минут\nЗа: '..money..'')
      end
   end
   if jsonConfig['notifications'].logAllChat then
      local logAllChatText = text:gsub('{......}', '')
      sendTelegramNotification(logAllChatText)
   end
   if text:find(".+%[%d+%] говорит:") then 
      if jsonConfig['notifications'].logChat then
         sendTelegramNotification(text)
      end
   end
	if text:find("Вы дали выговор игроку (.-) с причиной (.+)") then
	local PlayerNamelfw,Reasonlfw = text:match("Вы дали выговор игроку (.-) с причиной (.+)")
		if jsonConfig['notifications'].logfwarn then
         local bot_fwarn_blocks = string.format('<b>BOT:</b>\n<code>/iw %s Н.П.С.К - %s</code>', uidlse, Reasonlfw)
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nВыдал(-а) выговор игроку '..PlayerNamelfw..' с причиной: '..Reasonlfw..'\n\n'..bot_fwarn_blocks)
		end
    end
    if text:find("Вы сняли выговор игроку (.+)") then
	local PlayerNamelufw = text:match("Вы сняли выговор игроку (.+)")
		if jsonConfig['notifications'].logfwarn then
         local bot_funwarn_blocks = string.format('<b>BOT:</b>\n<code>/uiw %s</code>', uidlse)
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nСнял(-а) выговор игроку '..PlayerNamelufw..'\n\n'..bot_funwarn_blocks)
		end
    end
   if text:find("{FFFFFF}(.-) принял ваше предложение вступить к вам в организацию.") then
	local PlayerNamelinv = text:match("{FFFFFF}(.-) принял ваше предложение вступить к вам в организацию.")
		if jsonConfig['notifications'].loginv then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nПригласил(-а) в организацию нового игрока: '..PlayerNamelinv..'')
		end
    end
    if text:find("Вы выгнали (.-). Причина: (.+)") then
	local PlayerNamelui,Reasonlui = text:match("Вы выгнали (.-). Причина: (.+)")
		if jsonConfig['notifications'].loginv then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nУволил(-а) из организации игрока: '..PlayerNamelui..' с причиной: '..Reasonlui..'')
		end
    end
    if text:find("Вы повысили игрока (.-) до (%d+)% ранга") then
	local PlayerNamelur,NewRanklur = text:match("Вы повысили игрока (.-) до (%d+)% ранга")
		if jsonConfig['notifications'].logrank then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nПовысил(-а) игрока '..PlayerNamelur..' до: '..NewRanklur..' ранга')
		end
    end
    if text:find("Вы понизили игрока (.-) до (%d+)% ранга") then
	local PlayerNameldr,NewRankldr = text:match("Вы понизили игрока (.-) до (%d+)% ранга")
		if jsonConfig['notifications'].logrank then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nПонизил(-а) игрока '..PlayerNameldr..' на: '..NewRankldr..' ранга')
		end
    end
	if text:find("Вы установили игроку (.+) новый тэг: {cccccc}(.+)") then
	local PlayerNamelst,Taglst = text:match("Вы установили игроку (.+) новый тэг: {cccccc}(.+)")
		if jsonConfig['notifications'].logtag then
         local bot_blocks = string.format('<b>BOT:</b>\n<code>/selltag %s %s</code>', uidlse, Taglst)
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nВыдал(-а) игроку: '..PlayerNamelst..' тег: '..Taglst..'.\n\n'..bot_blocks)
		end
    end
    if text:find("Вы удалили игроку (.+) его тэг: {cccccc}(.+)") then
	local PlayerNamelut,Taglut = text:match("Вы удалили игроку (.+) его тэг: {cccccc}(.+)")
		if jsonConfig['notifications'].logtag then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nСнял(-а) у игрока: '..PlayerNamelut..' тег: '..Taglut..'.')
		end
    end
	if text:find("{FFFFFF}(.-) {73B461}пополнил счет организации на {FFFFFF}$(.+)") then
	local PlayerNamelpm,Moneylpm = text:match("{FFFFFF}(.-) {73B461}пополнил счет организации на {FFFFFF}$(.+)")
		if jsonConfig['notifications'].logorgkazna then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nСотрудник: '..PlayerNamelpm..' пополнил счёт организации на: '..Moneylpm..'.')
		end
    end
    if text:find("{ECB534}(.-) снял с организации $(.+)") then
	local PlayerNameltm,Moneyltm = text:match("{ECB534}(.-) снял с организации $(.+)")
		if jsonConfig['notifications'].logorgkazna then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nСотрудник: '..PlayerNameltm..' снял с счёта организации: '..Moneyltm..'.')
		end
    end
   -- Новое регулярное выражение, которое учитывает цветовой код {8E38EA}, 
   -- спецсимволы валют и любые символы в поле суммы (включая пробелы и точки)
   if text:find("{8E38EA}%[Семья %(Новости%)%] (.+)%[(%d+)%]:{FFFFFF} Пополнил склад семьи на (.+)") then
      local PlayerNamelfpm, PlayerID, Moneylfpm = text:match("{8E38EA}%[Семья %(Новости%)%] (.+)%[(%d+)%]:{FFFFFF} Пополнил склад семьи на (.+)")
      
      if jsonConfig['notifications'].logfamkazna then
         -- Чистим сумму от лишних спецсимволов и иконок для уведомления в Telegram, если нужно,
         -- либо оставляем как есть. Здесь Moneylfpm будет содержать строку вида "? 1 ? 100 ? 100.000"
         sendTelegramNotificationST(jsonConfig['notifications'].usernameicrST .. ':\n\nУчастник семьи: ' .. PlayerNamelfpm .. '[' .. PlayerID .. ']\nПополнил склад семьи на: ' .. Moneylfpm)
      end
   end
    if text:find("%[(.+) (.+)%] (.+)%[(%d+)%]:{FFFFFF} Взял (.+)") then
	local Family, Family2, PlayerNamelftm, PlayerID, Moneylftm = text:match("%[(.+) (.+)%] (.+)%[(%d+)%]:{FFFFFF} Взял (.+)")
		if jsonConfig['notifications'].logfamkazna then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nУчастник семьи: '..PlayerNamelftm..' Взял с склада семьи: '..Moneylftm)
		end
    end
	if text:find("Игрок (.-) принял покупку ранга за (.+).") then
   -- Функция для разделения суммы пробелами (1 000 000)
	local PlayerNamelsr,Moneylsr = text:match("Игрок (.-) принял покупку ранга за (.+).")
        if jsonConfig['notifications'].logsellr then
            sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nПродал(-а) ранг игроку: '..PlayerNamelsr..' ОЛД: '..Moneylsr)
        end
    end
	if text:find("Игрок (.-) принял продление ранга за (.+).") then
	local PlayerNamelsr,Moneylsr = text:match("Игрок (.-) принял продление ранга за (.+).")
        if jsonConfig['notifications'].logsellr then
            sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ':\n\nПродлил(-а) ранг игроку: '..PlayerNamelsr..' ОЛД: '..Moneylsr)
        end
    end
   if text:find('| UID: (.+) |') then
      if jsonConfig['notifications'].logsellr then
         uidlse = text:match("| UID: (.+) |") or "N/A"
      end
   end
   if text:find('приобрести ранг в организации {90EE90}(.+)') then
      if jsonConfig['notifications'].logsellr then
         rangname = text:match("приобрести ранг в организации {90EE90}(.+)") or "N/A"
      end
   end
   if text:find('продлить ранг в организации {90EE90}(.+)') then
      if jsonConfig['notifications'].logsellr then
         rangname = text:match("продлить ранг в организации {90EE90}(.+)") or "N/A"
      end
   end
   if text:find('Игрок (.-) принял покупку ранга за (.+).') then
      if jsonConfig['notifications'].logsellr then
        PlayerNamelsel,Moneyrlse = text:match("Игрок (.-) принял покупку ранга за (.+).")
        PlayerNamelsel = PlayerNamelsel or "N/A"
        Moneyrlse = Moneyrlse or "N/A"
      end
   end
   if text:find('Игрок (.-) принял продление ранга за (.+).') then
      if jsonConfig['notifications'].logsellr then
        PlayerNamelsel,Moneyrlse = text:match("Игрок (.-) принял продление ранга за (.+).")
        PlayerNamelsel = PlayerNamelsel or "N/A"
        Moneyrlse = Moneyrlse or "N/A"
      end
   end
   if text:find('%[(.+) (.+)%] (.-)_(.-)%[(%d+)%]:{FFFFFF} Пополнил склад семьи на (.+)') and text:find(''.. jsonConfig['notifications'].usernameSTGL ..'') then
      if jsonConfig['notifications'].logsellr then
         Family, Family2, PlayerNameI, PlayerNameF, PlayerID, Moneylse = text:match("%[(.+) (.+)%] (.-)_(.-)%[(%d+)%]:{FFFFFF} Пополнил склад семьи на (.+)")
        Family = Family or "N/A"
        Family2 = Family2 or "N/A"
        PlayerNameI = PlayerNameI or "N/A"
        PlayerNameF = PlayerNameF or "N/A"
        PlayerID = PlayerID or "N/A"
        Moneylse = Moneylse or "N/A"
      end
   end
   if text:find('%[(.+) (.+)%] (.-)_(.-)%[(%d+)%]:{FFFFFF} Пополнил склад семьи на (.+)') and text:find(''.. jsonConfig['notifications'].usernameSTGL ..'') then
         if jsonConfig['notifications'].logsellr and PlayerNamelsel and uidlse and rangname and Moneyrlse and Moneylse and PlayerNameI then
         -- Соответствие названия ранга и номера
         local rank_map = {
            ['[:uf257:] Менеджмент'] = 8,
            ['[:uf256:] Специалист'] = 7,
            ['[:uf255:] Страховщик'] = 6,
            ['[:uf254:] Консультант'] = 5
         }
         
         local rangenum = rank_map[rangname] or 'N/A'
         local cleanPlayerNamelsel = PlayerNamelsel:gsub('%b()', ''):gsub('%s+$', '')
         
         -- Очистка суммы от меток :KK: и :K: для строки BOT:
         -- 1. Убираем :KK:
         -- 2. Заменяем :K: на точку
         -- 3. Удаляем все пробелы
         local cleanMoney = Moneyrlse:gsub(':KK:', ''):gsub(':K:', '.'):gsub('%s+', '')

         -- Формируем блок для бота с очищенной ценой
         local bot_block = string.format('<b>BOT:</b>\n<code>/sell %s %s %s %s</code>', uidlse, cleanPlayerNamelsel, rangenum, cleanMoney)
         
         sendTelegramNotificationST(
            (jsonConfig['notifications'].usernameicrST or "Log") ..
            ':\n\nПродал(-а) ранг: ' .. rangname ..
            '\nИгроку: ' .. PlayerNamelsel .. ' | UID: ' .. uidlse ..
            '\nЗа: ' .. Moneyrlse .. '$\nFam pay: ' .. Moneylse .. '$ (50% от суммы) [' .. PlayerNameI .. ']' ..
            '\n\n' .. bot_block
         )
      end
   end
    if text:find("%(%( %S+%[%d+%]: {B7AFAF}.-{FFFFFF} %)%)") then
      local nameNrp, famNrp, idNrp, tNrp = text:match("%(%( (%w+)_(%w+)%[(%d+)%]: {B7AFAF}(.-){FFFFFF} %)%)")
		local idNrpInGame = sampGetCharHandleBySampPlayerId(idNrp)
      if idNrpInGame and jsonConfig['notifications'].logChat then
         sendTelegramNotificationST('(( '..nameNrp..'_'..famNrp..'['..idNrp..']: '..tNrp..' ))')
      end
   end
   if isInsuranceAd(text) and text:find(jsonConfig['notifications'].usernameSTGL) then
        if jsonConfig['notifications'].other then
            sendTelegramNotificationSTVR(jsonConfig['notifications'].usernameicrST .. ": Отправил рекламу в /vr")
        end
    end
   if text:find("отключил рекламу компании в планшете.") and text:find(''.. jsonConfig['notifications'].usernameSTGL ..'') then
	local Name = text:match("отключил рекламу компании в планшете.")
        if jsonConfig['notifications'].other then
			sendTelegramNotificationST('' .. jsonConfig['notifications'].usernameicrST .. ': Завершил рекламу /rvr')
        end
    end
end

local adPhrases = {
    "СТК - зарабатывай на действиях, а не на ожидании!",
    "В СТК платят тем, кто работает,",
    "Страховые сделки в СТК - реальный доход здесь и сейчас!",
    "СТК - активность превращается в деньги!",
    "Хватит стоять - в СТК доход делают руками!",
    "АФК - мимо кассы, в СТК платят за результат!",
    "Ранги СТК - больше сделок, больше прибыли!",
    "В СТК не фармят время - фармят деньги!",
    "СТК - место, где страховки работают на тебя!",
    "Работай, страхуй, зарабатывай - это СТК!",
    "СТК - доход без воды и без АФК!",
    "Хочешь деньги? В СТК их берут действием!"
}

function isInsuranceAd(text)
    for _, phrase in ipairs(adPhrases) do
        -- убираем спецсимволы для корректного pattern matching
        local pattern = phrase:gsub("([%%%^%$%(%)%.%[%]%*%+%-%?])", "%%%1")
        if text:lower():find(pattern:lower()) then
            return true
        end
    end
    return false
end

function onReceivePacket(id, bs)
   if jsonConfig['notifications'].logCalls then
      if id == 220 then
         raknetBitStreamReadInt8(bs);
         if raknetBitStreamReadInt8(bs) == 17 then
            raknetBitStreamReadInt32(bs);
            local lenCall, textCall = raknetBitStreamReadInt32(bs), '';
            if lenCall > 0 then
               textCall = raknetBitStreamReadString(bs, lenCall)
               local eventCall, dataCall = textCall:match('window%.executeEvent%(\'([%w.]+)\',%s*\'(.+)\'%)');
               if eventCall == 'event.call.InitializeCaller' then
                  local okCall, jsonCall = pcall(decodeJson, dataCall)
                  if okCall and jsonCall[1] and (lastCall + 2) < os.clock() then
                     lastCall = os.clock()
                     sendTelegramNotification('Входящий вызов!\nВам звонит '..jsonCall[1])
                  end
               end
            end
         end
      end
   end
	local notificationsJoinLeave = {
		[34] = {'' .. jsonConfig['notifications'].usernameicrST .. ': Подключился к серверу!', 'ID_CONNECTION_REQUEST_ACCEPTED', jsonConfig['notifications'].join},
		[35] = {'Попытка подключения не удалась!', 'ID_CONNECTION_ATTEMPT_FAILED', jsonConfig['notifications'].join},
		[37] = {'Неправильный пароль от сервера!', 'ID_INVALID_PASSWORD', jsonConfig['notifications'].join}
	}
	if notificationsJoinLeave[id] and notificationsJoinLeave[id][3] then
		sendTelegramNotification(notificationsJoinLeave[id][1])
	end
   local notificationsJoinLeaveIfAuto = {
		[32] = {'' .. jsonConfig['notifications'].usernameicrST .. ': Сервер закрыл соединение!', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['notifications'].join},
		[33] = {'' .. jsonConfig['notifications'].usernameicrST .. ': Соединение потеряно!', 'ID_CONNECTION_LOST', jsonConfig['notifications'].join},
	}
	if notificationsJoinLeaveIfAuto[id] and notificationsJoinLeaveIfAuto[id][3] and not jsonConfig['settings'].autoQ and not jsonConfig['settings'].autoOff then
		sendTelegramNotification(notificationsJoinLeaveIfAuto[id][1])
	end
   local LocalAutoQ = {
		[32] = {'' .. jsonConfig['notifications'].usernameicrST .. ': Сервер закрыл соединение!', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['settings'].autoQ},
		[33] = {'' .. jsonConfig['notifications'].usernameicrST .. ': Соединение потеряно!', 'ID_CONNECTION_LOST', jsonConfig['settings'].autoQ},
	}
	if LocalAutoQ[id] and LocalAutoQ[id][3] then
		sendTelegramNotification(LocalAutoQ[id][1]..'\nВаша игра выключена.')
      ffi.C.ExitProcess(0)
	end
   local LocalAutoOff = {
		[32] = {'' .. jsonConfig['notifications'].usernameicrST .. ': Сервер закрыл соединение!', 'ID_DISCONNECTION_NOTIFICATION', jsonConfig['settings'].autoOff},
		[33] = {'' .. jsonConfig['notifications'].usernameicrST .. ': Соединение потеряно!', 'ID_CONNECTION_LOST', jsonConfig['settings'].autoOff},
	}
	if LocalAutoOff[id] and LocalAutoOff[id][3] then
		sendTelegramNotification(LocalAutoOff[id][1]..'\nВаш компьютер выключен.')
      os.execute('shutdown /s /t 5')
	end
end

function threadHandle(runner, url, args, resolve, reject)
   local t = runner(url, args)
   local r = t:get(0)
   while not r do
      r = t:get(0)
      wait(0)
   end
   local status = t:status()
   if status == 'completed' then
      local ok, result = r[1], r[2]
      if ok then resolve(result) else reject(result) end
   elseif err then
      reject(err)
   elseif status == 'canceled' then
      reject(status)
   end
   t:cancel(0)
end

function requestRunner()
    return effil.thread(function(u, a)
        local requests = require 'requests' -- используем библиотеку requests внутри потока
        -- Проверяем, есть ли данные для POST-запроса
        local method = (a and a.data) and 'POST' or 'GET'
        local ok, response = pcall(requests.request, method, u, a)
        if ok then
            return {true, response.text} -- возвращаем текст ответа
        else
            return {false, response}
        end
    end)
end

function async_http_request(url, args, resolve, reject)
   local runner = requestRunner()
   if not reject then reject = function() end end
   lua_thread.create(function()
      threadHandle(runner, url, args, resolve, reject)
   end)
end

function encodeUrl(str)
   str = str:gsub(' ', '%+')
   str = str:gsub('\n', '%%0A')
   return u8:encode(str, 'CP1251')
end

function sendTelegramNotification(msg)
    -- Очистка текста от цветовых кодов
    msg = msg:gsub('{......}', '')

    local body = encodeJson({
        token = jsonConfig['notifications'].inputToken,
        chat_id = jsonConfig['notifications'].inputUser,
        text = u8(msg),
        parse_mode = "HTML"
    })

    -- Асинхронная отправка
    async_http_request('http://us37.glacierhosting.org:3133/log', {
        headers = { ['Content-Type'] = 'application/json; charset=utf-8' },
        data = body,
        method = 'POST'
    }, function(response)
        -- Успешно отправлено
    end, function(err)
        -- Ошибка выведется в консоль MoonLoader (Ctrl+R или ~)
        print("[Fox-Log] Main Log Error: " .. tostring(err))
    end)
end

function sendTelegramNotificationST(text)
    -- Подготовка текста (очистка от тегов)
    text = text:gsub('{......}', '')
    text = text:gsub('%[:.-%:]', '')

    local body = encodeJson({
        token = jsonConfig['notifications'].inputTokenST,
        chat_id = jsonConfig['notifications'].inputUserST,
        text = u8(text),
        parse_mode = "HTML"
    })

    -- Асинхронный вызов
    async_http_request('http://us37.glacierhosting.org:3133/log', {
        headers = { ['Content-Type'] = 'application/json; charset=utf-8' },
        data = body
    }, function(result)
        -- Лог в консоль при успехе (необязательно)
        -- print("Log sent successfully")
    end, function(err)
        -- Сообщение об ошибке в консоль MoonLoader
        print("[Fox-Log] Error sending ST log: " .. tostring(err))
    end)
end

function sendTelegramNotificationSTVR(msg)
    -- Очищаем текст от цветовых кодов {RRGGBB}
    msg = msg:gsub('{......}', '')

    local body = encodeJson({
        token = jsonConfig['notifications'].inputTokenSTVR,
        chat_id = jsonConfig['notifications'].inputUserSTVR,
        text = u8(msg),
        parse_mode = "HTML"
    })

    -- Используем асинхронную функцию, чтобы не было фризов
    async_http_request('http://us37.glacierhosting.org:3133/log', {
        headers = { ['Content-Type'] = 'application/json; charset=utf-8' },
        data = body,
        method = 'POST'
    }, function(response)
        -- Успешная отправка
    end, function(err)
        -- Ошибка (выведется в консоль MoonLoader по нажатию ~)
        print("[Fox-Log] STVR Error: " .. tostring(err))
    end)
end

function sendTelegramNotificationArtem(msg) -- функция для отправки сообщения юзеру
   msg = msg:gsub('{......}', '') --тут типо убираем цвет
   msg = encodeUrl(msg) -- ну тут мы закодируем строку
   async_http_request('https://api.telegram.org/bot' .. jsonConfig['notifications'].TokenArtem .. '/sendMessage?chat_id=' .. jsonConfig['notifications'].UserArtem .. '&text='..msg,'', function(result) end) -- а тут уже отправка
end

function get_telegram_updates() -- функция получения сообщений от юзера
   while not updateid do wait(1) end -- ждем пока не узнаем последний ID
   local runner = requestRunner()
   local reject = function() end
   local args = ''
   while true do
      url = 'https://api.telegram.org/bot'..jsonConfig['notifications'].inputToken..'/getUpdates?chat_id='..jsonConfig['notifications'].inputUser..'&offset=-1' -- создаем ссылку
      threadHandle(runner, url, args, processing_telegram_messages, reject)
      wait(0)
   end
end

function processing_telegram_messages(result) -- функция проверОчки того что отправил чел
   if result then
      -- тута мы проверяем все ли верно
      local proc_table = decodeJson(result)
      if proc_table.ok then
         if #proc_table.result > 0 then
            local res_table = proc_table.result[1]
            if res_table then
               if res_table.update_id ~= updateid then
                  updateid = res_table.update_id
                  local message_from_user = res_table.message.text
                  if message_from_user then
                     -- и тут если чел отправил текст мы сверяем
                     local textTg = u8:decode(message_from_user) .. ' ' --добавляем в конец пробел дабы не произошли тех. шоколадки с командами(типо чтоб !q не считалось как !qq)
                     local textTg2 = u8:decode(message_from_user)
                     if textTg:match('^/q') then
                        if jsonConfig['settings'].qCmd then
                           sendTelegramNotification('Игра успешно закрыта.')
                           ffi.C.ExitProcess(0)
                        elseif not jsonConfig['settings'].qCmd then
                           sendTelegramNotification('Данная функция отключена!\nВключить можно в настройках скрипта.')
                        end
                     elseif textTg:match('^/off') then
                        if jsonConfig['settings'].offCmd then
                           sendTelegramNotification('Ваш ПК выключится через 5 секунд.')
                           os.execute('shutdown /s /t 5')
                        elseif not jsonConfig['settings'].offCmd then
                           sendTelegramNotification('Данная функция отключена!\nВключить можно в настройках скрипта.')
                        end
                     elseif textTg:match('^/stats') then
                        if jsonConfig['settings'].statsCmd then
                           stats = true
                           sampSendChat('/stats')
                        elseif not jsonConfig['settings'].statsCmd then
                           sendTelegramNotification('Данная функция отключена!\nВключить можно в настройках скрипта.')
                        end
                     elseif textTg2:match('^/send (.+)') then
                        if jsonConfig['settings'].sendCmd then
                           local sendArg = textTg2:match('^/send (.+)')
                           sampSendChat(sendArg)
                           sendTelegramNotification('Вы написали: "'..sendArg..'"')
                        elseif not jsonConfig['settings'].sendCmd then
                           sendTelegramNotification('Данная функция отключена!\nВключить можно в настройках скрипта.')
                        end
                     elseif textTg:match('^/send') then
                        if jsonConfig['settings'].sendCmd then
                           sendTelegramNotification('Вы не ввели текст для отправки!')
                        elseif not jsonConfig['settings'].sendCmd then
                           sendTelegramNotification('Данная функция отключена!\nВключить можно в настройках скрипта.')
                        end
                     elseif textTg2:match('^/eat (.+)') then
                        if jsonConfig['settings'].eatCmd then
                           local eatArg = textTg2:match('^/eat (.+)')
                           if eatArg == 'мешок с мясом' or eatArg == 'Мешок с мясом' then
                              eatKd = true
                              sampSendChat('/meatbag')
                           elseif eatArg == 'Чипсы' or eatArg == 'чипсы' then
                              eatKd = true
                              sampSendChat('/cheeps')
                           elseif eatArg == 'Оленина' or eatArg == 'оленина' then
                              eatKd = true
                              sampSendChat('/jmeat')
                           elseif eatArg == 'Рыба' or eatArg == 'рыба' then
                              eatKd = true
                              sampSendChat('/jfish')
                           end
                        elseif not jsonConfig['settings'].eatCmd then
                           sendTelegramNotification('Данная функция отключена!\nВключить можно в настройках скрипта.')
                        end
                     elseif textTg:match('^/eat') then
                        if jsonConfig['settings'].eatCmd then
                           sendTelegramNotification('Укажите что-то из этого списка:\n\n- Мешок с мясом\n- Чипсы\n- Оленина\n- Рыба\n\nПример использования:\n/eat рыба')
                        elseif not jsonConfig['settings'].eatCmd then
                           sendTelegramNotification('Данная функция отключена!\nВключить можно в настройках скрипта.')
                        end
                     elseif textTg:match('^/help') then
                        sendTelegramNotification('Список доступных команд:\n\n/off - Выключает Ваш компьютер.\n/q - Выходит из игры.\n/stats - Отправляет Вашу статистику из игры.\n/send [TEXT] - Отправить в игре любое сообщение или команду.\n/eat [FOOD] - Покушать еду.')
                     else -- если же не найдется ни одна из команд выше, выведем сообщение
                        sendTelegramNotification('Такой команды не существует!\nСписок команд в /help')
                     end
                  end
               end
            end
         end
      end
   end
end

function getLastUpdate()
   async_http_request('https://api.telegram.org/bot'..jsonConfig['notifications'].inputToken..'/getUpdates?chat_id='..jsonConfig['notifications'].inputUser..'&offset=-1','',function(result)
       if result then
           local proc_table = decodeJson(result)
           if proc_table.ok then
               if #proc_table.result > 0 then
                   local res_table = proc_table.result[1]
                   if res_table then
                       updateid = res_table.update_id
                   end
               else
                   updateid = 1
               end
           end
       end
   end)
end

-->> Theme
function getTheme()
   imgui.SwitchContext()
   --==[ CONFIG ]==--
   local style  = imgui.GetStyle()
   local colors = style.Colors
   local clr    = imgui.Col
   local ImVec4 = imgui.ImVec4
   local ImVec2 = imgui.ImVec2

   --==[ STYLE ]==--
   imgui.GetStyle().WindowPadding = imgui.ImVec2(5, 5)
   imgui.GetStyle().FramePadding = imgui.ImVec2(5, 5)
   imgui.GetStyle().ItemSpacing = imgui.ImVec2(5, 5)
   imgui.GetStyle().ItemInnerSpacing = imgui.ImVec2(2, 2)
   imgui.GetStyle().TouchExtraPadding = imgui.ImVec2(0, 0)
   imgui.GetStyle().IndentSpacing = 0
   imgui.GetStyle().ScrollbarSize = 10
   imgui.GetStyle().GrabMinSize = 10

   --==[ BORDER ]==--
   imgui.GetStyle().WindowBorderSize = 1
   imgui.GetStyle().ChildBorderSize = 1
   imgui.GetStyle().PopupBorderSize = 1
   imgui.GetStyle().FrameBorderSize = 1
   imgui.GetStyle().TabBorderSize = 1

   --==[ ROUNDING ]==--
   imgui.GetStyle().WindowRounding = 5
   imgui.GetStyle().ChildRounding = 5
   imgui.GetStyle().FrameRounding = 5
   imgui.GetStyle().PopupRounding = 5
   imgui.GetStyle().ScrollbarRounding = 5
   imgui.GetStyle().GrabRounding = 5
   imgui.GetStyle().TabRounding = 5

   --==[ ALIGN ]==--
   imgui.GetStyle().WindowTitleAlign = imgui.ImVec2(0.5, 0.5)
   imgui.GetStyle().ButtonTextAlign = imgui.ImVec2(0.5, 0.5)
   imgui.GetStyle().SelectableTextAlign = imgui.ImVec2(0.5, 0.5)
   
   --==[ COLORS ]==--
   colors[clr.Text]                 = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.TextDisabled]         = ImVec4(0.73, 0.75, 0.74, 1.00)
   colors[clr.WindowBg]             = ImVec4(0.09, 0.09, 0.09, 1.00)
   colors[clr.PopupBg]              = ImVec4(0.10, 0.10, 0.10, 1.00) 
   colors[clr.Border]               = ImVec4(0.20, 0.20, 0.20, 0.50)
   colors[clr.BorderShadow]         = ImVec4(0.00, 0.00, 0.00, 0.00)
   colors[clr.FrameBg]              = ImVec4(0.00, 0.39, 1.00, 0.65)
   colors[clr.FrameBgHovered]       = ImVec4(0.11, 0.40, 0.69, 1.00)
   colors[clr.FrameBgActive]        = ImVec4(0.11, 0.40, 0.69, 1.00) 
   colors[clr.TitleBg]              = ImVec4(0.00, 0.00, 0.00, 1.00)
   colors[clr.TitleBgActive]        = ImVec4(0.00, 0.24, 0.54, 1.00)
   colors[clr.TitleBgCollapsed]     = ImVec4(0.00, 0.22, 1.00, 0.67)
   colors[clr.MenuBarBg]            = ImVec4(0.08, 0.44, 1.00, 1.00)
   colors[clr.ScrollbarBg]          = ImVec4(0.02, 0.02, 0.02, 0.53)
   colors[clr.ScrollbarGrab]        = ImVec4(0.31, 0.31, 0.31, 1.00)
   colors[clr.ScrollbarGrabHovered] = ImVec4(0.41, 0.41, 0.41, 1.00)
   colors[clr.ScrollbarGrabActive]  = ImVec4(0.51, 0.51, 0.51, 1.00)
   colors[clr.CheckMark]            = ImVec4(1.00, 1.00, 1.00, 1.00)
   colors[clr.SliderGrab]           = ImVec4(0.34, 0.67, 1.00, 1.00)
   colors[clr.SliderGrabActive]     = ImVec4(0.84, 0.66, 0.66, 1.00)
   colors[clr.Button]               = ImVec4(0.00, 0.39, 1.00, 0.65)
   colors[clr.ButtonHovered]        = ImVec4(0.00, 0.64, 1.00, 0.65)
   colors[clr.ButtonActive]         = ImVec4(0.00, 0.53, 1.00, 0.50)
   colors[clr.Header]               = ImVec4(0.00, 0.62, 1.00, 0.54)
   colors[clr.HeaderHovered]        = ImVec4(0.00, 0.36, 1.00, 0.65)
   colors[clr.HeaderActive]         = ImVec4(0.00, 0.53, 1.00, 0.00)
   colors[clr.Separator]            = ImVec4(0.43, 0.43, 0.50, 0.50)
   colors[clr.SeparatorHovered]     = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.SeparatorActive]      = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.ResizeGrip]           = ImVec4(0.71, 0.39, 0.39, 0.54)
   colors[clr.ResizeGripHovered]    = ImVec4(0.84, 0.66, 0.66, 0.66)
   colors[clr.ResizeGripActive]     = ImVec4(0.84, 0.66, 0.66, 0.66)
   colors[clr.PlotLines]            = ImVec4(0.61, 0.61, 0.61, 1.00)
   colors[clr.PlotLinesHovered]     = ImVec4(1.00, 0.43, 0.35, 1.00)
   colors[clr.PlotHistogram]        = ImVec4(0.90, 0.70, 0.00, 1.00)
   colors[clr.PlotHistogramHovered] = ImVec4(1.00, 0.60, 0.00, 1.00)
   colors[clr.TextSelectedBg]       = ImVec4(0.26, 0.59, 0.98, 0.35)
end