import os
import requests
import json
from datetime import datetime
import sendTgMsg

debug_enabled = True
def DBG(message):
    if debug_enabled:
        print(message)

def request_data_json(date):
    with open('config.json') as f:
        config = json.load(f)
        baseUrl = config['baseUrl']
        endpoint = config['endpoint']
        params = "&".join(config["params"])
        dateKey = config['dateKey']
        url = baseUrl + endpoint + "?" + params + "&" + dateKey + "=" + date
        # DBG(url)
        headers = config['headers']
        # DBG(headers)
        response = requests.get(url, headers=headers)
        # DBG(response.json())
        return response.json()
    
def parse_response_json(json_data):
    parsed_json = []
    times_of_day = ['morning', 'afternoon', 'evening']
    for time in times_of_day:
        time_list = json_data['data'][time]['distList']
        for entry in time_list:
            dist_name = entry['distName']
            dist_code = entry['distCode']
            venue_list = entry['venueList']
            for venue in venue_list:
                venue_name = venue['venueName']
                venue_id = venue['venueId']
                fat_list = venue['fatList']
                for fat in fat_list:
                    fat_name = fat['fatName']
                    fat_id = fat['fatId']
                    session_list = fat['sessionList']
                    for session in session_list:
                        start_time = session['ssnStartTime']
                        date = session['ssnStartDate']
                        available = session['available']
                        session_count = session['sessionCount']
                        peak_hour = session['peakHour']
                        parsed_json.append({
                            'distName': dist_name,
                            'distCode': dist_code,
                            'venueName': venue_name,
                            'venueId': venue_id,
                            'fatName': fat_name,
                            'fatId': fat_id,
                            'ssnStartTime': start_time,
                            'ssnStartDate': date,
                            'available': available,
                            'sessionCount': session_count,
                            'peakHour': peak_hour
                        })
    return parsed_json

def get_changed_records(old_json, new_json):
    changed_records = []
    for new_record in new_json:
        combination_exists = False
        for old_record in old_json:
            if (
                old_record["venueId"] == new_record["venueId"]
                and old_record["ssnStartTime"] == new_record["ssnStartTime"]
                and old_record["ssnStartDate"] == new_record["ssnStartDate"]
            ):
                combination_exists = True
                break
        if not combination_exists or new_record["available"] is True and old_record["available"] is False:
            changed_records.append(new_record)
    return changed_records

current_date = datetime.now().date().strftime("%Y-%m-%d")
DBG(current_date)
today_data_json = request_data_json(current_date)
play_dates = [entry['playDate'] for entry in today_data_json['data']['venueCountList']]
# DBG(play_dates)
data_json = []
data_json += parse_response_json(today_data_json)
for i, date in enumerate(play_dates):
    if i == len(play_dates) - 1:
        continue
    if date == current_date:
        continue
    DBG(date)
    data_json += parse_response_json(request_data_json(date))

if os.path.exists('data.json'):
    os.rename('data.json', 'data_old.json')
    
with open('data.json', 'w') as f:
    json.dump(data_json, f, ensure_ascii=False, indent=4)
    if os.path.exists('data_old.json'):
        changed_record = get_changed_records(json.load(open('data_old.json')), data_json)
        with open('changed.json', 'w') as f:
            json.dump(changed_record, f, ensure_ascii=False, indent=4)

sendTgMsg.send_result(changed_record)
