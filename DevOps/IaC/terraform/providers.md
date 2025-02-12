# Terraform Provider Versions

## Best Practice #1: Always use the same versions of all terraform providers when deploying a particular version of your application
When you run `terraform init`, terraform determines what providers you have referenced and evaluates any version constraints you have applied. Once it has determined the appropriate set. You really want the same versions of the same set of providers to be used every time you deploy a particular version of your application. Later versions of providers may contain bugs or breaking changes and you don't want to be finding out about them for the first time when deploying to your production environment.

To enable this, you want to ensure that you use the same terraform lock file in each of the CD stages of your pipeline. When you run `terraform init`, a `terraform.lock` file is generated containing details of the selected providers and versions. You want this lock file to be present every time you run `terraform init` in each stage of your pipeline. To do this:
- Run `terraform init` in the CI stage of your CI/CD pipeline and then publish the resultant lock file as a pipeline artefact.
- In each of the CD stages of your pipeline, download that pipeline artefact and store the lock file in your terraform configuration directory.

This, effectively, pins a particular version of your application to a particular set of terraform provider versions. Thus, when you run `terraform init` in each of your pipeline's CD stages, you will always be guaranteed to download the same versions of the same set of providers.

## Best Practice #2: Use the latest versions of all terraform providers for each new version of your application
Although you want to use the same versions of each provider throughout the life of a _single_ pipeline run, you also want to be utilising the latest versions of each provider for each _new_ pipeline run. Newer providers also come with enhanced features and bug fixes so, unless there is a known bug or breaking change in a later version, you always want to be testing the deployment of each version of your application using the latest versions of each of provider that was available at the time.

To achieve this, simply avoid specifying any specific provider versions in your `providers.tf` file. This way, terraform will naturally select the latest version of each provider when the CI stage of your pipeline runs `terraform init`. It will then continue to use those versions for the lifetime of that pipeline run, as per Best Practice #1 above.