from MyFun import *

Result = 100  # Для синтаксиса
print("Режим работы: 1.Автомат; 2.Ручной;")
rezhim = input()


if rezhim == "1":
    try:
        log("Выбран автоматический режим мониторинга и перезапуска сервисов." +
        "\n Параметры работы:" +
        "\n  - Интервал мониторинга загрузки ЦП (сек): " + str(CPU_CheckEverySecond) +
        "\n  - Рестарт сервисов если загрузка на ЦП превышает %: " + str(limitzagruzky))

        fun_monitoringCPU()  # Вызов функции мониторинга
    except Exception as err:
        log(err)
        input()
elif rezhim == "2":
    Result = query()
    while Result != 0:
        try:
            wstr = runcmdcommand(Result)
            print(wstr)
            wtofile(" Выполнен РУЧНОЙ РЕЖИМ \n" + wstr)
            print("--Готово-------------------------------------------------------")
            print("")
            Result = query()

        except Exception as err:
            Result = query()
            print(err)
            if 'status 1056' in str(err):
                print("Служба уже работает")
            elif 'status 1062' in str(err):
                print("Служба остановлена, или не может принимать команды")
            elif "status 5" in str(err):
                print("Отказано в доступе")
            else:
                print("else")
            print("--Завершено с ошибкой--------------------------------------------------------")
            print("")


print("Для завершения нажмите ENTER")
input()
exit()
