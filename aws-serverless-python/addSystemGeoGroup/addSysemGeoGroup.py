import jcapiv1,jcapiv2,requests,json,datetime,os

from jcapiv1.rest import ApiException
from jcapiv2.rest import ApiException

from datetime import datetime
from datetime import timedelta

apiKey = os.environ['jc_api_key']

backTrackDays = 1 # Recommended interval

# Setting V1 api config
config_V1 = jcapiv1.Configuration()
config_V1.api_key['x-api-key'] = apiKey

# Setting V2 api config
config_V2 = jcapiv2.Configuration()
config_V2.api_key['x-api-key'] = apiKey

# Getting the API instances ready
jcSystemApiInstance = jcapiv1.SystemsApi(jcapiv1.ApiClient(config_V1))
jcSysGroupApiInstance = jcapiv2.SystemGroupsApi(jcapiv2.ApiClient(config_V2))

def getGeoFromIP(IP):
    url = "http://ip-api.com/json/" + IP
    r = requests.get(url)
    return r.json()


def anchorDate (backTrackDays):
    # Using UTC by default
    now = datetime.utcnow()
    backDate = datetime.date(now - timedelta(days=backTrackDays))
    return backDate

# Search if any new systems created since the backTrackDays

backDate = anchorDate(backTrackDays)
systemFilter = f"created:$gt:{backDate}"
jcSystems = jcSystemApiInstance.systems_list(filter=systemFilter).to_dict()['results']

# Add the new systems to the geo orientated group according to remote IP
if [] != jcSystems:

    for system in jcSystems:
        
        geoLocale = getGeoFromIP(system['remote_ip'])
        sysGroupName = geoLocale['country'] + "_" + system['os_family']

        # Check if the sys group exists
        filter = [f"name:eq:{sysGroupName}"]
        jcSysGroup = jcSysGroupApiInstance.groups_system_list(filter=filter)

        addSysGroupMemberBody = {
            'op':'add',
            'type':'system',
            'id':system['id']
        }

        # If the sys group is not created:
        # Add the system to the group
        if [] == jcSysGroup:
            ## Create the group
            try:
                createSysGroupBody = {'name':sysGroupName}
                newGroup = jcSysGroupApiInstance.groups_system_post(body=createSysGroupBody)
                print(f"Sys Group {newGroup.name} created!")
            except ApiException as error:
                print(f"Error: {error}")

            ## Add the system to the group
            try:
               
                addSysGroupMember = jcSysGroupApiInstance.graph_system_group_members_post(group_id=newGroup.id,body=addSysGroupMemberBody)
                print(f"System {system['hostname']} added to group {newGroup.name}!")
            except ApiException as error:
                print(f"Error: {error}")
            
        else:
            try:
                jcsysGroupMember = jcSysGroupApiInstance.graph_system_group_members_post(group_id=jcSysGroup[0].id,body=addSysGroupMemberBody)
                print(f"System {system['hostname']} added to group {jcSysGroup[0].name}!")
            except ApiException as error:
                print(f"System {system['hostname']} Already Exists in {jcSysGroup[0].name} group!")            

else:
    print(f"Phew! No systems has been create for the past {backTrackDays} days, take a day off!")


    