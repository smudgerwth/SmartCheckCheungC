import requests
import json
from datetime import datetime
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
        DBG(url)
        headers = config['headers']
        DBG(headers)
        response = requests.get(url, headers=headers)
        DBG(response.json())
        return response.json()

dict_cnt=0
list_cnt=0
def filter_json(json_data, key, value):
    global dict_cnt
    global list_cnt
    if isinstance(json_data, dict):
        dict_cnt += 1
        print(dict_cnt)
        return {k: filter_json(v, key, value) for k, v in json_data.items() if k != key or v != value}
    elif isinstance(json_data, list):
        list_cnt += 1
        print(list_cnt)
        return [filter_json(item, key, value) for item in json_data if not (isinstance(item, dict) and item.get(key) == value)]
    else:
        return json_data

current_date = datetime.now().date().strftime("%Y-%m-%d")
DBG(current_date)
today_data_json = request_data_json("2024-06-03")
play_dates = [entry['playDate'] for entry in today_data_json['data']['venueCountList']]
DBG(play_dates)

updated_json_data = filter_json(today_data_json, "sessionCount", 0)
# DBG(updated_json_data)
for date in play_dates:
    if date == current_date:
        continue
    DBG(date)
    # request_data_json(date)
#save the response to a file
with open('response.json', 'w') as f:
    json.dump(today_data_json, f, ensure_ascii=False)
with open('filterd.json', 'w') as f:
    json.dump(updated_json_data, f, ensure_ascii=False)