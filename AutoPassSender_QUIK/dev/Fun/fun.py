import pyodbc
import csv
import subprocess
try:
    sql_query = 'select * from company'
    conn =  pyodbc.connect('Trusted Connection=yes; Server=PANDELOV-PC; Driver={SQL Server}; Database=aero')
    conn.autocommit = True
except pyodbc.Error as err:
    print('Не удалось подключиться к БД: ' + err)
try:
    cursor = conn.cursor()
    cursor.execute(sql_query)
except pyodbc.Error as err:
    print('Запрос не выполнен: ' + err)
arr = cursor.fetchall()
with open('list.csv', 'w', encoding='utf-8') as csv_file:
    csv_writer = csv.writer(csv_file, delimiter=';', lineterminator='\r')
    csv_writer.writerow(['id', 'name'])
    for row in arr:
         csv_writer.writerow([row[0], row[1]])
subprocess.call('test.bat')


'''
1	Don_avia  
2	Aeroflot  
3	Dale_avia 
4	air_France
5	British_AW
'''

