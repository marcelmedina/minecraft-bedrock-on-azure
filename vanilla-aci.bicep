
@description('Server Name. (will be used as the DNS Label)')
param serverName string=''
@description('CPUs for the server')
param numberCpuCores int = 2

@description('Memory available to the server. Will allocate all except 100MB to Java')
param memory int = 4

@description('Whitelist of players that will be allowed in the server (use , to separate them)')
param whitelist string = ''

@description('Players that can issue commands (use , to separate them)')
param ops string = ''

@description('Accept minecraft server EULA?')
param eula bool

@description('Max number of players')
param maxPlayers int = 2

@description('Enable the use of command blocks?')
param enableCommandBlock bool = true

@description('Server Message of the day')
param motd string = ''

@description('Minecraft version to run (use LATEST for current version)')
param version string = 'LATEST'

@description('Server type (VANILLA, FORGE, BUKKIT, SPIGOT, PAPER, FTB, CURSEFORGE, SPONGEVANILLA, SPONGEFORGE)')
param type string = 'PAPER'

@description('Server mode (survival, creative, adventure, spectator)')
param mode string = 'creative'

var fileShareName  = 'minecraftdata'


var storageAccountType  = 'Standard_LRS'
var location = resourceGroup().location
var storageAccountName = '${serverName}storage'
var javaMemory = (memory * 1024) - 200


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
                name: 'WHITELIST'
                value: whitelist
            }
            {
                name: 'OPS'
                value: ops
            }
            {
                name: 'MAX_PLAYERS'
                value: '${maxPlayers}'
            }
            {
                name: 'ENABLE_COMMAND_BLOCK'
                value: '${enableCommandBlock}'
            }
            {
                name: 'MOTD'
                value: motd
            }
            {
                name: 'MEMORY'
                value: '${javaMemory}M'
            }
            {
              name: 'EULA'
              value: '${eula}'
            }
            {
              name: 'VERSION'
              value: version
            }
            {
              name: 'TYPE'
              value: type
            }
            {
              name: 'GAMEMODE'
              value: mode
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
              port: 25565
              protocol: 'TCP'
            }
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
          protocol: 'TCP'
          port: 25565
        }
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
          storageAccountKey: listKeys(storageAccount.name, storageAccount.apiVersion).keys[0].value
        }
      }
    ]
  }
}


