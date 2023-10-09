import wmi


def cpu_info(servername):
    pc = wmi.WMI(''+servername+'') #  10.157.39.114   , user=r"bd-vm-soap-n\sigoshin_my-adm", password=""
    cpu = pc.Win32_Processor()
    for i in cpu:
        return i.LoadPercentage
