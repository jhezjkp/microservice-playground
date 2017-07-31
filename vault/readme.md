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

务必将5个解封密钥(实践中将由5人分别持有)和root token记录下来。

使用vault unseal命令执行解封(不要将解密key直接写在unseal命令之后)

```shell
➜  ~ vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 5
Key Threshold: 2
Unseal Progress: 1
Unseal Nonce: 003dfa27-bc31-2ab1-ef50-6ae889ab4394
➜  ~ vault unseal
Key (will be hidden):
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

## 通过Http API访问

除了cli外，还可以通过http api接口访问vault：

```shell
➜  vault git:(master) ✗ curl -H X-Vault-Token:831fdf18-4f67-3b7c-8937-638a29f137e9  http://localhost:8200/v1/secret/demo_api
{"request_id":"d031b2ef-15d0-8d32-5aa1-56ecbc05ceb4","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"token":"this_is_api_token","url":"http://api.demo.com"},"wrap_info":null,"warnings":null,"auth":null}
```

## 启用审计

vault同时支持多个审计后端，以防止其中某个后端被篡改的情况：

```shell
vault audit-enable file file_path=log/audit.log
```

所有的请求和响应都会各自对应一条审计日志，日志中的敏感信息(如token)将会被哈希脱敏(HMAC-SHA256)：

```shell
#查询命令
➜  vault git:(master) ✗ vault read secret/hello
Key             	Value
---             	-----
refresh_interval	768h0m0s
value           	world
```

对应的审计日志

```json
{"time":"2017-07-31T04:08:36Z","type":"request","auth":{"client_token":"hmac-sha256:3c5e878019363f51f7d322738206e1996373bd69b5460c0db6cd46abe0b111ab","accessor":"hmac-sha256:8ec7f96e2fd3e55a30c4234a00f20286a4bdd63015764fa942e2e2a905718e02","display_name":"root","policies":["root"],"metadata":null},"request":{"id":"5c257f25-2f3f-a4c2-a81b-200aa58f31d0","operation":"read","client_token":"hmac-sha256:3c5e878019363f51f7d322738206e1996373bd69b5460c0db6cd46abe0b111ab","client_token_accessor":"hmac-sha256:8ec7f96e2fd3e55a30c4234a00f20286a4bdd63015764fa942e2e2a905718e02","path":"secret/hello","data":null,"remote_address":"127.0.0.1","wrap_ttl":0,"headers":{}},"error":""}
{"time":"2017-07-31T04:08:36Z","type":"response","auth":{"client_token":"hmac-sha256:3c5e878019363f51f7d322738206e1996373bd69b5460c0db6cd46abe0b111ab","accessor":"hmac-sha256:8ec7f96e2fd3e55a30c4234a00f20286a4bdd63015764fa942e2e2a905718e02","display_name":"root","policies":["root"],"metadata":null},"request":{"id":"5c257f25-2f3f-a4c2-a81b-200aa58f31d0","operation":"read","client_token":"hmac-sha256:3c5e878019363f51f7d322738206e1996373bd69b5460c0db6cd46abe0b111ab","client_token_accessor":"hmac-sha256:8ec7f96e2fd3e55a30c4234a00f20286a4bdd63015764fa942e2e2a905718e02","path":"secret/hello","data":null,"remote_address":"127.0.0.1","wrap_ttl":0,"headers":{}},"response":{"secret":{"lease_id":""},"data":{"value":"hmac-sha256:1882b67e2dcce6aebac6bc907912e0dab1dc6c0bf50667145eea4046479da1a0"}},"error":""}
```

vault提供了一个查询token对应的HMAC-SHA256哈希值的api，通过它可以查询对应的哈希值：

```shell
#先查询审计类型
➜  vault git:(master) ✗ vault audit-list
Path   Type  Description  Replication Behavior  Options
file/  file               replicated            file_path=log/audit.log
#之前的审计日志是文件类型，查询对应审计日志中token的哈希值时需要指定是哪个审计日志的
➜  vault git:(master) ✗ curl -H X-Vault-Token:831fdf18-4f67-3b7c-8937-638a29f137e9 -d '{"input": "831fdf18-4f67-3b7c-8937-638a29f137e9"}' -X POST http://localhost:8200/v1/sys/audit-hash/file
{"hash":"hmac-sha256:3c5e878019363f51f7d322738206e1996373bd69b5460c0db6cd46abe0b111ab","request_id":"86e26b70-f649-c807-b9cd-c73bbfe841bf","lease_id":"","renewable":false,"lease_duration":0,"data":{"hash":"hmac-sha256:3c5e878019363f51f7d322738206e1996373bd69b5460c0db6cd46abe0b111ab"},"wrap_info":null,"warnings":null,"auth":null}
```

从响应的结果中可以看到831fdf18-4f67-3b7c-8937-638a29f137e9这个token的哈希值为3c5e878019363f51f7d322738206e1996373bd69b5460c0db6cd46abe0b111ab，与之前的审计日志匹配。

## 策略(policy)与token管理

vault中的一切都是基于路径的，策略对指定路径进行声明式允许或禁止以达到操作管理的目的。默认的策略是禁止。

```shell
#列出系统中当前的所有策略
➜  vault git:(master) ✗ vault policies
default
root
#查看指定策略详情(root策略是内建策略，无法修改或删除，拥有最高权限)
➜  vault git:(master) ✗ vault read sys/policy/root
Key  	Value
---  	-----
name 	root
rules
#创建策略
➜  vault git:(master) ✗ cat demo-policy.hcl
# allow read secret/demo*
path "secret/demo*" {
    capabilities = ["read"]
}
➜  vault git:(master) ✗ vault write sys/policy/demo-policy rules=@demo-policy.hcl
Success! Data written to: sys/policy/demo-policy
#创建一个token，将继承执行创建token的token的策略
➜  vault git:(master) ✗ vault token-create
Key            	Value
---            	-----
token          	62943731-51a4-c6fc-7893-e02c72c1aabf
token_accessor 	ebef82d4-419b-5cd7-d0a9-579af1437153
token_duration 	0s
token_renewable	false
token_policies 	[root]
#查看新建的token的详情
➜  vault git:(master) ✗ vault token-lookup 62943731-51a4-c6fc-7893-e02c72c1aabf
Key             	Value
---             	-----
accessor        	ebef82d4-419b-5cd7-d0a9-579af1437153
creation_time   	1501467439
creation_ttl    	0
display_name    	token
expire_time     	<nil>
explicit_max_ttl	0
id              	62943731-51a4-c6fc-7893-e02c72c1aabf
issue_time      	2017-07-31T10:17:19.438138622+08:00
meta            	<nil>
num_uses        	0
orphan          	false
path            	auth/token/create
policies        	[root]
renewable       	false
ttl             	0
#新建的token有root权限，撤消它
➜  vault git:(master) ✗ vault token-revoke 62943731-51a4-c6fc-7893-e02c72c1aabf
Success! Token revoked if it existed.
#创建token并直接附加demo-policy策略
➜  vault git:(master) ✗ vault token-create -policy=demo-policy
Key            	Value
---            	-----
token          	d483aea7-a408-413b-d889-96c359215365
token_accessor 	99cb713e-9a34-4e03-15e6-34d4cebde1ef
token_duration 	768h0m0s
token_renewable	true
token_policies 	[default demo-policy]
#新开一个终端，对新token进行测试，结果符合预期
➜  ~ vault auth
Token (will be hidden):
Successfully authenticated! You are now logged in.
token: d483aea7-a408-413b-d889-96c359215365
token_duration: 2764737
token_policies: [default demo-policy]
➜  ~ vault read secret/hello
Error reading secret/hello: Error making API request.

URL: GET http://127.0.0.1:8200/v1/secret/hello
Code: 403. Errors:

* permission denied
➜  ~ vault read secret/demo_api
Key             	Value
---             	-----
refresh_interval	768h0m0s
token           	this_is_api_token
url             	http://api.demo.com

➜  ~ vault delete secret/demo_api
Error deleting 'secret/demo_api': Error making API request.

URL: DELETE http://127.0.0.1:8200/v1/secret/demo_api
Code: 403. Errors:

* permission denied
```

token创建后就无法变更其对应的策略，如果需要修改，可以通过以下方式实现：

+ 撤销当前的token，重新生成一个附加了新策略的token
+ 修改当前token对应的策略

