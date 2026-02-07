
@description('Server Name. (will be used as the DNS Label and in-game server name)')
param serverName string=''

@description('CPUs for the server')
param numberCpuCores int = 2

@description('Memory available to the server in GB')
param memory int = 4

@description('Whitelist of players - format: username1:XUID1,username2:XUID2')
param allowListUsers string = ''

@description('OPS - Operators XUIDs (use , to separate them)')
param ops string = ''

@description('MEMBERS - Members XUIDs (use , to separate them)')
param members string = ''

@description('VISITORS - Visitors XUIDs (use , to separate them)')
param visitors string = ''

@description('Object ID of the user/service principal that will have access to Key Vault')
param keyVaultAccessObjectId string = ''

@description('Accept Minecraft server EULA? (true/false)')
param eula string = 'true'

@description('Max number of players')
param maxPlayers int = 10

@description('Allow cheats in the server (true/false)')
param allowCheats string = 'false'

@description('Minecraft Bedrock version to run (LATEST, PREVIEW, or specific version)')
param version string = 'LATEST'

@description('Game mode: survival, creative, adventure')
param gamemode string = 'survival'

@description('Difficulty: peaceful, easy, normal, hard')
param difficulty string = 'normal'

@description('Level name (world name)')
param levelName string = 'Bedrock level'

@description('Level seed (leave empty for random)')
param levelSeed string = ''

@description('View distance')
param viewDistance int = 10

@description('Tick distance')
param tickDistance int = 4

@description('Enable online mode - Xbox Live authentication (true/false)')
param onlineMode string = 'true'

@description('Enable allow list - whitelist (true/false)')
param allowList string = 'false'

var fileShareName  = 'minecraftdata'
var storageAccountType  = 'Standard_LRS'
var location = resourceGroup().location
var storageAccountName = '${serverName}storage'
var keyVaultName = '${serverName}-kv'
var tenantId = tenant().tenantId


resource storageAccount 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: storageAccountType
  }
  kind: 'StorageV2'
}

resource storageShare 'Microsoft.Storage/storageAccounts/fileServices/shares@2019-06-01' = {
  name:  '${storageAccountName}/default/${fileShareName}'
  dependsOn: [ 
    storageAccount 
  ]
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    sku: {
      family: 'A'
      name: 'standard'
    }
    tenantId: tenantId
    enabledForDeployment: true
    enabledForTemplateDeployment: true
    enableRbacAuthorization: false
    accessPolicies: [
      {
        tenantId: tenantId
        objectId: keyVaultAccessObjectId
        permissions: {
          secrets: [
            'get'
            'list'
            'set'
            'delete'
          ]
        }
      }
    ]
  }
}

resource secretAllowListUsers 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'allowListUsers'
  properties: {
    value: allowListUsers
  }
}

resource secretOps 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'ops'
  properties: {
    value: ops
  }
}

resource secretMembers 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'members'
  properties: {
    value: members
  }
}

resource secretVisitors 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'visitors'
  properties: {
    value: visitors
  }
}

resource secretStorageKey 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'storageAccountKey'
  properties: {
    value: storageAccount.listKeys().keys[0].value
  }
}

resource secretEula 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'eula'
  properties: {
    value: toLower(eula) == 'true' ? 'TRUE' : 'FALSE'
  }
}

resource secretVersion 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'version'
  properties: {
    value: version
  }
}

resource secretGamemode 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'gamemode'
  properties: {
    value: gamemode
  }
}

resource secretDifficulty 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'difficulty'
  properties: {
    value: difficulty
  }
}

resource secretAllowCheats 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'allowCheats'
  properties: {
    value: toLower(allowCheats)
  }
}

resource secretMaxPlayers 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'maxPlayers'
  properties: {
    value: string(maxPlayers)
  }
}

resource secretOnlineMode 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'onlineMode'
  properties: {
    value: toLower(onlineMode)
  }
}

resource secretAllowList 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'allowList'
  properties: {
    value: toLower(allowList)
  }
}

resource secretLevelName 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'levelName'
  properties: {
    value: levelName
  }
}

resource secretLevelSeed 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'levelSeed'
  properties: {
    value: levelSeed
  }
}

resource secretViewDistance 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'viewDistance'
  properties: {
    value: string(viewDistance)
  }
}

resource secretTickDistance 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyVault
  name: 'tickDistance'
  properties: {
    value: string(tickDistance)
  }
}

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: serverName
  location: location
  dependsOn: [
    storageShare
    secretAllowListUsers
    secretOps
    secretMembers
    secretVisitors
    secretStorageKey
    secretEula
    secretVersion
    secretGamemode
    secretDifficulty
    secretAllowCheats
    secretMaxPlayers
    secretOnlineMode
    secretAllowList
    secretLevelName
    secretLevelSeed
    secretViewDistance
    secretTickDistance
  ]
  properties: {
    containers: [
      {
        name: serverName
        properties: {
          image: 'itzg/minecraft-bedrock-server'
          environmentVariables: [
            {
              name: 'EULA'
              value: toLower(eula) == 'true' ? 'TRUE' : 'FALSE'
            }
            {
              name: 'VERSION'
              value: version
            }
            {
              name: 'SERVER_NAME'
              value: serverName
            }
            {
              name: 'GAMEMODE'
              value: gamemode
            }
            {
              name: 'DIFFICULTY'
              value: difficulty
            }
            {
              name: 'ALLOW_CHEATS'
              value: toLower(allowCheats)
            }
            {
              name: 'MAX_PLAYERS'
              value: string(maxPlayers)
            }
            {
              name: 'ONLINE_MODE'
              value: toLower(onlineMode)
            }
            {
              name: 'ALLOW_LIST'
              value: toLower(allowList)
            }
            {
              name: 'ALLOW_LIST_USERS'
              value: allowListUsers
            }
            {
              name: 'OPS'
              value: ops
            }
            {
              name: 'MEMBERS'
              value: members
            }
            {
              name: 'VISITORS'
              value: visitors
            }
            {
              name: 'LEVEL_NAME'
              value: levelName
            }
            {
              name: 'LEVEL_SEED'
              value: levelSeed
            }
            {
              name: 'VIEW_DISTANCE'
              value: string(viewDistance)
            }
            {
              name: 'TICK_DISTANCE'
              value: string(tickDistance)
            }
          ]
          resources: {
            requests: {
              cpu: numberCpuCores
              memoryInGB: memory
            }
          }
          ports: [
            {
              port: 19132
              protocol: 'UDP'
            }
          ]
          volumeMounts: [
            {
              name: 'acishare'
              mountPath: '/data'
              readOnly: false
            }
          ]
        }
      }
    ]
    osType: 'Linux'
    ipAddress: {
      type: 'Public'
      ports: [
        {
          protocol: 'UDP'
          port: 19132
        }
      ]
      dnsNameLabel: serverName
    }
    restartPolicy: 'Never'
    volumes: [
      {
        name: 'acishare'
        azureFile: {
          readOnly: false
          shareName: fileShareName
          storageAccountName: storageAccount.name
          storageAccountKey: storageAccount.listKeys().keys[0].value
        }
      }
    ]
  }
}

output keyVaultName string = keyVault.name
output keyVaultId string = keyVault.id
output containerGroupName string = containerGroup.name
output containerIPAddress string = containerGroup.properties.ipAddress.ip
output containerFQDN string = containerGroup.properties.ipAddress.fqdn


