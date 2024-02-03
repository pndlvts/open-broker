import os.path
import datetime
import logging
import colorama as color
import win32com.client as win32
from sys import argv

def email_reader_writer(logger_var):
    if os.path.exists('email.txt'):
        #читаем файл
        f = open('email.txt', 'r+')
        try:
            email = str(f.readline())
            print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Файл email.txt прочитан. Считаны получатели: ' + email)
            while True:
                answer = input('Требуется изменить? (Y/N): ')
                if answer == 'Y' or answer == 'y':
                    f.truncate(0)
                    email = str(input('Введите получателей: '))
                    f.write(email)
                    print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Файл email.txt перезаписан. Записаны получатели: ' + email)
                    logger_var.info('Файл email.txt перезаписан! Записаны получатели: ' + email)
                elif answer == 'N' or answer == 'n':
                    logger_var.info('Файл email.txt прочитан. Отправка на получателей: ' + email)
                    break
                else:
                    print(color.Back.YELLOW + color.Fore.WHITE + color.Style.BRIGHT + 'Некорректный пользовательский ввод! Повторите: ')
        finally:
            f.close()
    else:
        print(color.Back.YELLOW + color.Fore.WHITE + color.Style.BRIGHT + 'Файл email.txt не обнаружен. Он будет создан в каталоге скрипта.')
        logger_var.warning('Файл email.txt не обнаружен.')
        f = open('email.txt', 'w+')
        try:
            print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Формат ввода: pandelov_ts@open.ru;trebish@open.ru')
            email = str(input('Введите получателей: '))
            f.write(email)
            print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Файл email.txt создан. Записаны получатели: ' + email)
            logger_var.info('Файл email.txt создан. Записаны получатели: ' + email)
        finally:
            f.close()
    return email

def email_reader(logger_var):
    if os.path.exists('email.txt'):
        f = open('email.txt', 'r')
        try:
            email = str(f.readline())
            print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Файл email.txt прочитан. Считаны получатели: ' + email)
            logger_var.info('Файл email.txt прочитан. Отправка на получателей: ' + email)
        finally:
            f.close()
    return email

def mail_sender(email, logger_var):
    mode = argv[1]
    while True:
        if mode == 'STARTD':
            title = 'начало работы'
            print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Тема письма: ' + title + '\MODE = ' + mode)
            logger_var.info('MODE = STARTD, Тема письма: ' + title)
            break
        elif mode == 'ENDD':
            title = 'окончание работы'
            print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Тема письма: ' + title + '\MODE = ' + mode)
            logger_var.info('MODE = ENDD, Тема письма: ' + title)
            break
        else:
            mode = str(input('Некорректный параметр. Введите вручную (STARTD/ENDD): '))
            mode = mode.upper()
            logger_var.info('Ручной параметр MODE: ' + mode)
    try:
        outlook = win32.Dispatch('outlook.application')
        mail = outlook.CreateItem(0)
        mail.To = email #список получателей
        mail.Subject = title  # тема письма
        mail.Body = ''
        mail.HTMLBody = ''
        mail.Send()
        print(color.Back.CYAN + color.Fore.WHITE + color.Style.BRIGHT  + 'Отправлено!')
        logger_var.info('Письмо отправлено! MODE - ' + mode + '. Тема письма: ' + title)
    except:
        print(color.Fore.RED + 'Не удалось отправить письмо')
        logger_var.error('Ошибка отправки письма на адрес(а): ' + email)
        exit(1)

def main():
    #подключаем логирование
    logger = logging.getLogger(__name__)
    logger.setLevel(logging.INFO)
    file_handler = logging.FileHandler('logfile.log', 'a+')
    file_handler.setFormatter(logging.Formatter('%(asctime)s    %(levelname)s   %(message)s', '%d.%m.%Y %H:%M:%S'))
    logger.addHandler(file_handler)
    #colorama init
    color.init(autoreset=True)
    #далее основной функционал
    logger.info('-------------------START-------------------')
    if len(argv) < 3:
        print(color.Fore.RED + 'Ошибка. Скрипт не выполнен. Не получены все аргументы')
        logger.error('Ошибка. Скрипт не выполнен. Не получены все аргументы.')
        logger.info('-------------------END-------------------')
        exit(1)
    scheduler = str(argv[2]).lower()
    print(scheduler)
    if scheduler == 'true':
        email_list = email_reader(logger)
        mail_sender(email_list, logger)
    elif scheduler == 'false':
        email_list = email_reader_writer(logger) 
        mail_sender(email_list, logger)
    else:
        print(color.Fore.RED + 'Ошибка. Скрипт не выполнен. Не получен корректный параметр scheduler (True/False)')
        logger.error('Ошибка. Скрипт не выполнен. Не получен корректный параметр scheduler (True/False)')
    logger.info('-------------------END-------------------')

main()
input()