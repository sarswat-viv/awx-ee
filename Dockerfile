FROM quay.io/ansible/awx-ee:24.6.1

USER root

# Install Azure Ansible Collection into system-wide path readable by USER 1000
RUN ansible-galaxy collection install azure.azcollection \
    -p /usr/share/ansible/collections --force && \
    chmod -R a+rX /usr/share/ansible/collections

# Install Azure Python SDKs
RUN pip3 install --no-cache-dir \
    packaging \
    azure-identity \
    azure-keyvault-secrets \
    azure-mgmt-compute \
    azure-mgmt-network \
    azure-mgmt-resource \
    azure-mgmt-storage \
    azure-common \
    -r /usr/share/ansible/collections/ansible_collections/azure/azcollection/requirements.txt

# Add Git credential helper for passwordless Azure DevOps repo sync via Workload Identity
RUN printf '#!/usr/bin/env python3\nimport sys\nfrom azure.identity import DefaultAzureCredential\n\nif len(sys.argv) > 1 and sys.argv[1] == "get":\n    token = DefaultAzureCredential().get_token("499b84ac-1321-427f-aa17-267ca6975798/.default").token\n    print("username=azdo")\n    print(f"password={token}")\n' > /usr/local/bin/git-credential-azdo && \
    chmod 755 /usr/local/bin/git-credential-azdo && \
    git config --system credential.https://dev.azure.com.helper "/usr/local/bin/git-credential-azdo" && \
    git config --system credential.https://dev.azure.com.useHttpPath true

USER 1000

LABEL name="awx-azure-ee" \
      version="1.0.0" \
      description="Custom AWX Execution Environment with Azure Key Vault SDK and Entra ID Git Helper"