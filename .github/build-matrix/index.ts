import { getInput, setFailed } from '@actions/core';
import { createHash } from 'crypto';
import * as fs from "fs";
import { load, YAMLException } from "js-yaml";

interface Account {
  secret: string
  account_name?: string
}

interface MatrixDetails {
  accounts: Record<string, Account>
  images: Record<string, string>
}

try {
  const details = getInput('matrix_details', { required: true });
  const data = load(details) as MatrixDetails

  const imgStrings: string[] = []
  Object.keys(data.images).forEach(i => {
    imgStrings.push(`${i}:${data.images[i]}`)
  })

  const accountNames: string[] = []
  Object.keys(data.accounts).forEach(a => {
    accountNames.push(createHash('md5').update(a).digest("hex"))
  })

  const retData = {images: imgStrings, accounts: accountNames}
  fs.writeFileSync('account_data.json', JSON.stringify(retData))
} catch (error) {
  if (error instanceof YAMLException) {
    // js-yaml can leak secrets in errors, catching specifically here
    setFailed("Failed to parse YAML")
  } else {
    setFailed(error.message)
  }
}
