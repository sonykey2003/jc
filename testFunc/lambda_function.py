import requests
def getGeoFromIP(IP):
    url = "http://ip-api.com/json/" + IP
    r = requests.get(url)
    return r.json()


geo = getGeoFromIP("129.126.8.35")
print(geo)

