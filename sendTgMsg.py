import requests
import time
import os
import pandas as pd
from pathlib import Path

CHAT_ID_BADMINTON_ALL = '-1001664412034'
CHAT_ID_BADMINTON_HOLI = '-563254817'
CHAT_ID_BADMINTON_WEEK = '-562433679'
CHAT_ID_BASKETBALL = '-1002349404473'
CHAT_ID_BADMINTON_NTW = '-1001896497593'
CHAT_ID_TENNIS = '-5255744266'
CHAT_ID_DEBUG = '166389413'

# https://api.telegram.org/bot{TOKEN}/getUpdates

MSG_DELAY = 0

day_chinese = {'Monday': '一', 'Tuesday': '二', 'Wednesday': '三',
               'Thursday': '四', 'Friday': '五', 'Saturday': '六', 'Sunday': '日'}
# day = pd.to_datetime('2024-06-04').strftime('%A')
# print(day_chinese[pd.to_datetime('2024-06-04').strftime('%A')])


def path(fn):
    return (os.path.join(os.path.dirname(os.path.abspath(__file__)), fn))


def sendTgMsg(msg, chat_id):
    with open(path('token'), 'r') as f:
        TOKEN = f.read()
    requests.post('https://api.telegram.org/bot'+TOKEN +
                  '/sendMessage?chat_id='+chat_id+'&text='+msg)
    time.sleep(MSG_DELAY)


MAX_LENGTH = 4096


def send_result(json_data, chat_id, name = ''):
    if json_data == '':
        return
    msg = name + '\n'
    for data in json_data:
        data['venueName'] = data['venueName'].replace('體育館', '')
        day = day_chinese[pd.to_datetime(data['ssnStartDate']).strftime('%A')]
        data['ssnStartDate'] = data['ssnStartDate'][5:]
        data['ssnStartTime'] = data['ssnStartTime'][:5]
        msg += data['ssnStartDate'] + ', ' + day + ', ' + data['venueName'] + \
            ', ' + data['ssnStartTime'] + ', ' + \
            str(data['sessionCount']) + '\n'
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
        sendTgMsg(part, chat_id)

if __name__ == "__main__":
    sendTgMsg("Hi", CHAT_ID_DEBUG)
