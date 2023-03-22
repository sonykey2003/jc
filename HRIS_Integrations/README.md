# Onboarding Users from CSV to JC
### When you only have CSV dumps from the HRIS

## Prerequisites
* A [JumpCloud tenant](https://jumpcloud.com/) - free for 10 users.
* A Google Drive account to host the CSV.
* A [Make.com](https://www.make.com/en) free account.


## How-to Steps

1. Feel free to use `OnboardingCSVSample.csv` as your HRIS CSV template. 
2. Upload the CSV to your Google Drive.
3. Download `csvOnboardingJC_MakeScenario.json` (exported scenario). 
4. Create a new `scenario` on Make.com -> "import Blueprint" -> navigate to the Json file you just downloaded -> save. 
5. At the first "Google Sheets" module, set it up by link your google drive account, and choose the csv file.
6. Go to `createUsersAttr` JSON module -> add (data structure) -> Generate -> use the sample data like below, click "generate".
7. Note: Highly recommended to generate a random password for the new users and rotate it regularly. 
```JSON
{
    "company": "string",
    "costCenter": "string",
    "department": "string",
    "email": "string",
    "employeeIdentifier": "string",
    "employeeType": "string",
    "firstname": "string",
    "jobTitle": "string",
    "lastname": "string",
    "location": "string",
    "password": "string"
}

```

8. Next, go to `createUsers` HTTP module -> add Credentials -> Name it, and input your JC API key in "Key" section. -> "API Key Placement" - In the header -> "API Key parameter name" - "X-API-Key" -> create.
9. Then, go to `bulkJobData` JSON module -> add (data structure) -> Generate -> use the sample data like below, click "generate".
```JSON

{
    "user_ids": ["{User_ID_1}", "{User_ID_2}", "{User_ID_3}"],
    "state": "ACTIVATED",
    "start_date": "2000-01-01T00:00:00.000Z"
}
```
10. Lastly, go to `scheduleOnboarding` HTTP module -> choose the credential you created in step 8. 

Done! Run the scenario and see how it goes!