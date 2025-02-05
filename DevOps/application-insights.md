# Application Insights
## Overview
Azure Monitor Application Insights is a feature of Azure Monitor that allows applications to report their telemetry (logs, metrics & traces) and provides an excellent reporting and visualisation UI allowing administrators to investigate applications performance and diagnose any issues. It also supports dynamics querying by Azure Alert Rules, allowing alerts to be raised immediately whenever a serious issue is detected.

Applications can include code and configuration allowing it to send its telemetry to an instance of Application Insights. These are referred to as “instrumented" applications.

## Number of Instances
Ideally, all applications in the same environment would log to a single instance of Application Insights. That way, we get full, end-to-end traceability through all the applications. E.g. the application map would show which applications call which and the Transaction Search would be able to tie together all the API requests/database calls/etc. that were triggered because of some action/event. 

## Naming Convention
`{product}-{environment}-appi`

## Authentication

### Authentication Types
Application Insights currently supports two methods of authentication that users/applications must undergo before they are allowed to query data or send telemetry:

#### Entra Authentication
Users and managed identities can request an access token from the Entra ID tenant that the Application Insights instance is configured to trust. Entra will only issue such a token if the caller has an appropriate role over the target Application Insights resource (e.g. Monitoring Metrics Publisher). If successful, they caller must supply the returned access token in the authorisation header when making requests to Application Insights.

#### Local Authentication (recommend to disable)
Users and managed identities can authenticate to App Insights using an Instrumentation Key. This is a secret that must be shared with applications so that they can include it in any requests they make to Application Insights. It is recommended that Local authentication be disabled to force all clients to authenticate to Application Insights using Entra authentication.

If local authentication is left enabled and the instrumentation key was leaked, then attackers could:
1.	Query the telemetry to gain insight into the application code, allowing them to go on to craft more dangerous attacks.
2.	Send malicious telemetry to the Application Insights instance. This could be to:
•	cause legitimate telemetry to not be logged due to Application Insight's sampling percentage.
•	raise false alerts in the hope that the business gets accustomed to them and starts to ignore them.
•	cause a “Denial of Wallet” due to the ingestion cost of sending telemetry to Application Insights.

**Note:** When local authentication is disabled, the application insights instance still exposes an instrumentation key value, which is a required field in any Application Insights connection strings. However, with local authentication disabled, this instrumentation key is no longer used for authentication; it only used to verify that the caller is connecting to the correct Application Insights instance. As such, it no longer needs to be treated as a secret.

### App Service Auto-Instrumentation
Azure App Services can automatically log certain types of telemetry - like metrics, requests and dependencies - to an Application Insights resource without needing any code to be written. This telemetry is known as “auto-instrumentation” and it can be applied to many types of application even when you have no access to the underlying source code.

By default, auto-instrumentation, expects to be able to authenticate to Application Insights using the instrumentation key - meaning that Local Authentication would need to be enabled on the Application Insights instance. To force auto-instrumentation to use Entra Authentication, you need to add the following AppSetting to the App Service:

<table>
  <tr>
    <td style=font-weight:bold>Name</td>
    <td>APPLICATIONINSIGHTS_AUTHENTICATION_STRING</td>
  </tr>
  <tr>
    <td style=font-weight:bold>Value when using system-assigned managed identity</td>
    <td>Authorization=AAD</td>
  </tr>
  <tr>
    <td style=font-weight:bold>Value when using a user-assigned managed identity</td>
    <td>Authorization=AAD;ClientId={Client id of UMI}</td>
  </tr>
</table>

For more information, see https://learn.microsoft.com/en-us/azure/azure-monitor/app/azure-ad-authentication?tabs=aspnetcore#environment-variable-configuration.
