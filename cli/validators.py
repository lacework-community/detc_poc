################
# VALIDATORS
################
import os.path

def validate_path_exists(dir_path):
  valid = os.path.isdir(dir_path)
  if valid == True:
    return True
  else:
    raise Exception("Path '{}' does NOT exist!".format(dir_path))

def validate_file_exists(file_path):
  valid = os.path.isfile(file_path)
  if valid == True:
    return True
  else:
    raise Exception("File '{}' does NOT exist!".format(file_path))


# def validate_terraform_commands(action):
#   valid = action in ["plan", "apply", "destroy"]
#   if valid == True:
#     return True
#   else:
#     raise Exception("Terraform action '{}' is NOT valid!".format(action))
