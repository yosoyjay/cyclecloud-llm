#cloud-config
apt:
  sources:
    cyclecloud:
      source: "deb [signed-by=$KEY_FILE] https://packages.microsoft.com/repos/cyclecloud bionic main"
      key: |
        -----BEGIN PGP PUBLIC KEY BLOCK-----
        Version: GnuPG v1.4.7 (GNU/Linux)

        mQENBFYxWIwBCADAKoZhZlJxGNGWzqV+1OG1xiQeoowKhssGAKvd+buXCGISZJwT
        LXZqIcIiLP7pqdcZWtE9bSc7yBY2MalDp9Liu0KekywQ6VVX1T72NPf5Ev6x6DLV
        7aVWsCzUAF+eb7DC9fPuFLEdxmOEYoPjzrQ7cCnSV4JQxAqhU4T6OjbvRazGl3ag
        OeizPXmRljMtUUttHQZnRhtlzkmwIrUivbfFPD+fEoHJ1+uIdfOzZX8/oKHKLe2j
        H632kvsNzJFlROVvGLYAk2WRcLu+RjjggixhwiB+Mu/A8Tf4V6b+YppS44q8EvVr
        M+QvY7LNSOffSO6Slsy9oisGTdfE39nC7pVRABEBAAG0N01pY3Jvc29mdCAoUmVs
        ZWFzZSBzaWduaW5nKSA8Z3Bnc2VjdXJpdHlAbWljcm9zb2Z0LmNvbT6JATUEEwEC
        AB8FAlYxWIwCGwMGCwkIBwMCBBUCCAMDFgIBAh4BAheAAAoJEOs+lK2+EinPGpsH
        /32vKy29Hg51H9dfFJMx0/a/F+5vKeCeVqimvyTM04C+XENNuSbYZ3eRPHGHFLqe
        MNGxsfb7C7ZxEeW7J/vSzRgHxm7ZvESisUYRFq2sgkJ+HFERNrqfci45bdhmrUsy
        7SWw9ybxdFOkuQoyKD3tBmiGfONQMlBaOMWdAsic965rvJsd5zYaZZFI1UwTkFXV
        KJt3bp3Ngn1vEYXwijGTa+FXz6GLHueJwF0I7ug34DgUkAFvAs8Hacr2DRYxL5RJ
        XdNgj4Jd2/g6T9InmWT0hASljur+dJnzNiNCkbn9KbX7J/qK1IbR8y560yRmFsU+
        NdCFTW7wY0Fb1fWJ+/KTsC4=
        =J6gs
        -----END PGP PUBLIC KEY BLOCK-----

package_update: true
packages:
  # Needed for CycleCloud CLI.  Must specify python3.8-venv, python3-venv does not work.
  - python3.8-venv
  # These are needed, but failing when installing here.  See runcmd.
  #- openjdk-8-jdk
  # Will "install" (download package), but will not be operational.  See runcmd.
  # Tested with this specific version
  #- cyclecloud8=8.3.0-3062

runcmd:
  #
  # Install CycleCloud
  #
  # Manually install CycleCloud as it will fail during install due to Java 11 being installed as default and not working with apt
  - apt-get install -yq openjdk-8-jdk
  - update-java-alternatives -s java-1.8.0-openjdk-amd64
  - apt-get install -yq cyclecloud8=8.3.0-3062
  # Find temp install dir. I've found it to be 490f4cc0-d326-4f4b-b48e-26e6320f3acb, but including to avoid brittleness
  # Because /opt/cycle_server/config/ already exists, you need to force install
  - bash `find /opt/cycle_server/.installer -maxdepth 1 -type d | grep '/opt/cycle_server/.installer/'`/install.sh --force
  - /opt/cycle_server/cycle_server await_startup
  # Install CycleCloud CLI
  - unzip /opt/cycle_server/tools/cyclecloud-cli.zip -d /tmp
  - python3 /tmp/cyclecloud-cli-installer/install.py -y --installdir /home/${cyclecloud_admin_name}/.cycle --system
  # Separate command to avoid potential quote / double quote / var expansion troubles
  - cmd="/usr/local/bin/cyclecloud initialize --loglevel=debug --batch --url=http://localhost:8080 --verify-ssl=false --username=${cyclecloud_admin_name} --password='${cyclecloud_admin_password}'"
  # Must run as user or CycleCloud will attempt to install in /root/.cycle
  - runuser -l ${cyclecloud_admin_name} -c "$cmd"
  - runuser -l ${cyclecloud_admin_name} -c '/usr/local/bin/cyclecloud account create -f /opt/cycle_server/azure_subscription.json'
  - rm -f /opt/cycle_server/config/data/cyclecloud_account.json.imported
  # Import slurm cluster into CyleCloud
  # - Assume files have been copied to /home/${cyclecloud_admin_name}/{cyclecloud-projects, slurm}
  # Upload projects to CycleCloud "locker".  These will be used to configure nodes in the cluster.
  - for proj in /home/${cyclecloud_admin_name}/cyclecloud-projects/cc_*; do cd $proj; echo $proj; /usr/local/bin/cyclecloud project upload '${cyclecloud_subscription_name}-storage' --config /home/${cyclecloud_admin_name}/.cycle/config.ini; done
  # Copy Slurm config so CycleCloud is aware of it
  - cp /home/${cyclecloud_admin_name}/slurm/slurm-*.txt /opt/cycle_server/config/data
  # Import Slurm config to create cluster in CycleCloud
  - /usr/local/bin/cyclecloud import_cluster slurm -f /home/${cyclecloud_admin_name}/slurm/slurm.txt -p /home/${cyclecloud_admin_name}/slurm/slurm.json --config /home/${cyclecloud_admin_name}/.cycle/config.ini

write_files:
  - path: /opt/cycle_server/config/java_home
    content: |
      /usr/local/openjdk-8

  - path: /opt/cycle_server/config/data/cyclecloud_account.json
    content: |
      [
        {
          "AdType": "Application.Setting",
          "Name": "cycleserver.installation.initial_user",
          "Value": "${cyclecloud_admin_name}"
        },
        {
          "AdType": "AuthenticatedUser",
          "Name": "${cyclecloud_admin_name}",
          "RawPassword": "${cyclecloud_admin_password}",
          "Superuser": true
        },
        {
          "AdType": "Credential",
          "CredentialType": "PublicKey",
          "Name": "${cyclecloud_admin_name}/public",
          "PublicKey": "${cyclecloud_admin_public_key}"
        },
        {
          "AdType": "Application.Setting",
          "Name": "cycleserver.installation.complete",
          "Value": true
        }
      ]

  - path: /opt/cycle_server/azure_subscription.json
    content: |
      {
        "Environment": "public",
        "AzureRMUseManagedIdentity": true,
        "AzureResourceGroup": "${cyclecloud_rg}",
        "AzureRMApplicationId": " ",
        "AzureRMApplicationSecret": " ",
        "AzureRMSubscriptionId": "${azure_subscription_id}",
        "AzureRMTenantId": " ${azure_tenant_id}",
        "DefaultAccount": true,
        "Location": "${cyclecloud_location}",
        "Name": "${cyclecloud_subscription_name}",
        "Provider": "azure",
        "ProviderId": "${azure_subscription_id}",
        "RMStorageAccount": "${cyclecloud_storage_account}",
        "RMStorageContainer": "${cyclecloud_storage_container}",
        "AcceptMarketplaceTerms": true
      }
