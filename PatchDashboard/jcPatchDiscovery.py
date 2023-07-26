
# requires conda core
import requests
from bs4 import BeautifulSoup
import pandas as pd


# Release Info URLs and API Key
## Windows
win11ReInfoUrl = "https://learn.microsoft.com/en-us/windows/release-health/windows11-release-information"
win10ReInfoUrl = "https://learn.microsoft.com/en-us/windows/release-health/release-information"
macOSReInfoUrl = 'https://en.wikipedia.org/wiki/MacOS_version_history'
apikey='ee6efb89fa63259b00e48f575d3935d9277789b7' #shawn's RO
#apikey = '12dd73757f99dcd67b3258f8f8c2b4adddee716d' #se tenant

def getTables (url):
    re = requests.get(url)
    Soup = BeautifulSoup(re.text, 'html.parser')

    # Find the table in the HTML and parse it into a DataFrame
    tables = Soup.find_all('table')
    return tables

def getJCSystem (apikey,limit=100,skip=0):
    base_url = "https://console.jumpcloud.com/api"
    headers = {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'x-api-key': apikey
    }
    url = f"{base_url}/systems"
    systems = []
    while True:
        params = {'limit': limit, 'skip': skip}
        response = requests.get(url, headers=headers,params=params)
        skip += limit 
        results = response.json()['results']
        if response.status_code == 200 and results:
            systems += results
        else:
            break
    return systems

def clean_macOS_table(macOS_table):
    macOS_table.drop(macOS_table.index[-1], inplace=True)
    macOS_table.drop(['Kernel', 'Dateannounced', 'Releasedate','Darwinversion','Processorsupport','Applicationsupport','Unnamed: 9'], axis=1, inplace=True)
    macOS_table['Version Number'] = macOS_table['Most recentversion'].str.rsplit('(', 1).str[0]
    macOS_table['Release Date'] = macOS_table['Most recentversion'].str.rsplit('(', 1).str[1].str.rstrip(')')
    macOS_table['Release Date'] = pd.to_datetime(macOS_table['Release Date'], errors='coerce')
    macOS_table.drop('Most recentversion', axis=1, inplace=True)
    return macOS_table



JCSystems = getJCSystem(apikey=apikey)

# Win11 Tables
Win11_All = getTables(win11ReInfoUrl)

Win11_CuVer = pd.read_html(str(Win11_All))[0]
Win11_22H2 = pd.read_html(str(Win11_All))[1]
Win11_21H2 = pd.read_html(str(Win11_All))[2]

# MacOS Table
MacOS_All = pd.read_html(str(getTables(macOSReInfoUrl)))[2]

MacOS_All.drop(MacOS_All.index[-1], inplace=True)
MacOS_All.drop(['Kernel', 'Dateannounced', 'Releasedate','Darwinversion','Processorsupport','Applicationsupport','Unnamed: 9'], axis=1, inplace=True)

MacOS_All['Version Number'] = MacOS_All['Most recentversion'].str.rsplit('(', 1).str[0]
MacOS_All['Release Date'] = MacOS_All['Most recentversion'].str.rsplit('(', 1).str[1]

# Remove the trailing ')' from the 'Release Date' column
MacOS_All['Release Date'] = MacOS_All['Release Date'].str.rstrip(')')

# Convert the 'Release Date' column to datetime format
MacOS_All['Release Date'] = pd.to_datetime(MacOS_All['Release Date'], errors='coerce')

# If you want to drop the original 'Most recentversion' column
MacOS_All = MacOS_All.drop('Most recentversion', axis=1)

sysPatchInfoDF =pd.DataFrame(
    {
        'Hostname':[],
        'DisplayName':[],
        'OS':[],
        'OS Patch Level':[],
        'UpToDate?':[],
        'Lastest Release':[],
        'systemID':[]
    }
)



# Matching the data with Version
for system in JCSystems:
    # Build a new DF for the systems and patching level
    outdated = True

    os = system['os'] +' '+system['version']
    # Compare the patch level with the latest for each OS
    # MacOS
    systemVerDetails = system['osVersionDetail']

    if system['osFamily'] == 'darwin':
        osPatchLv = systemVerDetails['revision']
        lastestMacOS = MacOS_All.loc[systemVerDetails['osName'] + ' '+systemVerDetails['major'] == MacOS_All['Version']].values[0][2]
        outdated = osPatchLv not in lastestMacOS
    # Linux - For Ubuntu ONLY
    elif system['os'] == 'Ubuntu':
        osPatchLv = systemVerDetails['revision']


    # Windows
    elif system['osFamily'] == 'windows':
        osPatchLv = systemVerDetails['patch'] + '.' + systemVerDetails['revision']
        latestVer = (Win11_CuVer.loc[Win11_CuVer['Version'] == systemVerDetails['releaseName']])['Latest build'].values[0]
        outdated = float(osPatchLv) != latestVer


    new_data = [
        system['hostname'], 
        system['displayName'], 
        os,
        osPatchLv,
        outdated, system['osVersionDetail'],
        system['id']
    ]
    new_series = pd.Series(new_data, index=sysPatchInfoDF.columns)
    sysPatchInfoDF = sysPatchInfoDF.append(new_series, ignore_index=True)