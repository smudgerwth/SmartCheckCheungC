import requests
import time
import os
import shutil
import pandas as pd
from pathlib import Path

CHAT_ID_ALL = '-1001664412034'
CHAT_ID_HOLI = '-563254817'
CHAT_ID_WEEK = '-562433679'
CHAT_ID_HKI = '-760118570'
CHAT_ID_HKI2 = '-697240120'
CHAT_ID_NTW = '-1001896497593'
CHAT_ID_DEBUG = '166389413'

MSG_DELAY = 0

column_name = ["Date","Day","Holiday","Time","Venue","Area"]
day_chinese = {'Monday': '一', 'Tuesday': '二', 'Wednesday': '三', 'Thursday': '四', 'Friday': '五', 'Saturday': '六', 'Sunday': '日'}
# day = pd.to_datetime('2024-06-04').strftime('%A')
# print(day_chinese[pd.to_datetime('2024-06-04').strftime('%A')])

def path(fn):
    return(os.path.join(os.path.dirname(os.path.abspath(__file__)), fn))

with open(path('token'), 'r') as f:
    TOKEN = f.read()

def sendTgMsg(msg,chat_id):
    requests.post('https://api.telegram.org/bot'+TOKEN +
                  '/sendMessage?chat_id='+chat_id+'&text='+msg)
    time.sleep(MSG_DELAY)

MAX_LENGTH=4096

def send_result(json_data):
    msg = ''
    for data in json_data:
        data['venueName'] = data['venueName'].replace('體育館','')
        day = day_chinese[pd.to_datetime(data['ssnStartDate']).strftime('%A')]
        data['ssnStartDate'] = data['ssnStartDate'][5:]
        data['ssnStartTime'] = data['ssnStartTime'][:5]
        msg += data['ssnStartDate'] + ', ' + day + ', ' + data['venueName'] + ', ' + data['ssnStartTime'] + ', ' + str(data['sessionCount']) + '\n'
    if len(msg) > MAX_LENGTH:
        parts = []
        current_part = ""
        lines = msg.splitlines()
        for line in lines:
            if len(current_part) + len(line) + 1 > MAX_LENGTH:
                parts.append(current_part)
                current_part = ""
            current_part += line + "\n"
        if current_part:
            parts.append(current_part)
    else:
        parts = [msg]
    for part in parts:
        # print(part)
        sendTgMsg(part, CHAT_ID_DEBUG)
    # msg = ''
    # json_data = [x for x in json_data if x['peakHour'] == True]
    # for data in json_data:
    #     msg += data['venueName'] + ' ' + data['ssnStartDate'] + ' ' + data['ssnStartTime'] + ' ' + str(data['sessionCount']) + '\n'
    # print(msg)
    # sendTgMsg(msg, CHAT_ID_HOLI)
    #Send only holiday
    # selDay = ["六","日"]
    # holi_diff = diff.query('(Day in @selDay | Holiday=="H") & Area != "*NTW" & Area != "*HK"')
    # if not holi_diff.empty:
    #     sendTgMsg(holi_diff.drop(["Holiday","Area"],axis=1).to_csv(sep = ',', index = False, header = None),CHAT_ID_HOLI)

    # #Send only weekday night
    # selDay = ["一","二","三","四","五"]
    # selTime = ["19:00","20:00","21:00","22:00"]
    # weekD_diff = diff.query('Time in @selTime & Day in @selDay & Holiday=="N" & Area != "*NTW" & Area != "*HK"')
    # if not weekD_diff.empty:
    #     sendTgMsg(weekD_diff.drop(["Holiday","Area"],axis=1).to_csv(sep = ',', index = False, header = None),CHAT_ID_WEEK)


# Send debug msg
# sendTgMsg('ping',CHAT_ID_DEBUG)
# import json
# send_result(json.load(open('changed.json')))
