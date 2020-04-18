from azure.keyvault import KeyVaultClient, KeyVaultAuthentication, KeyVaultId
from azure.common.credentials import ServicePrincipalCredentials
from decouple import config

SECRET_ID = config('SECRET_ID')
AKV_CLIENT_ID = config('AKV_CLIENT_ID')
AKV_TENANT_ID = config('AKV_TENANT_ID')
AKV_SECRET = config('AKV_CLIENT_SECRET')
AKV_VAULT_URL = config('AKV_VAULT_URL')

# Function used to retrieve value of a Key in Azure Key Vault
# SECRET ID is the name of the key you want the value of
# Function will return the value of SECRET_ID
def get_secret(SECRET_ID):
    def auth_callback(server, resource, scope):
        credentials = ServicePrincipalCredentials(
            client_id = AKV_CLIENT_ID,
            secret = AKV_SECRET,
            tenant = AKV_TENANT_ID,
            resource = "https://vault.azure.net"
        )
        token = credentials.token
        return token['token_type'], token['access_token']

    client = KeyVaultClient(KeyVaultAuthentication(auth_callback))

    secret_bundle = client.get_secret(AKV_VAULT_URL, SECRET_ID, KeyVaultId.version_none).value
    return secret_bundle

KEY = get_secret(SECRET_ID)
print(KEY)
