
@description('Server DNS name label (used for Azure DNS label and resource names). Must be 1-63 chars, lowercase letters, numbers, and hyphens.')
@minLength(1)
@maxLength(63)
param serverName string

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

@description('Accept Minecraft server EULA?')
param eula bool

@description('Max number of players')
param maxPlayers int = 10

@description('Allow cheats in the server')
param allowCheats bool = false

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

@description('Enable online mode (Xbox Live authentication)')
param onlineMode bool = true

@description('Enable allow list (whitelist)')
param allowList bool = false

var fileShareName  = 'minecraftdata'
var storageAccountType  = 'Standard_LRS'
var location = resourceGroup().location
var storageAccountName = '${serverName}storage'


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

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2019-12-01' = {
  name: serverName
  location: location
  dependsOn: [
    storageShare // Need to create the fileShare before creating the container.
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
              value: eula ? 'TRUE' : 'FALSE'
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
              value: allowCheats ? 'true' : 'false'
            }
            {
              name: 'MAX_PLAYERS'
              value: '${maxPlayers}'
            }
            {
              name: 'ONLINE_MODE'
              value: onlineMode ? 'true' : 'false'
            }
            {
              name: 'ALLOW_LIST'
              value: allowList ? 'true' : 'false'
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
              value: '${viewDistance}'
            }
            {
              name: 'TICK_DISTANCE'
              value: '${tickDistance}'
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


