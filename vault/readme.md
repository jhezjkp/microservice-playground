# [Hashicorp]vault-机密管理服务实战

## 配置

vault.conf

```
storage "file" {
  path = "./data"
}

listener "tcp" {
  address     = "127.0.0.1:8200"
  tls_disable = 1
}
```

## 启动并初始化

启动value server

```shell
➜  vault git:(master) ✗ vault server -config vault.conf
==> WARNING: mlock not supported on this system!

  An `mlockall(2)`-like syscall to prevent memory from being
  swapped to disk is not supported on this system. Running
  Vault on an mlockall(2) enabled system is much more secure.

==> Vault server configuration:

                     Cgo: disabled
              Listener 1: tcp (addr: "127.0.0.1:8200", cluster address: "127.0.0.1:8201", tls: "disabled")
               Log Level: info
                   Mlock: supported: false, enabled: false
                 Storage: file
                 Version: Vault v0.7.3
             Version Sha: 0b20ae0b9b7a748d607082b1add3663a28e31b68

==> Vault server started! Log data will stream in below:
```

启动完成后开个新窗口继续完成初始化

```shell
#先配置环境
➜  ~ export VAULT_ADDR=http://127.0.0.1:8200
#初始化
#生成5份密钥，至少需要2份才能完成解封
➜  ~ vault init -key-shares=5 -key-threshold=2
Unseal Key 1: rNLpQaEuFRyg4W40/bOus5bQfD0Y1/X0do4iaW24vF1B
Unseal Key 2: RoXg0KS4XbRVjMoF2u2PPIwX9beaOXylVX3uEWkIfETX
Unseal Key 3: Dk281O2Ii7gDgtPif3mtldto21eVi1LqCqywk5MuN93n
Unseal Key 4: nOdukyiBQXHx5Q12WQENen5Nsn2lFDvGIdjMBZ7JXDvu
Unseal Key 5: GaBK4TzveucISquyxWKJcBZ8oGObgSmZrTnR/o4/cV+A
Initial Root Token: 831fdf18-4f67-3b7c-8937-638a29f137e9

Vault initialized with 5 keys and a key threshold of 2. Please
securely distribute the above keys. When the vault is re-sealed,
restarted, or stopped, you must provide at least 2 of these keys
to unseal it again.

Vault does not store the master key. Without at least 2 keys,
your vault will remain permanently sealed.
```

务必将5个解封密钥(实践中将由5人分别持有)和root token记录下来

```shell
➜  ~ vault unseal RoXg0KS4XbRVjMoF2u2PPIwX9beaOXylVX3uEWkIfETX
Sealed: true
Key Shares: 5
Key Threshold: 2
Unseal Progress: 1
Unseal Nonce: a34abfec-6319-7d69-0a54-8afc271bf696
➜  ~ vault unseal nOdukyiBQXHx5Q12WQENen5Nsn2lFDvGIdjMBZ7JXDvu
Sealed: false
Key Shares: 5
Key Threshold: 2
Unseal Progress: 0
Unseal Nonce:
```

## 认证并存取机密

存取机密前必须需要经过认证，首先使用root token进行测试

```shell
#将token设置为环境变量简化命令
➜  ~ export VAULT_TOKEN=831fdf18-4f67-3b7c-8937-638a29f137e9
#尝试保存一个密码到secret/password
➜  ~ vault write secret/password value=it_is_a_secret
Success! Data written to: secret/password
#将刚刚保存的密码读取出来
➜  ~ vault read secret/password
Key             	Value
---             	-----
refresh_interval	768h0m0s
vaule           	it_is_a_secret

vault write secret/password value=it_is_a_secret
#或者只读取指定key
➜  ~ vault read -field=value secret/password
it_is_a_secret%
#保存多个key/value
➜  ~ vault write secret/demo_api url=http://api.demo.com token=this_is_api_token
Success! Data written to: secret/demo_api
➜  ~ vault read secret/demo_api
Key             	Value
---             	-----
refresh_interval	768h0m0s
token           	this_is_api_token
url             	http://api.demo.com

➜  ~ vault read -field=url secret/demo_api
http://api.demo.com%
#删除
➜  ~ vault delete secret/password
Success! Deleted 'secret/password' if it existed.
```

## 密封

执行密封命令后，vault将停止服务，直至解封

```shell
➜  ~ vault seal
Vault is now sealed.
➜  ~ vault read -field=url secret/demo_api
Error reading secret/demo_api: Error making API request.

URL: GET http://127.0.0.1:8200/v1/secret/demo_api
Code: 503. Errors:

* Vault is sealed
```



