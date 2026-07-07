import os
import sys
import requests
import json
from datetime import datetime, time as dt_time
import sendTgMsg
import re
# from playwright.sync_api import Playwright, sync_playwright, expect
import time

debug_enabled = True
header_cookie = None


def DBG(message):
    if debug_enabled:
        print(message)


def add_key_to_json(file_path, name, value, expire_time) -> None:
    data = {}
    data['Cookie'] = f"{name}={value}"
    data['expires'] = expire_time
    with open(file_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=4)


# def run(playwright: Playwright) -> None:
#     browser = playwright.chromium.launch(headless=True)
#     context = browser.new_context()
#     page = context.new_page()
#     page.set_default_timeout(60000)
#     page.goto("https://www.smartplay.lcsd.gov.hk/website/en/index.html")
#     with page.expect_popup() as page1_info:
#         page.get_by_role("link", name="Login").click()
#     page1 = page1_info.value
#     page1.set_default_timeout(60000)
#     try:
#         page1.wait_for_load_state('networkidle')
#     except:
#         time.sleep(30)
#     # page1.get_by_role("button", name="Facilities").click()

#     cookies = context.cookies()
#     DBG(cookies)

#     acw_tc_cookie = next(
#         (cookie for cookie in cookies if cookie['name'] == 'acw_tc'), None)
#     acw_sc_cookie = next(
#         (cookie for cookie in cookies if cookie['name'] == 'acw_sc__v2'), None)
#     if acw_tc_cookie and acw_sc_cookie:
#         add_key_to_json(
#             'cookies.json', acw_sc_cookie['name'], acw_sc_cookie['value'], acw_tc_cookie['expires'])

#     context.close()
#     browser.close()


def get_cookies():
    with sync_playwright() as playwright:
        run(playwright)


def request_data_json(url, headers):
    # DBG(url)
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


def matches_config_filter(value, config_filter):
    if config_filter is None:
        return True

    value = str(value)
    if 'include' in config_filter:
        return value in {str(item) for item in config_filter['include']}
    if 'exclude' in config_filter:
        return value not in {str(item) for item in config_filter['exclude']}
    return True


def make_file_key(facility, facility_index):
    raw_key = facility.get('fileKey') or f"{facility['code']}_{facility_index}"
    file_key = re.sub(r'[^A-Za-z0-9_.-]+', '_', str(raw_key)).strip('_.-')
    return file_key or f"facility_{facility_index}"


def time_in_range(value, time_range):
    value_time = datetime.strptime(value, "%H:%M:%S").time()
    start_time = datetime.strptime(time_range['start'], "%H:%M:%S").time()
    end_time = datetime.strptime(time_range['end'], "%H:%M:%S").time()
    return start_time <= value_time < end_time


def matches_time_slot_filter(value, time_slot_list):
    if time_slot_list is None:
        return True

    if 'include' in time_slot_list:
        return any(time_in_range(value, time_range) for time_range in time_slot_list['include'])
    if 'exclude' in time_slot_list:
        return not any(time_in_range(value, time_range) for time_range in time_slot_list['exclude'])
    return True


def parse_response_json(json_data, peak_only=False, dist_list=None, venue_id_list=None, time_slot_list=None):
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
                        if datetime.strptime(start_time, "%H:%M:%S").time() <= dt_time(9,0,0):
                            continue
                        # if available is False:
                        #     continue
                        if peak_hour is False and peak_only:
                            continue
                        if not matches_config_filter(dist_code, dist_list):
                            continue
                        if not matches_config_filter(venue_id, venue_id_list):
                            continue
                        if not matches_time_slot_filter(start_time, time_slot_list):
                            continue
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


debug_id = ""
try:
    current_time = int(time.time())
    for i in range(3):
        with open('config.json', encoding='utf-8') as f:
            config = json.load(f)
            debug_id = config['debugId']
            # try:
            #     with open('cookies.json') as f:
            #         cookies = json.load(f)
            #         if 'expires' not in cookies:
            #             DBG("No Cookie")
            #             get_cookies()
            #             continue
            #         expires = cookies['expires']
            #         if current_time + 60 > expires:
            #             DBG("Cookie expired")
            #             get_cookies()
            #             continue
            # except FileNotFoundError:
            #     DBG("No Cookie file")
            #     get_cookies()
            #     continue

            baseUrl = config['baseUrl']
            endpoint = config['endpoint']
            dateKey = config['dateKey']
            facility_key = config['facilityKey']
            facility_list = config['facilityList']
            for facility_index, facility in enumerate(facility_list, start=1):
                chat_id = facility['chatId']
                code = facility['code']
                file_key = make_file_key(facility, facility_index)
                peakhour = facility.get('peakhour', True)
                dist_list = facility['distList']
                venue_id_list = facility.get('venueIdList')
                time_slot_list = facility.get('timeSlotList')
                name = facility['name']
                url = f"{baseUrl}{endpoint}?{facility_key}={code}&{dateKey}="
                DBG(name)
                # DBG(url)
                # config["headers"]["Cookie"] = f"{cookies['Cookie']}"
                headers = config["headers"]
                # DBG(headers)
                current_date = datetime.now().date().strftime("%Y-%m-%d")
                DBG(current_date)
                today_data_json = request_data_json(url+current_date, headers)

                if today_data_json is None:
                    sys.exit()

                play_dates = [entry['playDate']
                              for entry in today_data_json['data']['venueCountList']]
                # DBG(play_dates)
                data_json = []
                data_json += parse_response_json(today_data_json,
                                                 peak_only=peakhour,
                                                 dist_list=dist_list,
                                                 venue_id_list=venue_id_list,
                                                 time_slot_list=time_slot_list)
                for i, date in enumerate(play_dates):
                    if i == len(play_dates) - 1:
                        continue
                    if date == current_date:
                        continue
                    DBG(date)
                    data_json += parse_response_json(request_data_json(
                        url+date, headers), peak_only=peakhour,
                        dist_list=dist_list, venue_id_list=venue_id_list,
                        time_slot_list=time_slot_list)

                data_json_file = f"data_{file_key}.json"
                old_data_json_file = f"data_old_{file_key}.json"
                diff_json_file = f"diff_{file_key}.json"
                if os.path.exists(data_json_file):
                    os.replace(data_json_file, old_data_json_file)

                with open(data_json_file, 'w', encoding='utf-8') as f:
                    json.dump(data_json, f, ensure_ascii=False, indent=4)
                    old_json = []
                    if os.path.exists(old_data_json_file):
                        try:
                            with open(old_data_json_file, encoding='utf-8') as old_file:
                                old_json = json.load(old_file)
                        except json.JSONDecodeError:
                            DBG(f"Ignoring invalid old data file: {old_data_json_file}")
                    changed_record = get_changed_records(old_json, data_json)
                    with open(diff_json_file, 'w', encoding='utf-8') as diff_file:
                        json.dump(changed_record, diff_file,
                                  ensure_ascii=False, indent=4)
                    if changed_record != []:
                        sendTgMsg.send_result(changed_record, chat_id, name)

                DBG(datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
            sendTgMsg.sendTgMsg('ping', debug_id)
            exit(0)
except Exception as e:
    DBG(f"An error occurred: {e}")
    sendTgMsg.sendTgMsg('error', debug_id)
    exit(1)
