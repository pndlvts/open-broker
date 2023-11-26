from tkinter import *
from tkinter import ttk
import datetime
#Создаем окно
root = Tk() #Создаем окно
root.title("OPPS - MyHelper") #Заголовок
root.geometry("280x370") #Размеры
root.resizable(False, False) #Запрет изменения размера
icon = PhotoImage(file = "favicon.jpg") 
root.iconphoto(True, icon)
root.attributes("-alpha", 0.9)
#Элементы окна
weekday = int(datetime.datetime.today().weekday())
if weekday == 6:
    weekday = "17:00/23:00 - Реиндексация Jira"
    label_weekday = ttk.Label(text = weekday, font = "bold 10", foreground="red")
    label_weekday.pack()
else:
    weekday = "Не пятница"
btn_user_access = ttk.Button(text="Открыть vbs для выдачи доступов")
btn_user_access.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_user_off = ttk.Button(text="Отключить пользователя на серверах БД")
btn_user_off.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_sales_off = ttk.Button(text="Проставить * сейлзу")
btn_sales_off.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_edit_lastname = ttk.Button(text="SUP - Изменить фамилию сотрудника в БД")
btn_edit_lastname.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_edit_sum = ttk.Button(text="SUP - Изменить сумму П/П")
btn_edit_sum.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_vm_on = ttk.Button(text="Открыть vCenter (VM ON/OFF)")
btn_vm_on.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_pc_reboot = ttk.Button(text="Рестарт ПК по имени")
btn_pc_reboot.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_pc_ping = ttk.Button(text="Пингануть устройство")
btn_pc_ping.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_send_jira_message = ttk.Button(text="Создать письмо 'Технические работы: Jira'")
btn_send_jira_message.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
btn_mt5_errors = ttk.Button(text="Вывести ошибки МТ5")
btn_mt5_errors.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
create_ini = ttk.Button(text="Create .ini")
create_ini.pack(anchor="nw", padx=5, pady=[5, 0], fill=X)
label_developer = ttk.Label(text = "по ошибкам писать - pandelov_ts@open.ru", font = "normal 8")
label_developer.pack(side=BOTTOM)
root.mainloop()