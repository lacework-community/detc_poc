import requests
import json

def get_lacework_token(data):
  tenant = data["tenant"]
  key_id = data["key_id"]
  secret = data["secret"]

  token_url = "https://{}.lacework.net/api/v1/access/tokens".format(tenant)
  token_headers = {
    "X-LW-UAKS": secret,
    "Content-Type": "application/json"
  }
  token_body = {
    "keyId": key_id,
    "expiryTime": 3600
  }

  resp = requests.post(url=token_url, json=token_body, headers=token_headers)
  try:
    data = resp.json()
  except JSONDecodeError:
    raise Exception("HTTP Request failed: {}".format(resp.reason))

  if resp.status_code > 299:
    raise Exception("Fetching token failed: {}".format(data["data"]["message"]))
  else:
    token = data['data'][0]['token']
    return token

def get_lacework_users(tenant, token):
  url = "https://{}.lacework.net/api/v2/TeamMembers".format(tenant)
  headers = {
    "Content-Type": "application/json",
    "Authorization": token
  }
  resp = requests.get(url=url, headers=headers)
  try:
    data = resp.json()
  except JSONDecodeError:
    raise Exception("HTTP Request failed: {}".format(resp.reason))

  if resp.status_code > 299:
    raise Exception("Fetching users failed: {}".format(data["data"]["message"]))
  else:
    data = resp.json()
    return data["data"]

def delete_lacework_user(tenant, token, user_record):
  email = user_record["userName"]
  users = get_lacework_users(tenant, token)
  user = next(user for user in users if user["userName"] == email)

  if user is None:
    raise Exception("Couldn't find user email: {}".format(email))

  url = "https://{}.lacework.net/api/v2/TeamMembers/{}".format(tenant, user["userGuid"])
  headers = {
    "Content-Type": "application/json",
    "Authorization": token
  }
  resp = requests.delete(url=url, headers=headers)
  if resp.status_code > 299:
    raise Exception("Deleting users failed: {}".format(data["data"]["message"]))
  else:
    print("User {} deleted from Lacework tenant {}".format(email, tenant))

def add_user(tenant, token, user):
  url = "https://{}.lacework.net/api/v2/TeamMembers".format(tenant)
  headers = {
    "Content-Type": "application/json",
    "Authorization": token
  }

  body = {
    "props": {
      "firstName": user["firstName"],
      "lastName": user["lastName"],
      "company": "Lacework",
      "accountAdmin": False
    },
    "userEnabled": 1,
    "userName": user["userName"]
  }

  print(url)
  print(json.dumps(body, indent = 4))

  resp = requests.post(url=url, json=body, headers=headers)
  if resp.status_code > 299:
    print(resp.json())
    raise Exception("Adding users failed: {}".format(resp.reason))
