# -*- coding: utf-8 -*-
import paramiko
import os



def upload(ip, port, username, passwd, local_file_path, remote_file_path):#上传文件函数
    try:
        t = paramiko.Transport((ip, port))
        t.connect(username=username, password=passwd)
        sftp = paramiko.SFTPClient.from_transport(t)
        sftp.put(local_file_path, remote_file_path)
        t.close()
    except Exception as e:
        print('%s' % e)

def download(ip, port, username, passwd, local_file_path, remote_file_path):#下载文件函数
    try:
        t = paramiko.Transport((ip, port))
        t.connect(username=username, password=passwd)
        sftp = paramiko.SFTPClient.from_transport(t)
        sftp.get(remote_file_path, local_file_path)
        t.close()
    except Exception as e:
        print('%s' % e)
if __name__ == '__main__':
    local_path = os.path.abspath(os.path.dirname(__file__)) + "/aaa.py"
    remote_path = "/root/aaa.py"
    upload("10.0.2.15", 22, "root", "***password***", local_path, remote_path)
    local_path = os.path.abspath(os.path.dirname(__file__)) + "/const.py"
    remote_path = "/root/const.py"
    download("10.0.2.15", 22, "root", "***password***", local_path, remote_path)
#ls-al 当前目录所有文件 