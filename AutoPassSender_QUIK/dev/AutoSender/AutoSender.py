import sys
import csv
import time
import json
import pyodbc
import locale
import datetime
import subprocess
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
from cryptography.fernet import Fernet


def month_num_to_txt(month_num):
    month_arr =['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь', 'Июль', 'Август', 'Сентябрь', 'Октябрь', 'Ноябрь', 'Декабрь']
    if month_num == 1: return month_arr[0]
    elif month_num == 2: return month_arr[1]
    elif month_num == 3: return month_arr[2]
    elif month_num == 4: return month_arr[3]
    elif month_num == 5: return month_arr[4]
    elif month_num == 6: return month_arr[5]
    elif month_num == 7: return month_arr[6]
    elif month_num == 8: return month_arr[7]
    elif month_num == 9: return month_arr[8]
    elif month_num == 10: return month_arr[9]
    elif month_num == 11: return month_arr[10]
    elif month_num == 12: return month_arr[11]
    else: 
        print('Передано некорректное число')
        sys.exit(1)
# setlocale плохо дружит с pyinstaller, выше функция для обхода
# locale.setlocale(locale.LC_TIME, 'ru') 
d = datetime.date.today() #сегодняшняя дата
today_month_ru = month_num_to_txt(d.month)
# today_month_ru = d.strftime('%B') #текущий месяц на русском
tommorow = d + datetime.timedelta(days = 1) #завтрашняя дата
# tommorow_month_ru = tommorow.strftime('%B') #месяц завтрашнего дня на русском
tommorow_month_ru = month_num_to_txt(tommorow.month)


#ИНФА ДЛЯ АВТОРИЗАЦИИ В Confluence:
with open('userdata.json', 'r') as json_file:
    userdata = json.load(json_file)
    key = ''
    with open('crypto.key', 'rb') as file:
        key = file.read()
    f = Fernet(key)

    userdata['password'] = bytes(userdata['password'], encoding='utf-8')
    userdata['password'] = str(f.decrypt(userdata['password']))[2:-1]
    USER = {
        'username': userdata['username'], #учетка без OPEN.RU\
        'password': userdata['password'] #пароль шифруется скриптом pswdgenerator
    } 


#Авторизация и переход на нужную страницу в Confluence
s = Service('chromedriver.exe') #путь до драйвера
driver = webdriver.Chrome(service=s) #открываем браузер 
driver.get('https://conf.open-broker.ru/login.action?logout=true') #переходим на страницу авторизации
login_input = driver.find_element(By.ID, 'os_username') #находим инпут для логина
login_input.send_keys(USER['username']) #вставляем логин, который до этого был считан из json
password_input = driver.find_element(By.ID, 'os_password') #находим инпут для пароля
password_input.send_keys(USER['password']) #вставляем предварительно расшифроанный пароль
logon_button = driver.find_element(By.ID, 'loginButton') #кнопка авторизации
logon_button.click() #клик по кнопке авторизации
driver.get('https://conf.open-broker.ru/display/PROC/QUIK+Resend') #переходим на страницу Quik Resend
time.sleep(5)
month_link_text = f'{d.month:02}_{today_month_ru} {d.year}' #определяем тайтл страницы (месяц, далее в нее будут вложены страницы с днями)
month_link = driver.find_element(By.LINK_TEXT, month_link_text) #находим страницу с нужным заголовком
month_link.click() #и переходим на нее
time.sleep(5)
day_link_text = f'{d.day:02}/{d.month:02}/' #определяем тайтл страницы (день)
day_link = driver.find_element(By.PARTIAL_LINK_TEXT, day_link_text) #находим нужную страницу
day_link.click() #и переходим на нее. На странице будет текст + таблица, в которую бизнес вносит bf-коды
time.sleep(5)


#ПОЛУЧАЕМ СПИСОК КОДОВ CODE-BF:
codes = [] #определяем список с кодами
rows = driver.find_elements(By.XPATH, '//*[@id="main-content"]/div[1]/table/tbody/tr') #находим строки таблицы
for row_num, row in enumerate(rows, start=1): #циклом проходимся по строкам таблицы
    try:
        txt = row.find_element(By.XPATH, 'td[1]') #находим ячейку с кодом (первый столбец)
        txt = txt.text #вытягиваем из нее значение
    except:
        print('Ячейки не найдены')
        sys.exit(1)
    if '-BF' in txt :
        codes.append(txt[:-3]) #добавляем коды из таблицы в массив без постфикса -BF
    else:
        last_row = row_num #строка не содержит bf-код. На всякий случай проходимся по строкам дальше


#Пишем, что реестр закрыт
driver.find_element(By.ID, 'editPageLink').click()#Кликаем по кнопке "редактировать"
time.sleep(2)
iframe = driver.find_element(By.ID, 'wysiwygTextarea_ifr')#основной контент страницы при ее создании и редактировании находтся во фрейме. определяем фрейм
driver.switch_to.frame(iframe) #переключаемся на фрейм
time.sleep(2)
last_row_for_edit = driver.find_element(By.XPATH, f'//*[@id="tinymce"]/table/tbody/tr[{last_row}]')
last_td = last_row_for_edit.find_element(By.XPATH, 'td[1]')
last_td.click()
last_td.send_keys('РЕЕСТР ЗАКРЫТ')
driver.switch_to.default_content()
driver.find_element(By.ID, 'rte-button-publish').click()
time.sleep(2)


#Cоздание новой страницы месяца и дня в Conf ДОПИСАТЬ ПРОВЕРКИ СУЩЕСТВОВАНИЯ СТРАНИЦ
if (d.month < tommorow.month and d.month != 12) or (d.month > tommorow.month and d.month == 12): #если последний день месяца, то создаем страничку для нового месяца и дальше создаем страничку дня
    driver.get('https://conf.open-broker.ru/display/PROC/QUIK+Resend') #переходим на страничку Quik Resend, она корневая для этого скрипта
    time.sleep(5)
    driver.find_element(By.ID, 'quick-create-page-button').click() #создаем вложенную в Quik Resend
    driver.find_element(By.ID, 'content-title').send_keys(f'{tommorow.month:02}_{tommorow_month_ru} {d.year}') #определяем название странички в формате по аналогии (например, 01_Январь 2023)
    driver.find_element(By.ID, 'rte-button-publish').click() #после публикации conf сразу кидает на опубликованную страницу
    time.sleep(5)
else: 
    driver.get('https://conf.open-broker.ru/display/PROC/QUIK+Resend') #переходим на страицу квик ресенд
    time.sleep(5)
    month_link_text = f'{d.month:02}_{today_month_ru} {d.year}' #нужный тайтл для страницы месяца
    month_link = driver.find_element(By.LINK_TEXT, month_link_text) #находим ссылку на нужную страницу
    month_link.click()
    time.sleep(5)
driver.find_element(By.ID, 'quick-create-page-button').click() #создаем вложенную страницу в страницу месяца
if d.weekday() != 4:
    driver.find_element(By.ID, 'content-title').send_keys(f'{tommorow.day:02}/{tommorow.month:02}/{str(tommorow.year)[2:]} Quik') #название страницы дня в формате dd/mm/yy
else:
    driver.find_element(By.ID, 'content-title').send_keys(f'{tommorow.day+3:02}/{tommorow.month:02}/{str(tommorow.year)[2:]} Quik') #название страницы дня в формате dd/mm/yy
driver.find_element(By.ID, 'rte-button-insert-table').click() #открываем выпадающее меню для вставки таблицы
driver.find_element(By.XPATH, '//*[@id="table-picker-container"]').click() #вставляем таблицу, по умолчанию вставляется 3х3
driver.switch_to.frame(driver.find_element(By.ID, 'wysiwygTextarea_ifr')) #переключаемся на фрейм
par = driver.find_element(By.TAG_NAME, 'p') #текст пишется прямо в тег <p>, инпутов и textarea нет.
par.click() #ставим курсор в тег p и вставляем текст ниже
par.send_keys('''

Сначала смотрим наиболее частые проблемы и пытаемся самостоятельно решить с клиентом
Все счета указываем строго  с BF 
Дополнительные таблицы не создаем. Дополняем строки в существующей. Изменения вносятся строго до 16:00.
''')
par.click()
driver.switch_to.default_content() #кнопки для вставки ссылок находятся не во фрейме, перекулючаемся на основную html-страничку
driver.find_element(By.ID, 'rte-button-link').click() #кликаем по кнопке добавления страницы
driver.find_element(By.ID, 'weblink-panel-id').click() #переходим в нужное меню и вставляем адрес страницы и текст ссылки
time.sleep(5)
driver.find_element(By.ID, 'weblink-destination').send_keys('https://conf.open-broker.ru/display/PROC/QUIK+Resend#QUIKResend-%D0%9D%D0%B0%D0%B8%D0%B1%D0%BE%D0%BB%D0%B5%D0%B5%D1%87%D0%B0%D1%81%D1%82%D1%8B%D0%B5%D0%BF%D1%80%D0%BE%D0%B1%D0%BB%D0%B5%D0%BC%D1%8B')
time.sleep(2)
driver.find_element(By.ID, 'alias').clear()
driver.find_element(By.ID, 'alias').send_keys('Список наиболее частых проблем')
driver.find_element(By.ID, 'link-browser-insert').click() #вставляем ссылку в
driver.switch_to.frame(driver.find_element(By.ID, 'wysiwygTextarea_ifr')) #далее редачим таблицу. Нам нужна 2х2 с текстом в заголовках 
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[1]').click() #курсор в ячейку 1 в заголовке
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[1]').send_keys('Номер брокерского счета клиента в партнере строго по маске XXXXXX-BF') #вставляем текст
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[2]').click()
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[2]').send_keys('Причина переотправки')
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[3]').click() #устанавливаем курсор в стлбец 3 
driver.switch_to.default_content()
driver.find_element(By.XPATH, '//*[@id="rte-toolbar-row-default"]/div[5]/button[3]').click() #удаляем столбец
driver.switch_to.frame(driver.find_element(By.ID, 'wysiwygTextarea_ifr'))
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[3]/td[1]').click()
driver.switch_to.default_content()
for i in range(20):
    driver.find_element(By.XPATH, '/html/body/div[2]/div/div[2]/div[3]/form/div[3]/div/div[5]/div[2]/button[2]').click()
time.sleep(2)    
driver.find_element(By.ID, 'rte-button-publish').click() 
time.sleep(3)
driver.close()


#Запрос к БД
if len(codes) == 1:
    codes = '(\'' + codes[0] + '\')'
elif len(codes) < 1:
    print('Коды в Confluence не найдены. Проверьте.')
    sys.exit()
else:    
    codes = tuple(codes)
sql_query = f'''
OPEN SYMMETRIC KEY SK_QORT_QUIK_NOTIFICATION
DECRYPTION BY PASSWORD = 'вписать ключ при создании exe и тестах!!!';
Select
a.person_guid as Guid,
a.client_code as CLIENT_CODE, 
a.firstname as FIRSTNAME, 
a.lastname as    LASTNAME, 
REPLACE(e.Email, ',',';') as MAIL,
REPLACE(e.Phones, '+','') as PHONE,
a.client_codespb as CLIENT_CODESPB,
a.client_codefrm as CLIENT_CODEFRM,
a.login as LOGIN,
CONVERT(varchar(max), DecryptByKey(a.password)) as PASSWORD
from [opendb].[dbo].[vwQuikUserNotification] a
join [QUORT].[QORT_DB].[dbo].[Subaccs] sub on sub.SubAccCode Collate Cyrillic_General_CS_AS = a.client_code 
join [QUORT].[QORT_DB].[dbo].[Firms] e on e.id = sub.OwnerFirm_ID
where a.client_code in
{codes}
'''
try:
    conn =  pyodbc.connect('Trusted Connection=yes; Server=TITAN; Driver={SQL Server}; Database=opendb')
    conn.autocommit = True
except pyodbc.Error as err:
    print('Не удалось подключиться к БД: ')
    print(err)
else:
    print('Соединение с БД установлено')
try:
    cursor = conn.cursor()
    cursor.execute(sql_query)
except pyodbc.Error as err:
    print('Запрос не выполнен')
    print(err)
else:
    arr = cursor.fetchall()
    arr_len = len(arr)
    if arr_len == 0:
        print('В БД нет записей')
        sys.exit()
    print(f'Запрос выполнился успешно. Найдено записей {arr_len}\nСтроки:')
    with open('In\\quik.csv', 'w', encoding='utf-8') as csv_file:
        csv_writer = csv.writer(csv_file, delimiter=';', lineterminator='\r')
        csv_writer.writerow(['Guid', 'CLIENT_CODE', 'FIRSTNAME', 'LASTNAME', 'MAIL', 'PHONE', 'CLIENT_CODESPB', 'CLIENT_CODEFRM', 'LOGIN', 'PASSWORD'])
        for row in arr:
            csv_writer.writerow([row[0], row[1], row[2], row[3], row[4], row[5], row[6], row[7], row[8], row[9]])
    time.sleep(5)
    subprocess.call('QuikPassProcessor.bat') 
input()