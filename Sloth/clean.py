#1
import os 
from os import listdir
#2
folder_path = "%s/Sloth/" % os.getcwd()
#3
for file_name in listdir(folder_path):
    #4
    if file_name.endswith('.c') or file_name.endswith('.pyd') or file_name.endswith('.html'):
        #5
        os.remove(folder_path + file_name)