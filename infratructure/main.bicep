param location string = resourceGroup().location
param appNamePrefix string = 'avscan'
param containerExposedPort int = 3310
param logAnalyticsWorkspaceId string = ''
@secure()
param logAnalyticsSharedKey string = ''

var environmentName = '${appNamePrefix}-caenv-${location}-${uniqueString(resourceGroup().id)}'
var containerAppName = '${appNamePrefix}-capp-${location}-${uniqueString(resourceGroup().id)}'
var vnetName = '${appNamePrefix}-vnet-${location}-${uniqueString(resourceGroup().id)}'
var subnetName = 'capp-subnet'
var nsgName = '${subnetName}-nsg'

var cpu = json('1.5')
var memory = '3Gi'

var appLogsConfiguration = {
  destination: 'log-analytics'
  logAnalyticsConfiguration: {
    customerId: logAnalyticsWorkspaceId
    sharedKey: logAnalyticsSharedKey
  }
}

resource nsg 'Microsoft.Network/networkSecurityGroups@2022-07-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'allow-3310-inbound'
        properties: {
          access: 'Allow'
          direction: 'Inbound'
          protocol: 'Tcp'
          destinationAddressPrefix: '*'
          destinationPortRange: string(containerExposedPort)
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          priority: 100
          description: 'Allow inbound access to the exposed container port.'
        }
      }
    ]
  }
}

resource vnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '172.16.0.0/16'
      ]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: '172.16.0.0/23'
          networkSecurityGroup: {
            id: nsg.id
          }
        }
      }
    ]
  }
}

resource containerAppEnvironment 'Microsoft.App/managedEnvironments@2022-06-01-preview' = {
  name: environmentName
  location: location
  sku: {
    name: 'Consumption'
  }
  properties: {
    appLogsConfiguration: (logAnalyticsWorkspaceId == null || logAnalyticsWorkspaceId == '') ? null : appLogsConfiguration
    zoneRedundant: true
    vnetConfiguration: {
      internal: false
      outboundSettings: {
        outBoundType: 'LoadBalancer'
      }
      infrastructureSubnetId: vnet.properties.subnets[0].id
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2022-06-01-preview' = {
  name: containerAppName
  location: location
  properties: {
    environmentId: containerAppEnvironment.id
    managedEnvironmentId: containerAppEnvironment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        transport: 'tcp'
        targetPort: 3310
        exposedPort: containerExposedPort
        traffic: [
          {
            latestRevision: true
            weight: 100
          }
        ]
      }
    }
    template: {
      containers: [
        {
          image: 'docker.io/clamav/clamav:latest'
          name: 'clamav'
          resources: {
            cpu: cpu
            memory: memory
          }
        }
      ]
      scale: {
        maxReplicas: 1
        minReplicas: 0
      }
    }
  }
}

output fqdn string = containerApp.properties.configuration.ingress.fqdn
