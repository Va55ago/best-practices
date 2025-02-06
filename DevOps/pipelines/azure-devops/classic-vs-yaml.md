# Classic vs YAML Pipelines

## Overview
Whilst classic build and release pipelines are not officially deprecated, it is clear that Microsoft is no longer investing in them. Not only have they been labelled "classic", but Microsoft have also provided a [guide](https://learn.microsoft.com/en-us/azure/devops/pipelines/migrate/from-classic-pipelines) for migrating to YAML pipelines… and have even provided the ability to [disable the creation of new classic pipelines](https://devblogs.microsoft.com/devops/disable-creation-of-classic-pipelines/). In addition, YAML pipelines now offer several key functional & security advantages over classic build and release pipelines.

It is clear then that classic pipelines will not be supported indefinitely and users of Azure DevOps Services are expected to move towards YAML for their CI/CD pipelines in future.

## Source controlled code
This is a huge improvement over classic pipelines, where making any changes to the pipeline could take out the whole CI/CD process for as long as it took to complete the work. With YAML pipelines, changes can be made in branches and merged to main using a standard PR process. Not only this, but all changes are subject to full git version control, making it simple to see who made what changes and why, and to compare historical versions of the pipeline and revert changes if necessary.

## Human readable code
Classic pipelines were stored in an XML format that was very difficult for humans to read and understand. We were only ever expected to interact with the pipelines via the "click-and-drag" user interface. This made it difficult to understand what had changed between historical versions of the pipelines.

## Pipeline parameters
YAML pipelines support the concept of pipeline parameters that can be set when a run is triggered. The closest equivalent for classic pipelines was variables that were marked as "set at queue time", but the user interface for setting this was not nearly as seamless as for YAML pipeline parameters.

## YAML templates
YAML pipelines allow the creation of re-usable templates containing stages/jobs/steps that can be referenced multiple times from one or more pipelines). For those with a development background, you can think of YAML templates as akin to "methods" in programming languages.

Whilst classic pipelines attempted to support this use case with Task Groups, they were not as flexible nor fully featured as YAML templates, nor were they  YAML templates can include any type of re-usable code - not just tasks.

Utilising templates allows for two, valuable strategies to be adopted:
1.	Separate "where to deploy" from "how to deploy"
With YAML pipelines, you will often find that each stage of the top-level pipeline file simply calls a template that defines how to deploy the product. The top-level pipeline therefore knows the environments to which the product should be deployed, the order through which those environments should be deployed and the values of any variables for those environment. In contrast, the deployment template itself knows nothing about any environment other than what it is told via its parameters. It is simply a set of steps that need to run in order to deploy the product to any environment.

This allows for a clear separation of responsibilities. For example, all developers on the team may be permitted to update the deployment steps as they make changes to the application, whereas only a lead developer or DevOps engineer may be permitted to update the list of environments through which the product will be deployed.

2.	Store environment variables in the git repo
In classic pipelines, environment variables were stored against the pipeline and/or in variable groups. Not only did this make it difficult to track the history of environment variables, it also had the downside of making pipeline runs non-idempotent. If a stage was run and then rerun after a variable had been updated, the second attempt would pick up the new variable value, thus potentially behaving differently each time it is rerun.

By storing variables in YAML templates in the git repo then, not only do you gain the full power of git version control, but the environment variable values are effectively frozen at the point that the pipeline run is created. No matter how many times you rerun a stage, you are guaranteed to be using the same environment variable values.

Ideally, YAML templates should not rely on anything external to the template. E.g. it should not assume that the calling pipeline has brought into scope any variables, nor that it has created any specific files on the filesystem etc. In practice, this means that templates should rely only on information passed to it in the parameters that it exposes. The only exception to this rule is that pre-defined variables can be used in templates as they are known to be available in all contexts.

Note: There are actually two different types of YAML templates available: "includes" and "extends" templates. However, for the BST project, we will only really be concerned with the "includes" type. For a deep dive into how to create and use both types of templates, see https://learn.microsoft.com/en-us/azure/devops/pipelines/process/templates.

## Shared Environments
Azure DevOps natively supports the concept of an [Environment](https://learn.microsoft.com/en-us/azure/devops/pipelines/process/environments?view=azure-devops). Each Azure DevOps Environment represents a possible target of deployments from one or more YAML pipelines. Typically the Azure DevOps Environment would be named after the logical environment in which the resources and code will be deployed (e.g. "dev", "test", "staging", "production")… but they don't necessarily have to be.

Approvals and gates are configured on the Environment and not the pipeline itself (as they were in classic Release pipelines). Since Azure DevOps Environments exist independently of pipelines, they can be targeted by jobs from multiple pipelines and therefore provide a central place where approvals (and other gates) can be configured. This avoids the duplication of these policies that was inherent in classic Release pipelines.

  For example, let's say that a particular person (or group) should approve all deployments to particular environment regardless of which pipeline is doing that deployment. This policy can now be configured as an approval gate on the Environment itself instead of being configured separately on each individual pipeline.

In addition, pipelines must be granted permission to target each environment to which they want to deploy. This prevents a malicious developer from creating a new pipeline to execute arbitrary code against any environment. Instead, any malicious pipeline they created would first have to be granted permission to target the existing environment(s).

Finally, Azure DevOps Environments also allow you to view a complete history of all changes to each environment, regardless of which pipelines did the actual deployments.

## Jobs
Any given stage in a YAML pipeline contains one or more jobs that are each executed by an Azure Pipelines agent.

One advantage of YAML pipelines is that you can explicitly define which jobs are dependent on which other jobs. This allows certain jobs to run in parallel as long as all their dependent jobs have completed successfully (and you have enough free Agents to do so). Jobs in classic release pipelines would always run sequentially.

Jobs in YAML pipelines fall into one of the three categories listed below. It is important to use the correct type of job for each set of tasks being carried out.

### Agent Jobs
Each job of this type will be executed by an application known as an Azure Pipelines agent, which is installed on a number of Virtual Machines that are collectively referred to as an "Agent Pool".

Agent jobs can be split into two sub-types

#### Traditional Jobs
Traditional jobs do not make changes to any environment. As such, they can carry out no deployments to any environment. Examples of such jobs might be those involved in the CI stage of a pipeline. These jobs could contain steps that simply compile the code and run any unit tests, without deploying anything to any environment.

#### Deployment Jobs
A deployment job contains steps that are intended to make changes to an environment. Such changes could be related to the infrastructure (cloud resources), code, databases, permissions, etc. Regardless of the type of change, the fact that some change is being made to the environment constitutes a deployment.

For this reason, it is mandatory to specify an Azure DevOps Environment when declaring a deployment job. This causes deployment jobs to become subject to the security gates and policies assigned to that Environment. In addition, any deployment jobs that execute will be shown as deployments against that environment.

### Server Jobs
These are jobs that are executed on the server hosting Azure DevOps (i.e. not by an Agent). Server jobs are limited to being able to execute only a few task types. One of the most common examples is a server job that executes a "Wait for User Intervention" task. This might be to allow a user to manually review a generated plan of work before the pipeline continues.

### Container Jobs
Container jobs run within a container on an agent. They primarily exist to allow pipelines to utilise specific versions of tools that may conflict with one another if they were to be directly installed on the agent itself.

## Deployment strategies
In some cases, it is not desireable to simple overwrite the existing version of the application on all instances hosting it at once. Instead, you may want to gradually roll out changes, updating small groups of instances at a time. Or, alternatively, you want to deploy a brand new instance of your app side-by-side with the old one and then slowly route traffic to the newer version. These are known as deployment strategies.

In classic release pipelines, you would have had to program all of this logic into the pipeliens yourself. In contrast, YAML pipelines support a variety of different strategies out-of-the-box. Every deployment job in a YAML pipeline must specify which strategy should be used to perform that deployment.

## Pipeline Security
YAML pipelines can be assigned individual permissions to access "securable resources". These include:
- Service Connections
- Environments
- Agent Pools
- Variable Groups
- Secure Files

If a YAML pipeline attempts to utilise a securable resource that it has never used before, the run will halt until an administrator authorises the pipeline to use that resource. This provides security against an internal attack vector whereby a developer could create a new pipeline to perform a nefarious task without any oversight (e.g. Call a public API that they've written, pass it all the secrets stored in a variable group).
