from MyFun import *
import win32com.client as win32
import smtplib


def smtpsendemail():
    #Send the mail
    try:
        server = smtplib.SMTP('mail.open-broker.com', 587) # Какой SMTP сервер?
        # Next, log in to the server
        server.login("lgn", "pwd")
        msg = "Hello!" # The /n separates the message from the headers
        server.sendmail("sigoshin_my@open.ru", msg)
    except Exception as err:
        log(err)
        fun_monitoringCPU()  # Вызов функции мониторинга


def sendoutlookemail(sendtext, subjecttext):
    try:
        outlook = win32.Dispatch('outlook.application')
        mail = outlook.CreateItem(0)
        mail.To = alertemail
        mail.Subject = subjecttext  # 'Message subject'
        mail.Body = sendtext + '\n\n\n\n Инструкция https://conf.open-broker.ru/pages/viewpage.action?pageId=150422169'  # 'Message body'
        mail.HTMLBody = sendtext + '\n\n\n\n Инструкция https://conf.open-broker.ru/pages/viewpage.action?pageId=150422169' # '<h2>HTML Message body</h2>' this field is optional
        # To attach a file to the email (optional):
        # attachment  = "Path to the attachment"
        # mail.Attachments.Add(attachment)
        mail.Send()
    except Exception as err:
        log(err)
        fun_monitoringCPU()  # Вызов функции мониторинга