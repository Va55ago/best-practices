# Azure DevOps Pipeline Secrets

## Best Practice #1: Do not store secrets in git repos
Secrets should never be stored in plain-text outside of a secure vault (e.g. Azure Key Vault or Hashicorp Vault). Committing them to a git repo means that anyone with access to that git repo - either now or in the future - will be able to retrieve that secret and, potentially, misuse it. Even deleting the secret from the repo is not enough as it will still remain in the history.

Any secret that is ever committed to a git repo should be treated in the same was as if it was leaked to an attacker: I.e. the secret should be rotated and all references to it should be updated.

For the avoidance of doubt: Even encrypted secrets should not be stored in git repos. Again, this is because git commits are immutable and will always remain in the history so, should the encryption key ever be leaked in future, an attacker would be able to decrypt any secret that was ever added to that git repo.

## Best Practice #2: Enable Push Protection
To ensure that you can't inadvertently commit a secret to a git repo, you can enable `GitHub Advanced Security for Azure Devops` on your repo and ensure that the Push Protection feature is enabled. This will ensure that any a commit that is pushed to Azure DevOps will be rejected if Azure Devops believes it contains something that could be a secret.

Not only that, but Azure DevOps will periodically scan the entire history of your repo to determine if any secrets were ever 
Secrets cannot be stored in plain text in a git repo. Even storing them in an encrypted form would be problematic as anyone could go back through the git history to look at historical versions of the ciphertext. Therefore, you would need to maintain tight control of the decryption keys indefinitely, which is infeasible (you should assume that, eventually, all keys will be stolen, leaked or cracked). As such, secret values must not be stored in the git repo, even in encrypted form.
 
## Best Practice #3: Minimise Secrets
Similarly to the guidance for variables, you should minimise the number of secrets that you need to provide to your application at deployment time. Strategies to avoid this include (in order of preference):
 
-	Updating the application to not require a secret at all
  E.g. The application could be updated to use its managed identity when accessing a storage account, instead of a secret SAS token.
 
- Storing the secrets in a secure vault and having the application read them at runtime.
  E.g. The application's managed identity could be given permission to read the secret from Key Vault and the code could be updated to read this in at startup. This also has the advantage that the code could observe any changes made to it and start using new versions at runtime without any redeployment.

## Best Practice #4: Use Key-Vault Linked Variable Groups
If the application code cannot be changed and the secret must be supplied at deployment time, then the pipeline will need some way of retrieving that secret from a secure location. The three supported ways of doing this (in order of preference) are:
 
- A key-vault linked variable groups
  - Store the secrets in a key vault
  - Grant access to that secret to an Azure DevOps Service Connection.
  - Create an Azure DevOps Variable Group that is linked to that Key Vault and authenticates using the Service Connection from above.
  - Update the pipeline to link to this variable group from the appropriate scope.
- Encrypted variable group variables
  - Create a variable group
  - Add the secrets directly to the variable group but ensure that you click the “lock” icon to encrypt the variable.
  - Update the pipeline to link to this variable group from the appropriate scope.
- Encrypted pipeline variables
  - Create the pipeline
  - Click “Edit” to bring up the pipeline UI
  - Click “Variables” to bring up the variables editor
  - Add variables, ensuring that you check the “Keep this value secret” box to encrypt the value.
 
Unfortunately, secrets stored directly within the pipeline are always at the global pipeline scope, meaning they are available to all stages and jobs in the pipeline. This is the reason that Variable Groups are preferred in this instance.
