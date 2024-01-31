1) Проверить Java и версию jdk-11.0.2, отправка происходит утилитой mass-letter-sender.jar. Закинуть json_and_key_gen.exe +  AutoSender.exe в папу с mass-letter-sender.jar
Дополнительно проверить путь в quikPassProcessor.cmd 
2)Запустить json_and_key_gen.exe
3) В окне вводим свою УЗ без OPEN.RU\ и пароль
4)  Жмем кнопку "Создать файл" и потом "Закрыть"
5  Проверяем, что создались файлы crypto.key и userdata.json
6) Редактируем userdata.json таким образом:
				"password": "b'gAAAAABlb4yHUooPvi5dIw51Yec8kQPeCmRK8gTc6_2Xhklyx4-4UgQcYDzMbLIaS7PSTiQCjl3C_wjhyjKQrsrQFL4ug8eFzg=='" 
				заменяем на
				"password": "gAAAAABlb4yHUooPvi5dIw51Yec8kQPeCmRK8gTc6_2Xhklyx4-4UgQcYDzMbLIaS7PSTiQCjl3C_wjhyjKQrsrQFL4ug8eFzg=="
				(убираем b' в начале и ' в конце)
7) Проверяем наличие chromedriver.exe в каталоге и его соответствие версии Chrome.
8) запускаем AutoSender