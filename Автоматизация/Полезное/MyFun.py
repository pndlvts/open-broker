from sendemail import *
import time
import re


def log(textinfolog):
    textinfolog = tekdatetime() + " " + textinfolog
    print(textinfolog)
    wtofile(textinfolog)


try:
    FileJson = open('RESTART_MT5APISender_setting.json', 'r')
    JsonData = json.loads(FileJson.read())

    ServerName = JsonData['ServerName']  # Имя сервера
    ServiceName = JsonData['ServiceName']  # Имя сервиса
    CPU_CheckEverySecond = JsonData['CPU_CheckEverySecond']  # Интервал проверки
    limitzagruzky = JsonData['limitzagruzky']  # Лимит загрузки ЦП %
    waytothefile = JsonData['waytothefile']  # Путь к файлу лога
  #  alertemail = JsonData['alertemail']  # Адресаты алертов
except Exception as err:
    log(err)
    input()


def query():
    print("Выберите действие для службы " + ServiceName + "."
                                                          "\n1.Команда ipconfig (тест); "
                                                          "\n2.queryex Metatrader.ManagerApi.Service; "
                                                          "\n3.start Metatrader.ManagerApi.Service; "
                                                          "\n4.stop Metatrader.ManagerApi.Service; "
                                                          "\n22.queryex Metatrader.ManagerApi.UserAddCommand.Service; "
                                                          "\n33.start Metatrader.ManagerApi.UserAddCommand.Service; "
                                                          "\n44.stop Metatrader.ManagerApi.UserAddCommand.Service; "
                                                          "\n5.Список активных служб; "
                                                          "\n6.Kill задачи по ID; "
                                                          "\n7.Kill Metatrader.ManagerApi.Service; "
                                                          "\n8.Kill Metatrader.ManagerApi.UserAddCommand.Service; "
                                                          "\n9.Показать загрузку процессора в %; "
                                                          "\n0.Выход;")
    inputres = int(input())
    return inputres


def runcmdcommand(res):
    if res == 1:
        output = subprocess.check_output('ipconfig')
    elif res == 2:
        output = subprocess.check_output('sc "\\\\' + ServerName + '" queryex "Metatrader.ManagerApi.Service"')
    elif res == 22:
        output = subprocess.check_output('sc "\\\\' + ServerName + '" queryex "Metatrader.ManagerApi.UserAddCommand.Service"')
    elif res == 3:
        output = subprocess.check_output('sc "\\\\' + ServerName + '" start "Metatrader.ManagerApi.Service"')
    elif res == 33:
        output = subprocess.check_output('sc "\\\\' + ServerName + '" start "Metatrader.ManagerApi.UserAddCommand.Service"')
    elif res == 4:
        output = subprocess.check_output('sc "\\\\' + ServerName + '" stop "Metatrader.ManagerApi.Service"')
    elif res == 44:
        output = subprocess.check_output('sc "\\\\' + ServerName + '" stop "Metatrader.ManagerApi.UserAddCommand.Service"')
    elif res == 5:
        output = subprocess.check_output('tasklist /S "' + ServerName + '" /SVC /FI "ImageName eq Open.MT5APISender.exe"')
    elif res == 6:
        print("Принудительно завершить задачу (Kill) - укажите ID")
        killID = input()
        output = subprocess.check_output('taskkill /S "' + ServerName + '" /F /T /PID ' + str(killID))
    elif res == 7:
        output = subprocess.check_output('taskkill /S "' + ServerName + '" /F /T /fi "services eq Metatrader.ManagerApi.Service"')
    elif res == 8:
        output = subprocess.check_output('taskkill /S "' + ServerName + '" /F /T /fi "services eq Metatrader.ManagerApi.UserAddCommand.Service"')
    elif res == 9:
        output = cpu_info(ServerName)
    else:
        output = "Нет такой команды."

    if res == 9:
        output = output
    else:
        output = str(output, 'CP866')
    return output


def tekdatetime():
    return str(datetime.now().strftime("%Y.%m.%d %H:%M:%S"))


def fun_monitoringCPU():
    while 1 == 1:
        beg_cpu = runcmdcommand(9)  # Получили % загрузки ЦП на начале периодичности проверки
        #  log(" Мониторинг запущен с интервалом - " + str(CPU_CheckEverySecond) + " сек. Текущая загрузка ЦП - " + str(
        #      beg_cpu) + "%;")
        time.sleep(CPU_CheckEverySecond)  # Ждем период
        end_cpu = runcmdcommand(9)  # Получили % загрузки ЦП на конце периодичности проверки
        log(" Плановая проверка. Начальная загрузка ЦП - " + str(beg_cpu) + "%; конечная - " + str(end_cpu) + "%;")
        if beg_cpu is None or end_cpu is None:
            log(" Информация о загрузке ЦП не получена.")
            beg_cpu = 0
            end_cpu = 0
        if beg_cpu > limitzagruzky and end_cpu > limitzagruzky:
            log(" * * * * * * * ")
            log(" Перезапуск. Начальная загрузка ЦП - " + str(beg_cpu) + "%; конечная - " + str(end_cpu) + "%;")

            log(runcmdcommand(7))  # Остановка
            log(runcmdcommand(8))  # Остановка
            log("*** Выполнены команды остановки служб *** \n")
            log("Ждем 10 сек")
            time.sleep(10)

            log(runcmdcommand(3))  # Запуск
            log(runcmdcommand(33))  # Запуск
            log("*** Выполнены команды запуска служб *** \n")
            log("Ждем 10 сек")
            time.sleep(10)

            log(runcmdcommand(2))  # Запрос состояния
            rcheck(runcmdcommand(2))
            log(runcmdcommand(22))  # Запрос состояния
            rcheck(runcmdcommand(22))
            log(" * * * Выполнено Состояние служб * * * Рестарт завершен * * * \n")


def wtofile(text):
    try:
        #  waytothefile = 'H:/Support/_Scripts/sigoshin_my/PythonProject/log/log_restart_MT5/' #  'log/'
        with open(waytothefile + str(datetime.now().strftime("%Y.%m.%d")) + '_logfileRestartMT5.txt', 'a',
                  encoding='utf-8') as f:
            text = '\n'.join(filter(bool, re.split(r'[\r\n]+', text)))  # Убираем разделители строк - пустые строки
            f.write("\n" + text)
    except Exception as err:
        log(err)
        fun_monitoringCPU()  # Вызов функции мониторинга


# Функция проверки успешности запуска службы.
def rcheck(checkwhere=""):
    try:
        if "Состояние          : 4  RUNNING" in checkwhere:
            log("УСПЕХ " + checkwhere)
            # sendoutlookemail(checkwhere, 'RESTART_MT5APISender выполнен перезапуск - служба работает')
        else:
            log("ОШИБКА! " + checkwhere)
            # sendoutlookemail(checkwhere, 'RESTART_MT5APISender служба не запущена')
    except Exception as err:
        log(err)
        fun_monitoringCPU()  # Вызов функции мониторинга
