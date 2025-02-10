# Pipeline Architecture
## Executive Summary
- Every CI/CD pipeline is expected to build and deploy a single "product".
- The top-level pipeline defines to which environments the product is deployed and brings into scope any environment variables.
- The product deployment template defines how the product is deployed to any given environment.
- Each run of the CI/CD pipelines defines a new version of the product

## Definition of a product
A product is an independent unit of software that provides some value in-and-of-itself. Each product is independently deployable and should have its own product owner, its own development team and its own backlog of work to build, support and maintain it.

From a technical perspective, the product is the "unit of deployment". It may consist of multiple sub-components, but any change to any sub-component will cause a new version of the whole product to be created and deployed.

Some woiuld argue that every sub-component should be its own, independently deployable product. This approach is often termed as a "Microservice" architecture; one of the goals of which is to break large, "monolithic" products down into small, independently deployable services. There are many advantages to this approach but it also has some fairly high associated costs! Not only would each independent product require its own product backlog, product owner & product team, but a Microservice architecture also mandates that all changes to any microservices must always be made in a back-compatiable fashion, which can often be very challenging. For very large teams, the benefits of Microservices can still outweigh those costs. However, the benefits of a full microservice architecture should always be weighed against its additional complexity.

It is the responsibility of the architect to decide which applications, APIs and services are tightly coupled enough that they can be considered as components of a single, deployable product.  Whilst this decision can be somewhat subjective, it must be agreed and documented in a Product Architecture diagram. This would show the high level, independently deployable products and the dependencies between them.

## Product Repository & CUI/CD Pipeline
By definition, the component parts of a products are so tightly coupled with each other that changes to one often necessitate changes to the other. To take an example, imagine an API that reads from a database. The API code expects the database to have a certain tables and columns etc, and should the database schema ever change, then the application code would likely need to be changed with it. I.e. the API and the database are tightly coupled, so you would want every new version of the product to contain any corresponding changes to both.

To enable this, we need to ensure that all changes to tightly coupled components are:

1. Merged to the main branch as a single, atomic operation.
   This is so that that developers cannot pull a new version of one component without also getting the new version of the other.

2. Deployed together, as a unit, through the environments.
   This is to ensure that it's not possible to deploy the new version of one component without also deploying the new version of the other.

The first requirement mandates that the code for both components lives in the same repository. This ensures that changes to both components can be merged to the `main` branch via a single Pull Request. The second requirement mandates that both components are built, versioned & deployed via a single CI/CD pipeline.

You can extend this argument to all other components of the product: Azure resources, APIM policies, Azure App Registrations, role assignments, etc. Ultimately, this leads to the code for _all_ components being in a single product repo and being built, versioned and deployed by a single CI/CD pipeline.

## Product versioning
The version number scheme chosen for any given product is, technically, the responsibility of the product team. The only business requirements are that:
- Every change that is merged to main must create a new, unique version number.
- The sequence of version numbers must be obvious (i.e. which versions followed which).

Despite this flexibility, it is highly recommended that all product teams follow the principals of semantic versioning (see https://semver.org/). I.e.:

> Given a version number [in the format] `MAJOR.MINOR.PATCH`:
> - Increment the `MAJOR` version when you make large and/or breaking changes to the product.
> - Increment the `MINOR` version when you add functionality to the product in a backward compatible manner.
> - Increment the `PATCH` version when you make backward compatible changes that do not introduce any new features (e.g. bug fixes).

Where to store this version number and how it is incremented are implementation details that are left to the product teams to define. However, to provide an example: You could store the parts of the version number in global pipeline variables as such:

```YAML
variables:
  - name: version.major
    value: 0
  - name: version.minor
    value: 1
  - name: version.build
    value: $[counter(format('{0}.{1}', variables['version.major'], variables['version.minor']), 0)]
```

As you can see, the major and minor version numbers are intended to be managed by hand by the product development team in accordance with the rules of semantic versioning. In contrast, the patch/build number is auto-incremented by the pipeline every time it is run unless one - or both - of the major/minor version numbers has changed, in which case it is reset to zero.

> Note: You could have more advanced logic for the `version.build` variable to distinguish between "releasable" and "non-releasable" versions. E.g. A team might want a simple version number like the above when the pipeline is running against the `main` branch and, thus, creating a releasable artefact. If it's running against a feature branch, that artefact should not be able to be deployed all the way to production, so you might want to include a tag on the end - e.g. `1.2.0-pr_{pull_request_id}_{commit_id}`.

The version number is expected to be included in the name of each pipeline run, making is simple to identify which version of the product is currently deployed to each environment simply by looking at the latest pipeline run that executed the appropriate pipeline stage.

## YAML pipelines
Use YAML pipelines instead of classic build and release pipelines.

Whilst classic build and release pipelines are not officially deprecated, it is clear that Microsoft is no longer investing in them. Not only this, but YAML pipelines now have several key functional & security advantages over classic build and release pipelines.

For more information, see Classic vs YAML Pipelines.

## YAML templates
YAML templates are standalone pieces of YAML code that can be reused across one or more YAML pipelines. For those with a development background, you can think of them as akin to "methods" in programming languages. For more information, see Classic-vs-YAML-Pipelines - Reusable Templates.

Whether or not to use YAML templates is, technically, an implementation decision by the product team. However, they are highly recommended for the following use cases (at least!):

### Product deployment template
This defines the steps to deploy the product into any given environment. By defining this once, not only are you avoiding code duplication, but you also guarantee that the same deployment steps will be used in every environment (for a given version of the product). This was not something that could be guaranteed in classic release pipelines (where each stage was "cloned" from a previous stage at some point in the past).

Once the template is defined, you simply reference it in each stage of the main pipeline, passing in the name of the environment and the path(s) to the appropriate environment variables template(s) for that environment.

### Component deployment template(s)
These define the steps to deploy a type of component into any given environment. Defining this once means you can reuse the template for any other components of the same type within your product.

For example, the DAL product deploys multiple APIs into Azure App Services. Each API is a separate component of the DAL product and they are all deployed in the same way. Therefore, the product deployment template simply calls an "API Deployment Template" once for each API being deployed (passing the appropriate parameters each time).

### Variable template(s)
These define the values of variables for each environment to be passed to the deployment templates for each environment. They will be referenced from the variables section of each stage and/or job in the main pipeline.

## Variables and secrets
Minimise the number of variables and secrets that your pipeline needs to utilise at deployment time. Where this isn't possible:
•	Variables should be stored in variable YAML templates that are linked from the appropriate pipeline scope.
•	Secrets should be stored encrypted within variable groups (ideally, variable groups that are linked to a key vault containing the secrets).

For more information, see Pipeline Variables and Secrets.

## Environments
Create one [Azure DevOps Environment](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops) for each logical environment that your product pipeline will target. In general, it is expected that you would have "DEV", "SIT", "UAT", "MO", "PPE", "PROD" & "TRAINING", but some products may have more (e.g. DAL and Case Management will also deploy to a "Data Migration DEV" environment.

Every deployment job in your product pipeline must target one of these Azure DevOps Environments and will be subject to the gates and checks defined on it. For more information, see Classic vs YAML Pipelines - Azure DevOps Environments.

## Jobs
In the vast majority of cases, your pipeline is expected to use traditional jobs when building and testing your product and it to use deployment jobs when deploying your product. This will ensure that any changes made to an environment are subject to the gates and checks of the appropriate Azure DevOps Environment.

For more information about the different types of jobs available and when you should use each, see Classic vs YAML Pipelines - Jobs.

## Agent pools
When running a traditional job, a deployment job or a container job, the tasks in that job must be executed by an agent that has network visibility of all the resources with which it will be interacting. Agents are grouped into "pools" of agents that have similar capabilities and/or costs. Each deployment job must specify the agent pool that must be used to execute the job tasks in that job.

In some cases, the tasks in the job will only be interacting with public facing resources (e.g. the Azure ARM API). In those cases, you may make use of the Microsoft Hosted agent pool. However, in most cases, your pipeline will need to interact with private resources (e.g. an App Service that can only be reacheed via a Private Endpoint). In those cases, you must be sure to select the appropriate agent pool for the target environment.

Details of which agent pool to use for each environment can be in the list of build agent pools.

## Smoke tests
Whenever a service is deployed into any target environment (including - and especially - the production environment), the pipeline should execute a "smoke test" to ensure that the service is healthy before concluding that the deployment was successful.

> Note: This smoke test is not testing whether the service is functionally correct (i.e. free of bugs etc.). That is the responsibility of the automated testing jobs that should come later. The smoke test in the deployment job is simply ensuring that the application was deployed successfully and is available to service requests.

Ideally, the service would expose a health check endpoint that can be called by the pipeline (see [Health checks in ASP.NET Core](https://learn.microsoft.com/en-us/aspnet/core/host-and-deploy/health-checks?view=aspnetcore-8.0)). However, you must make sure that such a health check endpoint either requires no authentication, or that the pipeline identity has sufficient permissions to call it.

## Service Connections
It is very common for some tasks to need to authenticate to a target service in order to run. For example, a task to deploy an ARM template must authenticate with the ARM API. Every such task must select a service connection that has the minimum permissions needed for that task to complete successfully.

## Code Vulnerability Scanning
Any code written must be scanned for security vulnerabilities before it is deployed into any environment. To support this, Microsoft created [GitHub Advanced Security for Azure DevOps](https://learn.microsoft.com/en-us/azure/devops/repos/security/configure-github-advanced-security-features?view=azure-devops&tabs=yaml), which can be activated on any git repo hosted in Azure DevOps. Doing this then provides some additional tasks that can be used in pipelines, one of which is for vulnerability scanning.

For more information, see Code Vulnerability Scanning