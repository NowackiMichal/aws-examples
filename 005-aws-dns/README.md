CLOUD: Manage Public DNS Names

Create A Record in the Public DNS Management Service.

Description

It is required to set up a DNS record.

NOTE: For this task, you can use one of the available options:

    The tasks for either AWS or Azure or GCP.

    Steps that should be completed using the cloud provider available for you:
        Create or use an existing Virtual Server with a public IP address.
        Set Name Servers in the free external DNS register service.
        Wait until the answer DNS query for your domain is sent from DNS servers (use nslookup for testing).
        Add a type A record to the DNS.

Acceptance Criteria

    VM IP address is resolved from its DNS name using nslookup.
    DNS servers should be displayed in nslookup response.