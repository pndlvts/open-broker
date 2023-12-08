#!C:\Users\TIMOFEY\Desktop\AutoPassSender_QUIK\AutoPassSender_QUIK\Scripts\python.exe

from tkinter import *
from tkinter import ttk
#import hashlib as h
import json
from cryptography.fernet import Fernet

class App:
    def __init__(self):
        self.root = Tk() #Создаем окно
        self.root.title('OPPS - SHA256 Generator')
        self.root.geometry('200x100')  
        self.root.resizable(True, False)
        self.root.attributes('-alpha', 0.9)
        self.lg_label = ttk.Label(text = 'Логин')
        self.lg_label.grid(row = 0, column = 0, sticky=W+E, pady=5) 
        self.username_entry = ttk.Entry()
        self.username_entry.grid(row = 0, column= 1, sticky=W+E, pady=5)
        self.ps_label = ttk.Label(text = 'Пароль')
        self.ps_label.grid(row = 1, column = 0, sticky=W+E, pady=5)
        self.password_entry = ttk.Entry()
        self.password_entry.grid(row = 1, column = 1, sticky=W+E, pady=5)
        self.btn = ttk.Button(text="Создать файл", command=self.show_data)
        self.btn.grid(row = 2, column = 1, sticky='WE', pady=5)
        self.result_name_lbl = ttk.Label()
        self.result_name_lbl.grid(row = 3, column = 0, sticky=W+E, pady=5) 
        self.result_hash_lbl = ttk.Label()
        self.result_hash_lbl.grid(row = 4, column = 0, sticky=W+E, pady=5) 
        self.root.mainloop()

    def show_data(self):
        self.usr = User(self.username_entry.get(), self.password_entry.get())
        self.create_json(self.usr)
        self.result_name_lbl['text'] = 'Доменное  имя: ' +  self.usr.username
        self.result_hash_lbl['text'] = 'Зашифрованный пароль: ' + self.usr.password + '\n Проверьте'
        self.username_entry.destroy()
        self.password_entry.destroy()
        self.btn.destroy()
        self.result_name_lbl.grid(row = 0, column = 0, sticky=W+E, pady=5) 
        self.result_hash_lbl.grid(row = 1, column = 0, sticky=W+E, pady=5) 
        self.btn = ttk.Button(text="Закрыть", command=self.root.destroy)
        self.btn.grid(row = 2, column = 0, sticky=W+E, pady=5)
        self.root.geometry('850x150')

    def create_json(self,usr):
        jsontxt = json.dumps(usr.__dict__)
        f = open('userdata.json', 'w')
        f.write(jsontxt)
class User:
    def __init__(self, name, pswd): #конструктор
        self.username =  name 
        self.password = pswd
        self.generate_password()

    def generate_password(self): #шифруем
         key = Fernet.generate_key()
         with open('crypto.key', 'wb') as key_file:
            key_file.write(key)
         f = Fernet(key)     
         self.password = str(f.encrypt(self.password.encode()))
app = App()