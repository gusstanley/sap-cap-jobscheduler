# SAP CAP with BTP Job Scheduler

This project describes how to integrate a CAP Application with SAP BTP Job Scheduler.

## Project layout:

File or Folder | Purpose
---------|----------
`db/` | domain models and data
`srv/` | service models and code restricted by jobscheduler role
`package.json` | project metadata and configuration
`mta.yaml` | mta structure including all service dependencies and bindings
`xs-security.json` | xsuaa scope/role definition for jobscheduler

## Necessary Entitlements:
- BTP Job Scheduler
- XSUAA
- HDB/HDI
- Cloud Foundry

## Job Scheduler Configuration

#### First we need to add the following dependencies to the mta.yaml file:
```yaml
resources:
  - name: sap-cap-jobscheduler-db
    type: com.sap.xs.hdi-container
    parameters:
      service: hana
      service-plan: hdi-shared

  - name: jobscheduler #Name of the Job Scheduler resource
    type: com.sap.xs.job-scheduler #The type needs to match this one
    parameters:
      service-plan: standard
      config:
        enable-xsuaa-support: true #XSUAA is necessary when working with authenticated services

  - name: sap-cap-jobscheduler-auth
    type: com.sap.xs.uaa #Make sure we use the correct xsuaa type for creating the service instance
    parameters:
      service-plan: application
      path: ./xs-security.json
      config:
        xsappname: sap-cap-jobscheduler-auth
        tenant-mode: dedicated
```
We also have to add the jobscheduler and the auth resource as a requirement for the service module:
```yaml
modules:
  - name: sap-cap-jobscheduler-srv
    ...
    ...
    requires:
      - name: sap-cap-jobscheduler-db
      - name: sap-cap-jobscheduler-auth
      - name: jobscheduler
```
#### Configuring xs-security.json
```json
{
  "xsappname": "$XSAPPNAME",
  "scopes": [
    {
      "name": "$XSAPPNAME.jobscheduler",
      "description": "jobscheduler scope",
      "grant-as-authority-to-apps": [
        "$XSSERVICENAME(jobscheduler)"
      ]
    }
  ],
  "attributes": [],
  "role-templates": [],
  "authorities-inheritance": false
}
```
Note that we need at least one scope defined for this process to work, even if you are not using the scope in the app.

#### Check if we have XSUAA configured as authentication mode in package.json
```json
{
    ...
    "cds": {
        "requires": {
            "db": "hana",
            "auth": "xsuaa"
        }
    }
}
```

#### Restricting Access
To restrict the access to a particular entity we can add the following annotation.
```cds
annotate RootService.Books with @(restrict: [{
    grant: 'READ',
    to   : 'jobscheduler'
}]);
```
This will force only the role jobscheduler to have access to the entity.
Note that the name needs to be the same as defined in the xs-security.json file.

#### Deployment
```sh
npm install
cf login
npx mbt build
cf deploy mta_archives/sap-cap-jobscheduler_1.0.0.mtar 
```

Thanks,

Gustavo Stanley