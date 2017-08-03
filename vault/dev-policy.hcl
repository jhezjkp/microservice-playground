# allow on under secret/dev/*
path "secret/dev/*" {
    capabilities = ["list", "read", "create", "update", "delete"]    
}
