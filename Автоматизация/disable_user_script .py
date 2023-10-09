from ldap3 import Server, Connection
import pyodbc
import logging
from selenium import webdriver
#from selenium.webdriver.common.keys import Keys
from selenium.webdriver.common.by import By
from selenium.webdriver.common.alert import Alert
import time
import re
import winreg
import sys


"""####### ВРЕМЕННО ТЕСТ #############################################
EMPLOYEE = 'Чивкунова Анна Викторовна'
LOGIN = 'chivkunova'
USER_CRM = 'CHIVKUNOVAAV'
###################################################################"""


#Логин Пароль
regpath = "Environment"  # Читаем из реестра параметры
try:
    root = winreg.OpenKey(winreg.HKEY_CURRENT_USER, regpath)

    # читаем значение параметра
    winreg_username = winreg.QueryValueEx(root, "username")[0]
    winreg_CRM_user = winreg.QueryValueEx(root, "CRM_user")[0]
except EnvironmentError:
    print(u"ОШИБКА. Проверьте наличие (username, CRM_user) в реесте windows (HKEY_CURRENT_USER\Environment)")
    sys.exit(1)
#  Запрашиваем параметры у пользователя
input_passwd = input("Доменный пароль: ")
input_CRM_passwd = input("Пароль CRM: ")
param = {'user': winreg_username,  # Из реестра
         'passwd': input_passwd,
         'CRM_user': winreg_CRM_user,  # Из реестра
         'CRM_passwd': input_CRM_passwd}
# print(param['user'])
"""parser = argparse.ArgumentParser(prog='user_off_v1', description='Блокировка пользователей')
parser.add_argument('user', type=str, help='username')
parser.add_argument('passwd', type=str, help='password')
parser.add_argument('CRM_user', type=str, help='CRM_user')
parser.add_argument('CRM_passwd', type=str, help='CRM_passwd')
args = parser.parse_args()"""


#Подключение логгирования
logger = logging.getLogger(__name__)
logging.root.setLevel(logging.NOTSET)
console = logging.StreamHandler()
file = logging.FileHandler('user_off.log')
file.setFormatter(logging.Formatter('%(asctime)s    %(levelname)s   %(message)s', '%d.%m.%Y %H:%M:%S'))
console.setFormatter(logging.Formatter('%(levelname)s   %(message)s'))
logger.addHandler(console)
logger.addHandler(file)

# Поиск юзера в AD
EMPLOYEE = input('Укажите ФИО: ')
user = param['user']
conn = Connection('OPEN.RU', user=f'open.ru\\{user}', password=param['passwd'])
conn.bind()

conn.search('dc=open,dc=ru', f'(&(objectclass=user)(Name={EMPLOYEE}))', attributes=['sAMAccountName', 'department', 'title'])

try:
    if len(conn.entries) > 1:
        i = 0
        for entry in conn.entries:
            i=i+1
            print(i, ') Логин сотрудника: ', entry.sAMAccountName, entry.department, entry.title)
        LOGIN = conn.entries[int(input('Выберите запись по порядковому номеру: '))-1].sAMAccountName
        print('Выбран логин: ', LOGIN)
    else:
        print("1", ') Логин сотрудника: ', conn.entries[0].sAMAccountName, conn.entries[0].department, conn.entries[0].title)
        LOGIN = conn.entries[int(input('Выберите запись по порядковому номеру: '))-1].sAMAccountName
        print('Выбран логин: ', LOGIN)

       # LOGIN = conn.entries[0].sAMAccountName
        print('Логин:     ', conn.entries[0].sAMAccountName,
              '\nОтдел:     ', conn.entries[0].department,
              '\nДолжность: ', conn.entries[0].title, '\n')
except:
    print('Учётная запись не найдена. Попробуйте поискать вручную.')
    input()
    exit()


# Отключение УЗ на серверах и проставление признака * для сейлза, заполнение списка пользователей CRM
sql_off_user = f"IF EXISTS (SELECT name FROM master.sys.server_principals WHERE name = 'OPEN.RU\{LOGIN}') alter login [OPEN.RU\{LOGIN}] disable"
sql_off_user_2 = f"IF EXISTS (SELECT name FROM master.sys.server_principals WHERE name = '{LOGIN}') alter login [{LOGIN}] disable"
sql_delete_salesrights = f"DELETE salesrights WHERE sales ='OPEN.RU\{LOGIN}'"
sql_delete_salesaddrights = f"DELETE sales_add_rights where  sales ='OPEN.RU\{LOGIN}'"
sql_off_sales = f"UPDATE sales SET sales_name = '*{EMPLOYEE}' WHERE domain_name like 'OPEN.RU\{LOGIN}'"


# БЫЛО: sql_off_crm = f"SELECT ROW_NUMBER() OVER(ORDER BY username DESC) AS Row, surname, name, username, city from crm_users where surname like '{EMPLOYEE.split()[0]}' and name like '{EMPLOYEE.split()[1]}' and Patronymic like '{EMPLOYEE.split()[2]}'"
EMPLOYEE_UPPER = str.upper(EMPLOYEE)
sql_off_crm = f"""select ROW_NUMBER() OVER(ORDER BY U.LOGIN DESC) AS Row
                        ,LAST_NAME as surname
                        ,FST_NAME  as name
                        ,MID_NAME  as MID_NAME
                        ,U.LOGIN   as username
                        ,'нет данных об адресе, Email: ' + Con.EMAIL_ADDR + ' Доменный логин: ' + X_LOGIN_DOMAIN  as city
                      --,Pos.NAME
                      --, *
                  from S_USER U left join S_CONTACT Con on U.ROW_ID = Con.ROW_ID
                                left join S_POSTN Pos on Con.PR_POSTN_ID = Pos.ROW_ID
                  WHERE LAST_NAME like '{EMPLOYEE_UPPER.split()[0]}' 
                    And FST_NAME  like '{EMPLOYEE_UPPER.split()[1]}' 
                    And MID_NAME  like '{EMPLOYEE_UPPER.split()[2]}' 
                  GROUP BY U.LOGIN, LAST_NAME, FST_NAME, MID_NAME, 'нет данных об адресе, Email: ' + Con.EMAIL_ADDR + ' Доменный логин: ' + X_LOGIN_DOMAIN
                """
# sql_off_crm = f"select 'Аветисян', 'Виктория', 'Константиновна', 'AVETISYANVK'"


spisok = ['TITAN',
          'SATURN',
          'BD-SRV-DWH',
          'bd-vm-tt-titan',
          'bd-vm-dv-titan',
          'bd-vm-pp-titan',
          'bd-vm-ut-titan',
          'bd-vm-tt-saturn',
          'bd-vm-dv-saturn',
          'bd-vm-pp-saturn',
          'bd-vm-ut-saturn',
          'bd-vm-gate-rts'
          ]

for element in spisok:
    try:
        if element == 'TITAN':
            conn = pyodbc.connect('Trusted Connection=yes; Server='+element+'; Driver={SQL Server}; Database=opendb')
            conn.autocommit = True
        else:
            conn = pyodbc.connect('Trusted Connection=yes; Server='+element+'; Driver={SQL Server}; Database=master')
            conn.autocommit = True
    except pyodbc.Error as err:
        logger.error('Не удалось подключиться к базе. Текст ошибки: {}'.format(err))
    
    try:
        cursor = conn.cursor()
        if element == 'TITAN':
            cursor.execute(sql_off_sales)
            cursor.execute(sql_off_user)
            cursor.execute(sql_off_user_2)
            cursor.execute(sql_delete_salesrights)
            cursor.execute(sql_delete_salesaddrights)
            logger.info('{} - Если был Sales - признак * проставлен'.format(element))
            print()
            logger.info('{} - ОК'.format(element))
        else:
            cursor.execute(sql_off_user)
            logger.info('{} - ОК'.format(element))
    except pyodbc.Error as err:
        logger.error('Ошибка выполнения SQL запроса. Текст ошибки: {}'.format(err))
conn.close()

print()
logger.info(f'Учётная запись OPEN.RU\{LOGIN} в базах отключена')
print()


# Отключение УЗ в Confluence
driver = webdriver.Chrome(executable_path='chromedriver.exe')
driver.get("https://conf.open-broker.ru/admin/users/browseusers.action")
login_user = driver.find_element(By.ID, "os_username")
login_user.send_keys(param['user'])
password = driver.find_element(By.ID, "os_password")
password.send_keys(param['passwd'])
logON = driver.find_element(By.NAME, "login")
logON.click()
password = driver.find_element(By.ID, "password")
password.send_keys(param['passwd'])
logON = driver.find_element(By.NAME, "authenticate")
logON.click()
search = driver.find_element(By.ID, "searchTerm")
search.send_keys(LOGIN)
search_button = driver.find_element(By.XPATH, "//input[@type='submit'][@value='Поиск']")
search_button.click()

try:
    user_link = driver.find_element(By.LINK_TEXT, EMPLOYEE)
    user_link.click()
    groups = driver.find_element(By.LINK_TEXT, 'Редактировать группы')
    groups.click()
    delete_groups = driver.find_element(By.LINK_TEXT, 'Убрать из всех групп')
    delete_groups.click()
    save = driver.find_element(By.ID, "save-btn1")
    save.click()
    print()
    logger.info(f'Учётная запись {LOGIN} в Confluence отключена')
    print()
except:
    print()
    logger.error(f'Учётная запись {LOGIN} в Confluence не найдена')
    print()

driver.close()
driver.quit()


# Отключение УЗ в CRM
#conn = pyodbc.connect('Trusted Connection=yes; Server=TITAN; Driver={SQL Server}; Database=supdb')
conn = pyodbc.connect('Trusted Connection=yes; Server=bd-srv-sbldb; Driver={SQL Server}; Database=siebeldb') # Перевод на проверку существования юзера в CRM - в таблице БД CRM SMU_2023_05_08
"""users = ''
cursor = conn.cursor()
print(sql_off_crm)
cursor.execute(sql_off_crm)
users = cursor.fetchall()"""

try:
        cursor = conn.cursor()
        cursor.execute(sql_off_crm)
        users = cursor.fetchall()
        print(users)
        print(len(users))
        print("___")
except pyodbc.Error as err:
        print('Ошибка получения данных из БД. Не найдена учётная запись в CRM (ПРОВЕРЬТЕ ЭТО В CRM)')
        print("Программа выполнена.")
        input()
        sys.exit()
conn.close()

if len(users) > 1:
    print('\n'.join(map(str, users)))
    print()
    print('Найдено несколько пользователей')
    row_number = input('Укажите пользователя по номеру строки: ')
    print()
    print('Будет заблокирован логин: ', users[int(row_number)-1][4])
    USER_CRM = users[int(row_number)-1][4]
    print()
else:
    if len(users) == 1:
            print('Будет заблокирован логин: ', users[0][4])
            USER_CRM = users[0][4]
            print()
    else:
            print()
            logger.error(f'Учётная запись {LOGIN} с полномочиями  в CRM не найдена (ПРОВЕРЬТЕ ЭТО В CRM)')
            print("Программа выполнена.")
            input()
            sys.exit()


driver = webdriver.Chrome(executable_path='chromedriver.exe')
driver.get("https://crm.open-broker.ru/fins_rus/start.swe?SWEBHWND=&SWECmd=Login&SWEFullRefresh=1&TglPrtclRfrsh=1")
driver.set_window_size(1920,1080)
login = driver.find_element(By.ID, "s_swepi_1")
login.send_keys(param['CRM_user'])
password = driver.find_element(By.ID, "s_swepi_2")
password.send_keys(param['CRM_passwd'])
logON = driver.find_element(By.ID, "s_swepi_22")
logON.click()
time.sleep(2)
driver.get("https://crm.open-broker.ru/fins_rus/start.swe?SWECmd=GotoView&SWEView=Employee+List+View&SWERF=1&SWEHo=crm.open-broker.ru&SWEBU=1")
time.sleep(25)
filtr = driver.find_element(By.NAME, "s_1_1_20_0")
filtr.send_keys("Идентификатор пользователя")
fio = driver.find_element(By.NAME, "s_1_1_21_0")
fio.send_keys(USER_CRM)
poisk = driver.find_element(By.NAME, "s_1_1_19_0")
poisk.click()
time.sleep(1)
status = driver.find_element(By.ID, "1_s_1_l_Employment_Status")
status.click()
apply = driver.find_element(By.ID, "1_Employment_Status")
apply.click()
apply.clear()
apply.send_keys('Terminated')
time.sleep(1)

open_setting = driver.find_element(By.ID, "s_at_m_1")  # Открываем список настроек
open_setting.click()
time.sleep(1)
save_button = driver.find_element(By.PARTIAL_LINK_TEXT, 'Сохранить запись')
save_button.click()
time.sleep(1)

print("Поиск и удаление ролей ### START ")
# Поиск и удаление ролей ### START #################################################################
save_button = driver.find_element(By.CSS_SELECTOR, "[title^='Роли Меню']")
save_button.click()
time.sleep(1)
count_zapis = driver.find_element(By.PARTIAL_LINK_TEXT, 'Число записей')
count_zapis.click()
time.sleep(1)



try:
    element_count_record = driver.find_element(By.NAME, "popup")
    time.sleep(2)
    # В html коде элемента находим количество ролей по тексту:
    element_count_record_code = element_count_record.get_attribute("innerHTML")
    index_element_count_record_code = element_count_record_code.find("<div role=\"document\" tabindex=\"0\" title=\"")
    index_count_record = re.findall(r'\d', element_count_record_code[
                                           index_element_count_record_code + 40:index_element_count_record_code + 43])
    time.sleep(1)
except Exception as err:
    print("Количество ролей не определено")




print("______________________________________")
#print(element_count_record.get_attribute("innerHTML"))
print("______________________________________")


try:
    save_button = driver.find_element(By.CSS_SELECTOR, "[title^='Число записей:ОК']")
    save_button.click()
    time.sleep(1)
    for i in range(int(index_count_record[0])):
        print(int(index_count_record[0]))
        if int(index_count_record[0]) == 0:
            print("Роли для " + USER_CRM + " в CRM не найдены.")
            break
        else:
            print("Найдена роль")
            del_click = driver.find_element(By.CSS_SELECTOR, "[title^='Роли:Удалить']")
            del_click.click()
            time.sleep(1)
except Exception as err:
    if str(err).find("no such element: Unable to locate element:") != -1:
        print("Ролей у " + USER_CRM + " не было.")
    else:
        print(err)
        input()
        sys.exit()
# Поиск и удаление ролей #### END ################################################################
print("Поиск и удаление ролей #### END ################################################################")

credentials = driver.find_element(By.ID, "1_s_1_l_Responsibility")
credentials.click()
time.sleep(1)
print("1_s_1_l_Responsibility - ОК")

responsibility = driver.find_element(By.ID, "s_1_2_48_0_icon")
responsibility.click()
time.sleep(1)
print("s_1_2_48_0_icon - ОК")


try: # Если появилось окно, кликаем ОК
    driver.switch_to.alert.accept()
    time.sleep(1)
    # Переходим опять в полномочия
    credentials = driver.find_element(By.ID, "1_s_1_l_Responsibility")
    credentials.click()
    time.sleep(1)
    print("1_Responsibility")
    responsibility = driver.find_element(By.ID, "s_1_2_48_0_icon")
    responsibility.click()
    time.sleep(1)
    print("s_1_2_48_0_icon - ОК")
except Exception as err:
    print("no such alert - ОК")

deleteALL_button = driver.find_element(By.CSS_SELECTOR, "[title^='Полномочия:<< Удалить все']")

if deleteALL_button.is_enabled():
    print("Кнопка <Полномочия удалить все> - АКТИВНА")
    deleteALL_button.click()
    time.sleep(2)
else:
    print("Кнопка <Полномочия удалить все> - не кликабельна. Полномочия отсутствуют.")
    time.sleep(1)
print("[title^='Полномочия:<< Удалить все']")


deleteexit_button = driver.find_element(By.CSS_SELECTOR, "[title^='Полномочия:ОК']")
deleteexit_button.click()
time.sleep(2)
print("[title^='Полномочия:ОК']")

#delete_button = driver.find_element(By.ID, "s_4_1_78_0_Ctrl")
#while delete_button.is_enabled():
#        try:
#                delete_button.click()
#        except:
#                continue



menu_file = driver.find_element(By.LINK_TEXT, 'Изменить')
menu_file.click()
time.sleep(1)
save_button = driver.find_element(By.PARTIAL_LINK_TEXT, 'Сохранить запись')
save_button.click()
time.sleep(2)
driver.close()
driver.quit()
print()
logger.info(f'Учётная запись {LOGIN} в CRM отключена')
print("Проверьте УЗ в CRM.")
print("Программа выполнена.")
input()
sys.exit()
