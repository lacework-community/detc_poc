# Add user to a Lacework Tenant

This Python script can be used to add users to a Lace work Tenant.

## Install Lacework python lib

    pip3 install laceworksdk

## CSV File

The CSV file format is the same as the exported users from a Lacework Tenant.

## Run the script

Edit the 'users.py' file to add the name/key id/secret for the tenants that you want to add your users for.

    tenants_to_add_users_to = [
      {
        "tenant": "TENANT_NAME",
        "key_id": "TENANT_KEY_ID",
        "secret": "TEANT_SECRET"
      }
    ]


Run the script:

    python users.py

The script will output all the user that were not added to each tenant.