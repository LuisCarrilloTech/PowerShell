import requests
import json

# Prompt the user for UAG details
UAG_IP_or_FQDN = input("Enter your UAG IP or FQDN: ")
UAG_USERNAME = input("Enter your UAG username: ")
UAG_PASSWORD = input("Enter your UAG password: ")

# Ignore SSL warnings if the UAG uses a self-signed certificate
requests.packages.urllib3.disable_warnings(requests.packages.urllib3.exceptions.InsecureRequestWarning)

# Construct the URLs for API endpoints
login_url = f'https://{UAG_IP_or_FQDN}:9443/rest/v1/sessions'
connections_url = f'https://{UAG_IP_or_FQDN}:9443/rest/v1/monitor/userconnections'

# Authenticate and obtain the session token
login_data = {
    'username': UAG_USERNAME,
    'password': UAG_PASSWORD
}

response = requests.post(login_url, json=login_data, verify=False)
if response.status_code != 200:
    print("Error: Failed to authenticate.")
    exit(1)

session_token = response.json()['sessionToken']

# Get user connections using the session token
headers = {
    'Authorization': f'Bearer {session_token}'
}

response = requests.get(connections_url, headers=headers, verify=False)
if response.status_code != 200:
    print("Error: Failed to fetch user connections.")
    exit(1)

# Parse and print user connections
connections = response.json()
print(json.dumps(connections, indent=2))
