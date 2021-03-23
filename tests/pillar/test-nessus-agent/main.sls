nessus-agent:
  lookup:
    package_url: https://S3BUCKET.F.Q.D.N/Nessus/linux/nessus-agent/NessusAgent.rpm
    nessus_server: ACAS-SERVER.F.Q.D.N
    # Following generated with `openssl rand -hex 16`
    nessus_key: 01efb7801937bf0346684935efe4d1bd3c4852ca06740a7ff93d5589edd99496
    nessus_port: 8834
    nessus_groups: ACAS_GROUP1,ACAS_GROUP2,ACAS_GROUP3
