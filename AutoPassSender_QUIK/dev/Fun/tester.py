import datetime
import time
from selenium import webdriver
from selenium.webdriver.chrome.service import Service
from selenium.webdriver.common.by import By
import json
from cryptography.fernet import Fernet
import pyodbc
import sys
import locale
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
s = Service('chromedriver.exe')
driver = webdriver.Chrome(service=s) 
driver.get('https://conf.open-broker.ru/login.action?logout=true') 
login_input = driver.find_element(By.ID, 'os_username')
login_input.send_keys(USER['username'])
password_input = driver.find_element(By.ID, 'os_password')
password_input.send_keys(USER['password'])
logon_button = driver.find_element(By.ID, 'loginButton')
logon_button.click()
driver.get('https://conf.open-broker.ru/display/PROC/QUIK+Resend')
driver.find_element(By.ID, 'quick-create-page-button').click()
driver.find_element(By.ID, 'content-title').send_keys('TEST')
driver.find_element(By.ID, 'rte-button-insert-table').click()
driver.find_element(By.XPATH, '//*[@id="table-picker-container"]').click()
iframe = driver.find_element(By.ID, 'wysiwygTextarea_ifr') 
driver.switch_to.frame(iframe)
par = driver.find_element(By.TAG_NAME, 'p')
par.click()
par.send_keys('''

Сначала смотрим Наиболее частые проблемы и пытаемся самостоятельно решить с клиентом
Все счета указываем строго  с BF 
Дополнительные таблицы не создаем. Дополняем строки в существующей
''')
par.click()
driver.switch_to.default_content()
driver.find_element(By.ID, 'rte-button-link').click()
driver.find_element(By.ID, 'weblink-panel-id').click() 
time.sleep(2)
driver.find_element(By.ID, 'weblink-destination').send_keys('https://conf.open-broker.ru/display/PROC/QUIK+Resend#QUIKResend-%D0%9D%D0%B0%D0%B8%D0%B1%D0%BE%D0%BB%D0%B5%D0%B5%D1%87%D0%B0%D1%81%D1%82%D1%8B%D0%B5%D0%BF%D1%80%D0%BE%D0%B1%D0%BB%D0%B5%D0%BC%D1%8B')
time.sleep(1)
driver.find_element(By.ID, 'alias').clear()
driver.find_element(By.ID, 'alias').send_keys('Список наиболее частых проблем')
driver.find_element(By.ID, 'link-browser-insert').click()
driver.switch_to.frame(iframe)
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[1]').click()
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[1]').send_keys('Номер брокерского счета клиента в партнере строго по маске XXXXXX-BF')
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[2]').click()
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[2]').send_keys('Причина переотправки')
driver.find_element(By.XPATH, '/html/body/table/tbody/tr[1]/th[3]').click()
driver.switch_to.default_content()
driver.find_element(By.XPATH, '//*[@id="rte-toolbar-row-default"]/div[5]/button[3]').click()


time.sleep(10)
driver.switch_to.default_content()
driver.find_element(By.ID, 'rte-button-cancel').click()
driver.close()