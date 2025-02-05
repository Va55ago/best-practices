# Pipeline Variables
In terms of CI/CD pipelines, variables are non-secret values that can vary (hence the name) between different instances of the application being deployed. In most instances, these different instances are running in different environments and the variables are therefore often referred to generically as “environment variables” (this is despite this term clashing with the operating system concept of environment variables).

# Best Practice #1: Minimise variables
Ideally, you want to minimise the number of variables that need to be provided to each instance of the application during deployment.  This is because misconfigurations are one of the biggest causes of bugs and security incidents so reducing the the surface area for misconfigurations can greatly improve the security posture of the application whilst also minimising a whole class of possible bugs.

Strategies to avoid the need for configuration variables include:
- Never exposing variables for things that are don't vary
  If something is not expected to vary between environments, it should not be exposed as a variable in the pipeline.
- Following a “convention over configuration” approach.
  If your app needs to access a storage account - for example - then ensure that the storage accounts in each environment follow a predictable naming convention. Doing this allows the app can calculate the name that it expects in each environment rather than relying on a configuration value.
- Defining sensible defaults of configuration variables
  If a variable is not supplied, the default value should work for most environments. Doing this means that the default only need to be overridden for a few environments.
- Avoiding duplicating values across multiple variables.
  If, for some reason, you must have two different variables containing the same value, then set the value of one of them to reference the other.
 
## Best Practice #2: Use YAML variable templates
Even after you've minimised the number variables as much as possible, you will likely still have some configuration that must be supplied at deployment time. You have several options of where to store these environment variables
- In pipeline variables
- In a variable group referenced from the pipeline
- In a YAML variable template referenced from the pipeline.

The recommendation here is to use YAML variable templates. Doing this has several advantages over the other two approaches:

1. Idempotency
  Variables defined in YAML files are guaranteed to be fixed for the life of the pipeline run. This is because each run references a particular commit of the git repo, and commits are immutable. Should you ever need to re-run a stage/job of an older pipeline, you can be sure that the variable values used will be the same as when that stage/job was first executed.

  In contrast, variables defined in the pipeline itself, or in variables groups, are read at runtime. This means that, should they be changed between the first and second run of a stage/job, the second attempt will pick up the new values. This means there is no guarantee that running the same stage/job multiple times will always give the same outcome.

2. Maintainability
  Variables defined in YAML files are subject to all the power - and restrictions - of the git repos in which they are stored. This gives a plethora of advantages over variables stored in pipelines/variable groups:

  - You will be able to see a full history of each change to each variable, including who made the change, when and why.
  - You will be able to make changes to variables in a branch, without impacting other developers who may be using the pipeline.
  - You will be able to merge conflicting changes made by other developers.
  - Changes to variable values will have to go through the Pull Request process and be reviewed by other developers.

3. Improved variable precendence rules
  In classic pipelines, variables were scoped to either the whole pipeline (global) or to a stage. In YAML, you also have the option of overriding variables at the job scope.
 
  Also, with classic pipelines, if two variables with the same name are brought into the same scope, the order of precedence is undefined. For example, if a variable called “myVariable” was defined in a classic release stage variable, but a variable group also containing “myVariable” was linked to the same stage, then it is undefined which one the classic release pipeline would pick at runtime. With YAML pipelines, whichever variable is declared last in the YAML file is guaranteed to always take precedence.
 
4. Concurrent editing
  Variables stored in pipelines or variable groups lack any form of concurrency checking in place when multiple developers are changing them. I.e. two developers could open a variable group, make some changes and whoever presses the "Save" button last will overwrite the changes of the first developer. Storing variables in YAML templates in git repos completely avoids this possibility.

5. Complex variables
  Variables defined in YAML can have any type, including complex objects. In contrast, variables defined in the pipeline itself, or in linked variable groups, are always interpreted as strings.

# Best Practice #3: Don't treat all variables as secrets
Historically, some development teams have decided that all configuration variables should be treated as if they were secrets (encrypted or stored in a Key Vault etc). This decision often stems from a desire to reduce complexity in the code. I.e. if some variables are secret, then storing _all_ variables the same way means the code only needs one mechanism to access them. However, doing this can have serious detrimental impacts when it comes to the supportability of the application.

For example: When a problem occurs with a running application, it is often necessary for an operations team member to access the environment to diagnose the issue. They will request a temporary role over that environment, allowing them to view the application logs, metrics & configuration. However, if all the configuration values are stored as secrets, that team member will not - by default - be able to view any of the configuration values.
 
In the - hopefully rare - case that diagnosing an issue requires the ability to view a secret values, then the operations team member would be expected to request a further elevation of their role to access those secrets (which would usually require a secondary approval). However, if _all_ configuration variables are stored as secrets, then the operations team will nearly always need those elevated permissions. This would make make it impractical to have a reasonable segregation of responsibilities - wihch usually leads to the operations team member having more permissions than they strictly need.
