import pprint
import json
import lacework
import time

import csv
pp = pprint.PrettyPrinter(indent=4)
people = []
not_added = []

file_name = "users.csv"

# list all the tenant you want each users added to
tenants_to_add_users_to = [
  {
    "tenant": "TENANT_NAME",
    "key_id": "TENANT_KEY_ID",
    "secret": "TEANT_SECRET"
  }
]

with open(file_name, newline='') as csvfile:
  lacework_people = csv.reader(csvfile, delimiter=',', quotechar='"')
  for row in lacework_people:
    people.append(row)

list_of_users = []

for p in people:
  user_name = p[3]
  # if "lacework.net" not in user_name:
  #   continue
  if "Last Name" == p[1]:
    continue
  user =   {
    "firstName": p[0],
    "lastName": p[1],
    "userName": user_name
  }
  list_of_users.append(user)

# get to token for each tenant
for tenant in tenants_to_add_users_to:
  token = lacework.get_lacework_token(tenant)
  tenant["token"] = token

# loop over all user and add them to each tenant
for tenant in tenants_to_add_users_to:
  for user in list_of_users:
    try:
      lacework.add_user(tenant["tenant"], tenant["token"], user)
    except Exception:
      fail = { "tenant": tenant["tenant"], "user": user["userName"] }
      not_added.append(fail)

    # sleep to ensure we don't hit the API rate limit :fingercrossed:
    time.sleep(10)

pp.pprint("These people were not added this run:")
pp.pprint(not_added)

