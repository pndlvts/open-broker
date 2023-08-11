from http.server import executable
from ldap3  import Server, Connection
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

#Логин
regpath = "Environment" #читаем из реестра параметры из реестра 
try:
    root = winreg.OpenKey(winreg.HKEY_CURRENT_USER, regpath)
    winreg_username = winreg.QueryValueEx(root, "username")[0]
    winreg_crm_username = winreg.QueryValueEx(root, "crm_user")[0]  #логин Siebel
except EnvironmentError:
    print(u"ОШИБКА. Проверьте наличие username и crm_user в реестре Windows (HKEY_CURRENT_USER\Environment)")
    sys.exit(1)

#Пароль
passwd = input("Доменный пароль")
crm_passwd = input("Пароль Siebel CRM")

param = {
    'user': winreg_username,
    'passwd': passwd,
    'crm_user': crm_passwd,
    'crm_passwd': winreg_crm_username
}

#Подключение логгирования
logger = logging.getLogger(__name__)
logging.root.setLevel(logging.NOTSET)
console = logging.StreamHandler()
file = logging.FileHandler('disable_user_script.log')
file.setFormatter(logging.Formatter('%(time.asctime)s %(levelname)s %(message)s', '%d.%m.%Y %H:%M:%S'))
console.setFormatter(logging.Formatter('%(levelname)s %(message)s'))
logger.addHandler(console)
logger.addHandler(file)

#ищем юзера в Ad
EMPLOYEE = input('Укажите ФИО: ')
user = param['user']
conn = Connection('OPEN.RU', user=f'open.ru\\{user}', password = param['passwd'])
conn.bind()

conn.search('dc=open,dc=ru', f'(&(objectclass=user)(Name={EMPLOYEE}))', attributes=['sAMAccountName', 'department', 'title'])
try:
    if len(conn.entries) > 1:
        i = 0
        for entery in conn.entries:
            i = i + 1
            print(i, ') Логин сотрудника: ', entery.sAMAccountName, entery.department, entery.title)
        LOGIN = conn.entries[int(input('Выберите запись по порядковому номеру: '))-1].sAMAccountName
    else:
        print('1) Логин сотрудника: ', conn.entries[0].sAMAccountName, conn.entries[0].department, conn.entries[0].title)
        LOGIN = conn.entries[int(input('Выберите запись по порядковому номеру: '))-1].sAMAccountName
except:
    print('УЗ не найдена. Отключай вручную:(')
    input()
    exit()

#Отключаем на серваках БД в нашей зоне ответственности и проставляем *, если в Clients был сейлз, заполнение списка пользователей CRM
sql_off_domain_user = f"IF EXISTS (SELECT name FROM master.sys.server_principals WHERE name = 'OPEN.RU\{LOGIN}') ALTER LOGIN [OPEN.RU\{LOGIN}] DISABLE"
sql_off_server_user = f"IF EXISTS (SELECT name FROM master.sys.server_principals WHERE name = '{LOGIN}') ALTER LOGIN [{LOGIN}] DISABLE"
sql_del_salesrights = f"DELETE salesrights WHERE sales = 'OPEN.RU\{LOGIN}'"
sql_del_salesaddrights = f"DELETE sales_add_rights WHERE sales = 'OPEN.RU\{LOGIN}'"
sql_off_sales = f"UPDATE sales SET sales_name = '*{EMPLOYEE}' WHERE domain_name LIKE 'OPEN.RU\{LOGIN}'"
EMPLOYEE_UPPER = str.upper(EMPLOYEE)
sql_off_crm = f"""
    SELECT ROW_NUMBER() OVER(ORDER BY U.LOGIN DESC) AS Row,
    LAST_NAME AS surname,
    FST_NAME AS name,
    MID_NAME AS MID_NAME,
    U.LOGIN AS USERNAME,
    'нет данных об адресате Email: ' + Con.EMAIL_ADDR + ' Доменный логин: ' + X_LOGIN_DOMAIN AS city,
    --Pos.NAME,
    -- * FROM S_USER U LEFT JOIN S_CONTACT Con on U.ROW_ID = Con.ROW_ID
                       LEFT JOIN S_POSTN Pos ON Con.PR_POSTN_ID = POS.ROW_ID
         WHERE LAST_NAME LIKE '{EMPLOYEE_UPPER.slit()[0]}'
         AND FST_NAME LIKE '{EMPLOYEE_UPPER.slit()[1]}'
         AND MID_NAME LIKE '{EMPLOYEE_UPPER.slit()[2]}'
         GROUP BY U.LOGIN, LAST_NAME, PST_NAME, MID_NAME, 'нет данных об адресате, Email: ' + Con.EMAIL_ADDR + ' Доменный логин: ' + X_LOGIN_DOMAIN
"""
server_list = [
    'TITAN',
    'SATURN',
    'BD-SRV-DWH',
    'bd-vm-tt-titan',
    'bd-vm-pp-titan',
    'bd-vm-dv-titan',
    'bd-vm-ut-titan',
    'bd-vm-tt-saturn',
    'bd-vm-pp-saturn',
    'bd-vm-dv-saturn',
    'bd-vm-ut-saturn',
    'bd-vm-gate-rts',
]
for server in server_list:
    try:
        if server == 'TITAN':
            conn = pyodbc.connect('Trusted Connection=yes; Server='+server+'; Driver{SQL Server}; Database=opendb')
            conn.autocommit = True
        else:
            conn = pyodbc.connect('Trusted Connection=yes; Server='+server+'; Driver{SQL Server}; Database=master')
            conn.autocommit = True
    except pyodbc.Error as err:
        logger.error('Не удалось подключиться к базе. Текст ошибки: {}'.format(err))
    try:
        cursor = conn.cursor()
        if server == 'TITAN':
            cursor = conn.cursor()
            cursor.execute(sql_off_sales)
            cursor.execute(sql_off_domain_user)
            cursor.execute(sql_off_server_user)
            cursor.execute(sql_del_salesrights)
            cursor.execute(sql_del_salesaddrights)
            logger.info('{} - Если был Sales - признак * проставлен'.format(server))
            logger.info('{} - ОК'.format(server))
        else:
            cursor.execute(sql_off_domain_user)
            logger.info('{} - ОК'.format(server))
    except pyodbc.Error as err:
        logger.error('Ошибка выполнения SQL-запроса. Текст ошибки: {}'.format(err))
conn.close()
print()
logger.info(f'УЗ OPEN.RU\{LOGIN} в базах отключена')
print()

#Отключение УЗ в Confluence
driver = webdriver.Chrome(executable_path='chromedriver.exe')
driver.get("https://conf.open-broker.ru/admin/users/browseusers.action")
loging_user = driver.find_element(By.ID, "os_username")
loging_user.send_keys(param['user'])
password = driver.find_element(By.ID, "os_password")
loging_user.send_keys(param['passwd'])
logON = driver.find_element(By.NAME, "authenticate")
logON.click()
search = logON = driver.find_element(By.ID, "searchTerm")
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
    save = driver.find_element(By.ID, 'save-btn1')
    delete_groups.click()
    print()
    logger.info(f'УЗ {LOGIN} в Conf отключена')
    print()
except:
    print()
    logger.info(f'УЗ {LOGIN} в Conf не найдена')
    print()
driver.close()
driver.quit()
#Отключение УЗ в CRM
conn = pyodbc.connect('Trusted Connection=yes; Server=bd-srv-sbldb; Driver={SQL Server}; Database=siebeldb')
try:
    cursor = conn.cursor()
    cursor.execute(sql_off_crm)
    users = cursor.fetchall()
    print(users)
    print(len(users))
    print('____')
except pyodbc.Error as err:
    print('Ошибка получения данных из БД. Не найдена УЗ в CRM')
    print('скрипт выполнен')
    input()
    sys.exit()
conn.close()
if len(users) > 1:
    print('\n'.join(map(str, users)))
    print()
    print('найдено несколько пользователей')
    row_number = input('Укажите пользователя по номеру строки: ')
    print()
    print('Логин будет заблокирован', users[int(row_number)-1][4])
    USER_CRM = users[int(row_number)-1][4]
    print()
else: 
    if len(users) == 1:
        print('Логин будет заблокирован', users[0][4])
        USER_CRM = users[0][4]
        print()
    else:
        print()
        logger.error(f'УЗ {LOGIN} с полномочиями не найдена в CRM')
        print('скрипт выполнен')
        input()
        sys.exit()
driver = webdriver.Chrome(executable_path='chromedriver.exe')
driver.get("https://crm.open-broker.ru/fins_rus/start.swe?SWEBHWD=&SWECmd=Login&SWEFullRefresh=1&TglPrtclRftsh=1")
driver.set_window_size(1920,1080)
login = driver.find_element(By.ID, 's_swepi_1')
login.send_keys(param['crm_user'])
password = driver.find_element(By.ID, 's_swepi_2')
password.send_keys(param['crm_passwd'])
logON = driver.find_element(By.ID, 's_swepi_22')
logON.click()
time.sleep(2)
driver.get("https://crm.open-broker.ru/fins_rus/start.swe?SWECmd=GotoView&SWEView=Employee+List+View&SHERF=1&SWEHo=crm.open-broker.ru&SWEBU=1")
time.sleep(25)
filtr = driver.find_element(By.NAME, 's_1_1_20_0')
filtr.send_keys("Идентификатор пользователя")
fio = driver.find_element(By.NAME, 's_1_1_21_0')
fio.send_keys(USER_CRM)
poisk = driver.find_element(By.NAME, 's_1_1_19_0')
poisk.click()
time.sleep(1)
status = driver.find_element(By.ID, '1_s_1_1_Employment_Status')
status.click()
apply =  driver.find_element(By.ID, '1_Employment_Status')
apply.click()
apply.clear()
apply.send_keys('Terminated')
time.sleep(1)