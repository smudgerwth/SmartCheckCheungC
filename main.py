import os
import sys
import requests
import json
from datetime import datetime
import sendTgMsg
import re
from playwright.sync_api import Playwright, sync_playwright, expect
import time

debug_enabled = True
header_cookie = None

def DBG(message):
    if debug_enabled:
        print(message)

def run(playwright: Playwright) -> None:
    browser = playwright.chromium.launch(headless=True)
    context = browser.new_context()
    page = context.new_page()
    page.set_default_timeout(60000)
    page.goto("https://www.smartplay.lcsd.gov.hk/website/en/index.html")
    with page.expect_popup() as page1_info:
        page.get_by_role("link", name="Login").click()
    page1 = page1_info.value
    page.set_default_timeout(60000)
    page1.wait_for_load_state('networkidle')
    # page1.get_by_role("button", name="Facilities").click()

    cookies = context.cookies()

    # Find the specific cookie
    acw_cookie = next((cookie for cookie in cookies if cookie['name'] == 'acw_sc__v2'), None)
    if acw_cookie:
        # Save to JSON file
        global header_cookie 
        header_cookie = f"{acw_cookie['name']}={acw_cookie['value']}"
        print(header_cookie)
    # ---------------------
    context.close()
    browser.close()


with sync_playwright() as playwright:
    run(playwright)

def request_data_json(date):
    global header_cookie 
    with open('config.json') as f:
        config = json.load(f)
        baseUrl = config['baseUrl']
        endpoint = config['endpoint']
        params = "&".join(config["params"])
        dateKey = config['dateKey']
        url = f"{baseUrl}{endpoint}?{params}&{dateKey}={date}"
        # DBG(url)
        headers = config["headers"]
        if header_cookie:
            headers["Cookie"] = header_cookie
        # DBG(headers)
        try:
            response = requests.get(url, headers=headers, timeout=30)
            if response.status_code == 200:
                # DBG(response.json())
                return response.json()
            else:
                print(f"Request failed with status code: {response.status_code}")
                return None
        except requests.exceptions.RequestException as e:
            print(f"Request failed: {e}")
            return None

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
        if new_record["available"] is True:
            if not combination_exists or old_record["available"] is False:
                changed_records.append(new_record)
    return changed_records

try:
    current_date = datetime.now().date().strftime("%Y-%m-%d")
    DBG(current_date)
    today_data_json = request_data_json(current_date)
    if today_data_json is None:
        sys.exit()

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
        old_json = []
        if os.path.exists('data_old.json'):
            old_json = json.load(open('data_old.json'))
        changed_record = get_changed_records(old_json, data_json)
        with open('changed.json', 'w') as f:
            json.dump(changed_record, f, ensure_ascii=False, indent=4)
        sendTgMsg.send_result(changed_record)

    DBG(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
except:
    DBG("error")
    exit(1)
    
