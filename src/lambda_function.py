import os
import requests

def lambda_handler(event, context):
    endpoint = "https://graph.microsoft.com/v1.0/users"

    response = requests.get(endpoint)

    if response.status_code == 200:
        users_data = response.json()
        users_list = users_data.get("value", [])

        print("\nListing all users in Azure AD:\n")
        for user in users_list:
            print(f"User Principal Name: {user.get('userPrincipalName')}, "
                  f"Display Name: {user.get('displayName')}")

        if "@odata.nextLink" in users_data:
            print("\nMore pages of users exist. Handle nextLink for additional pages.")
    else:
        print("\nFailed to retrieve users from Microsoft Graph.")
        print(f"HTTP Status Code: {response.status_code}")
        print(f"Response: {response.text}")
    return response.text