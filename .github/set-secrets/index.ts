import {getInput, setFailed, setOutput, setSecret} from '@actions/core';
import {createHash} from 'crypto';
import {load, YAMLException} from "js-yaml";

interface Account {
  secret: string
  account_name?: string
}

interface MatrixDetails {
  accounts: Record<string, Account>
  images: Record<string, string>
}

try {
  const data = load(getInput("matrix_details", {required: true})) as MatrixDetails
  const image: string[] = process.env.IMAGE.split(":")
  const account: string = process.env.ACCOUNT

  var accountDetail: Account
  Object.keys(data.accounts).forEach(a => {
    const nameMd5 = createHash('md5').update(a).digest("hex")
    if (nameMd5 == account) {
      const tmpAccount = data.accounts[a]
      if (tmpAccount.account_name == undefined) {
        tmpAccount.account_name = a
      }
      accountDetail = tmpAccount
    }
  })

  // Set secrets for the values used so they are masked in the logs
  setSecret(accountDetail.account_name)
  setSecret(accountDetail.secret)

  setOutput("account", accountDetail.account_name)
  setOutput("access_token", accountDetail.secret)
  setOutput("image", image[0]);
  setOutput("image_tag", image[1]);
} catch (error) {
  if (error instanceof YAMLException) {
    // js-yaml can leak secrets in errors, catching specifically here
    setFailed("Failed to parse YAML")
  } else {
    setFailed(error.message)
  }
}

