import requests
import json
with open('config.json') as f:
    config = json.load(f)
    baseUrl = config['baseUrl']
    endpoint = config['endpoint']
    params = "&".join(config["params"])
    url = baseUrl + endpoint + "?" + params
    print(url)
    headers = config['headers']
    print(headers)
    response = requests.get(url, headers=headers)
    print(response.json())
    #save the response to a file
    with open('response.json', 'w') as f:
        json.dump(response.json(), f, ensure_ascii=False)