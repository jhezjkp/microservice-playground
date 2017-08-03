# [Hashicorp]vault-机密管理服务实战

[TOC]

## 概述

[vault](https://www.vaultproject.io)是一个用于管控机密数据访问的工具，可以用于管理API密钥、密码、证书等等机密数据，vault提供了统一的接口来访问这些机密数据的接口，严格控制访问权限并记录详细的审计日志。

vault设计原则[^1]:

+ 密钥轮转过期支持：vault颁发的密钥支持时效和次效两种特性，支持续约和撤销
+ 安全分发：TLS加密和cubbyhole分发密钥防止中间人攻击
+ 最小暴露原则：vault略论策略为禁止，最小化权限以防止数据被非授权访问
+ 访问侦测：所有访问和响应数据都有审计日志
+ 安全模式：vault提供一种安全模式，当检测到入侵时，可以将数据密封，以阻止数据泄露

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

使用`vault unseal`命令执行解封(不要将解密key直接写在unseal命令之后)

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

在具体的生产环境实践中，在初始化vault时，为防止执行初始化操作的人直接看到生成的解封密钥，可以在初始化时指定加密公钥的办法将生成的解封密钥加密输出，仅持有对应密钥的人才能解密得到原始解封密钥以确保vault的安全[^5]，以下以gpg为例来进行说明：

```shell
#vivia.asc是gpg公钥，演示时都使用同一人的公钥
➜  ~ vault init -key-shares=3 -key-threshold=2 \
    -pgp-keys="vivia.asc,vivia.asc,vivia.asc"
Unseal Key 1: wcBMA1qBDjHh2tL6AQgAhreszZMElunmjnclWwpGA+WSiPbeYGFVdzHrpkkmMNz4fkwT70KJcqyOziWpf+GDba6QtIhId8+mIAz3XV5ea18/rcENYmjbuLWjbeExr3AiSWsKyVL/KP35tIPRZ5umN2TshPeIdWr6PLFDo9z6kC/jRDpN7Jfd6HhC/PyTcA54HY6tJZSMuE3nOUf8A9pAdIN1uI8DbFMyIXGuG0lbpXhBQsq9RxfP/X9t/8X7pXDlY/eb8UJrDKQ8e43Z6g3sLU22Eb8G1fJA0JTcXtUS07RylFv0J5uXuVvLGzvhKsXOa4kbvK+RhMEc4I1ukzQqFUrLhCGzs7Z7yqFg+P50cNLgAeRfavfu6kHOClGNSzQMzOyU4erW4BfgPOGJQ+AF4s+QZivgPOZrHJlZuWxEX9A2/bIrl9NZOe07DQCJoUypyGoeTvaMQ0JszERoz5k+R/chVZCK/t8yAIAjcR0PKYF3P6RuSkdR4L3hOpjgcuSoN6wGaAi4WRcNnO3/9kAP4tJqsizhZXsA
Unseal Key 2: wcBMA1qBDjHh2tL6AQgAJ1pGWrR2jPwBcxPxO3sIxWP5wwFryhW3NJ/onH5LbWC7/kX2R1qKW2cydIsW7c/9ydovyCJoHrXKPoSDivMCz7POPeF66PaRKfi+Lsxda4ALU9YbUUr6id64xguuYO3I3gT272rhZ4L3ppasQIKc24K1vaIbyhWTbWS2LA6pvC5oAmePgJa9cxbcTAoS1m8yZ63qdyZf8QnPV9e3vnSCPXzrPYmReEq4AozzmqGRxFRUSaA6Zb/O+wQUDY9qPaK95jwPcVhQKqMj+UceHe7RxXYXdThFyOE/vzzwJdOhqYwNldx5TGEUARKtPlqXaNlji61cGBQLtG3enNS35PInudLgAeTSinPMsUDe30EKHr8lV2pp4T024JTgNOFXGOBx4pH3ux7g7+YvhOWd2zEFhbNkkoMkUlpJXlpI2DnDPDBkmSntL7O2bhzGPg4HoH4TjJo0Rxt1YGByZVIpu/ahMjQAX+rmed+T4B7hr+LgWuSM30R9oA735GJQeNmkWQ7b4tf5jK7hb0sA
Unseal Key 3: wcBMA1qBDjHh2tL6AQgAXeUwEcPkoEZt7LVaspL72IWvlc2PEDtlyYuO+PLidvNEAdALCvEEcs5zUFzYBxFAm5JqwHHYmxmiELmsXCFGRfkKXHFVetLAWstFkuLZ3e9yz7bU7d4R2hRviel9hTDm1T/MsCqiT40pETWj5WUpzlbYMUFmFySXomqxVhmoqH4T6sznyedIntZXP5Yrqel3mNaVgB4G3E5qZ6czC0b7QV8uVv026lUV2F9JZ4OXCXEJub0dq5qk4d+bpuutjwzPYhfOZhRFFPHK6xFB7j+UpguQHlpIiExi3TgN9OYF5xWQ6cexs+bHUyQaDqUoXtzSjaGGC75LuUKNz+E2p1s8udLgAeSwhebNvjhO8aWQ/tXVwqp34Qv+4PPgCOEe9OAU4l0XqHbgN+b3nKfY5obUFy7e2MluP0f0zeDjl57Nm8SiHawVScdkPi7WiR7QWUhchmqqKyvIkmu7LHpx3u8Di8VgLLEfGoZ74Ljhu4fgXOSAGGlslKt8TCxsEIfqoAZG4ruHjIfhIvsA
Initial Root Token: 6cee277d-54bb-a033-fe9c-0f83bd6f4f77

Vault initialized with 3 keys and a key threshold of 2. Please
securely distribute the above keys. When the vault is re-sealed,
restarted, or stopped, you must provide at least 2 of these keys
to unseal it again.

Vault does not store the master key. Without at least 2 keys,
your vault will remain permanently sealed.
#解密解封密钥，生产环境应该是由持有解密密钥的人各自到自己的机器上进行
➜  ~ echo "wcBMA1qBDjHh2tL6AQgAhreszZMElunmjnclWwpGA+WSiPbeYGFVdzHrpkkmMNz4fkwT70KJcqyOziWpf+GDba6QtIhId8+mIAz3XV5ea18/rcENYmjbuLWjbeExr3AiSWsKyVL/KP35tIPRZ5umN2TshPeIdWr6PLFDo9z6kC/jRDpN7Jfd6HhC/PyTcA54HY6tJZSMuE3nOUf8A9pAdIN1uI8DbFMyIXGuG0lbpXhBQsq9RxfP/X9t/8X7pXDlY/eb8UJrDKQ8e43Z6g3sLU22Eb8G1fJA0JTcXtUS07RylFv0J5uXuVvLGzvhKsXOa4kbvK+RhMEc4I1ukzQqFUrLhCGzs7Z7yqFg+P50cNLgAeRfavfu6kHOClGNSzQMzOyU4erW4BfgPOGJQ+AF4s+QZivgPOZrHJlZuWxEX9A2/bIrl9NZOe07DQCJoUypyGoeTvaMQ0JszERoz5k+R/chVZCK/t8yAIAjcR0PKYF3P6RuSkdR4L3hOpjgcuSoN6wGaAi4WRcNnO3/9kAP4tJqsizhZXsA" | base64 -D | gpg -dq
ce5a5b27fd8449b03b7b0672f5ba32a1aee5767efff69640d4c46e6ae40b2512d4
➜  ~ echo "wcBMA1qBDjHh2tL6AQgAJ1pGWrR2jPwBcxPxO3sIxWP5wwFryhW3NJ/onH5LbWC7/kX2R1qKW2cydIsW7c/9ydovyCJoHrXKPoSDivMCz7POPeF66PaRKfi+Lsxda4ALU9YbUUr6id64xguuYO3I3gT272rhZ4L3ppasQIKc24K1vaIbyhWTbWS2LA6pvC5oAmePgJa9cxbcTAoS1m8yZ63qdyZf8QnPV9e3vnSCPXzrPYmReEq4AozzmqGRxFRUSaA6Zb/O+wQUDY9qPaK95jwPcVhQKqMj+UceHe7RxXYXdThFyOE/vzzwJdOhqYwNldx5TGEUARKtPlqXaNlji61cGBQLtG3enNS35PInudLgAeTSinPMsUDe30EKHr8lV2pp4T024JTgNOFXGOBx4pH3ux7g7+YvhOWd2zEFhbNkkoMkUlpJXlpI2DnDPDBkmSntL7O2bhzGPg4HoH4TjJo0Rxt1YGByZVIpu/ahMjQAX+rmed+T4B7hr+LgWuSM30R9oA735GJQeNmkWQ7b4tf5jK7hb0sA" | base64 -D | gpg -dq
4924c349c68805b24e61e489183785d2cd2711048a7b5ae423453e523c6867051c
#拿到两外密钥即可执行解封，生产环境应该是由持有解密密钥的人各自到自己的机器上进行
➜  ~ vault unseal
Key (will be hidden):
Sealed: true
Key Shares: 3
Key Threshold: 2
Unseal Progress: 1
Unseal Nonce: f79ee25d-e0b3-5516-04f9-747af99546f2
➜  ~ vault unseal
Key (will be hidden):
Sealed: false
Key Shares: 3
Key Threshold: 2
Unseal Progress: 0
Unseal Nonce:
➜  ~ vault status
Sealed: false
Key Shares: 3
Key Threshold: 2
Unseal Progress: 0
Unseal Nonce:
Version: 0.7.3
Cluster Name: vault-cluster-6d0d0169
Cluster ID: d6f3bf2c-b44d-14c8-f08c-d36ecca921a7

High-Availability Enabled: false
```

另外，在生产环境root token将在完成基础设置后撤销，需要时再行生成一个新的：

```shell
#撤销root token
➜  ~ vault token-revoke 6cee277d-54bb-a033-fe9c-0f83bd6f4f77
Success! Token revoked if it existed.
➜  ~ vault token-lookup 6cee277d-54bb-a033-fe9c-0f83bd6f4f77
error looking up token: Error making API request.

URL: POST http://127.0.0.1:8200/v1/auth/token/lookup
Code: 403. Errors:

* permission denied
#当需要时，再生成一个root token，需要提供持有root token人的pgp公钥，并需要2个解封密钥授权
➜  ~ vault generate-root -pgp-key="vivia.asc"
Root generation operation nonce: 5737a318-c169-d029-76c3-cb98a86868a0
Key (will be hidden):
Nonce: 5737a318-c169-d029-76c3-cb98a86868a0
Started: true
Generate Root Progress: 1
Required Keys: 2
Complete: false
PGP Fingerprint: 2aaaef4f5ce9d93154c8233bb7be4c54223f9907
➜  ~ vault generate-root -pgp-key="vivia.asc"
Root generation operation nonce: 5737a318-c169-d029-76c3-cb98a86868a0
Key (will be hidden):
Nonce: 5737a318-c169-d029-76c3-cb98a86868a0
Started: true
Generate Root Progress: 2
Required Keys: 2
Complete: true
PGP Fingerprint: 2aaaef4f5ce9d93154c8233bb7be4c54223f9907

Encoded root token: wcBMA1qBDjHh2tL6AQgAI+Tx2bXsLAXEnx/q5p/OfZMZcfS0sPhAo4abQxCH4BWcVpTXYIG91KOxqVD4SfsrC9qDM+22+Hsw8qPCFyaTNB6RpisJyZO+tr1/hXbp3Jphwpu02llGNmE03LS5P4VveSLg/qJNbKXT0bFlub57mNFFPgND1I/4YV/7v+plOFSpY6ENr+AvO24gbggOWux/eG1+4CF9OBYbV7ua1zgTzqk6LOlfPEkhnvN7nBEGznEgTN9T/eNRSNZZo80bD9s0ua/mtUUcy23rJAMxWLIh5yIXv/2I/SHR/cBcjCVysO0CMdolPlAxWiUapH0jhhEMQ/BisD9mJaUuL0QK/5sg8tLgAeS1qdQJVyc5WvS0SszIPndo4X084IHgNeEvneCY4lqlLt/gcuXjnNZhPNpQ6WN+0Q32h3WuvACgN610jAQuB+la6ectWuAf4sN4qnjgoOQ+9+Bc9e/J4sE+vj4Bmu1b4njiQTzhWF4A
#解密得到原始的root token
➜  ~ echo "wcBMA1qBDjHh2tL6AQgAI+Tx2bXsLAXEnx/q5p/OfZMZcfS0sPhAo4abQxCH4BWcVpTXYIG91KOxqVD4SfsrC9qDM+22+Hsw8qPCFyaTNB6RpisJyZO+tr1/hXbp3Jphwpu02llGNmE03LS5P4VveSLg/qJNbKXT0bFlub57mNFFPgND1I/4YV/7v+plOFSpY6ENr+AvO24gbggOWux/eG1+4CF9OBYbV7ua1zgTzqk6LOlfPEkhnvN7nBEGznEgTN9T/eNRSNZZo80bD9s0ua/mtUUcy23rJAMxWLIh5yIXv/2I/SHR/cBcjCVysO0CMdolPlAxWiUapH0jhhEMQ/BisD9mJaUuL0QK/5sg8tLgAeS1qdQJVyc5WvS0SszIPndo4X084IHgNeEvneCY4lqlLt/gcuXjnNZhPNpQ6WN+0Q32h3WuvACgN610jAQuB+la6ectWuAf4sN4qnjgoOQ+9+Bc9e/J4sE+vj4Bmu1b4njiQTzhWF4A" | base64 -D | gpg -dq
a177f2cf-e227-3025-8439-35d26de2f06f
#使用新root token进行操作
➜  ~ export VAULT_TOKEN=a177f2cf-e227-3025-8439-35d26de2f06f
➜  ~ vault read secret/hello
Key             	Value
---             	-----
refresh_interval	768h0m0s
vaule           	world
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

注意，使用命令行认证成功后登录数据将会存储在`$HOME/.vault-token`中，后续命令将直接使用该文件中的内容进行认证，如果文件不存在了则需要重新认证。

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

发生紧急状况时，应该要立刻将vault密钥将机密锁死以防机密数据的进一步泄露以争取时间调查原因并采取相关措施。相关状况对应处置如下[^6]：

+ 存储在vault中的一个机密数据泄露了：立即生成一个新机密并替换它，并且使用`vault rotate`命令切换一个vault存储用的加密密钥(该操作是透明的，vault将保持在线并提供服务，使用`vault key-status`命令可以看到加密密钥的变更)
+ vault用户凭证(如token)泄露了：立即将泄露的凭证吊销，并且使用`vault rotate`命令切换一个vault存储用的加密密钥
+ vault解封密钥泄露了：使用`vault rekey`命令重新生成新的解封密钥

ps：`vault rekey`命令还可以变更解封密钥的总份数和解封需要的份数，适用于增减vault管理员的情况

```shell
#查看rekey状态
➜  ~ vault rekey -status
Nonce:
Started: false
Key Shares: 0
Key Threshold: 0
Rekey Progress: 0
Required Keys: 2
#开始rekey
➜  ~ vault rekey -init -key-shares=3 -key-threshold=2 -pgp-keys="vivia.asc,vivia.asc,vivia.asc" -backup=true
Nonce: 1064b780-e948-b1c1-0cf2-0c712057957e
Started: true
Key Shares: 3
Key Threshold: 2
Rekey Progress: 0
Required Keys: 2
PGP Key Fingerprints: [2aaaef4f5ce9d93154c8233bb7be4c54223f9907 2aaaef4f5ce9d93154c8233bb7be4c54223f9907 2aaaef4f5ce9d93154c8233bb7be4c54223f9907]
Backup Storage: true
#解封密钥持有人1确认rekey操作
➜  ~ vault rekey
Rekey operation nonce: 1064b780-e948-b1c1-0cf2-0c712057957e
Key (will be hidden):
Nonce: 1064b780-e948-b1c1-0cf2-0c712057957e
Started: true
Key Shares: 3
Key Threshold: 2
Rekey Progress: 1
Required Keys: 2
PGP Key Fingerprints: [2aaaef4f5ce9d93154c8233bb7be4c54223f9907 2aaaef4f5ce9d93154c8233bb7be4c54223f9907 2aaaef4f5ce9d93154c8233bb7be4c54223f9907]
Backup Storage: true
#解封密钥持有人2确认rekey操作，并得到最终结果
➜  ~ vault rekey
Rekey operation nonce: 1064b780-e948-b1c1-0cf2-0c712057957e
Key (will be hidden):


Key 1 fingerprint: 2aaaef4f5ce9d93154c8233bb7be4c54223f9907; value: wcBMA1qBDjHh2tL6AQgAsMIlKIMjFPHQvbOyXfbeSztoLxWF8kq7EmFtRi2AV86ZPPzK6cvcv0edckchD1EPjvC+SjZEmHD2u93k0lytm8cQhiEo8qQQgzkPMDGN1YOPZP3g5JdydjdnCM9YVpO0elBHJ3OzLotYNawLSNK93OiuVSYXsLsQvit33z5Rban1ZtxOpdmtkVYVxGnoEs9gpp6A8acW/tOeSOV9W6nqUAZy4enbYtarmZ2JAcLjXisSkBAbA1YN9NGa/R5cRgqGD0YbFusThkDN4y8tz6SntVJzmYjMrH9khYo3buWASvUv8GlYz4e/3qAVvq79/j07HEvGHcbABnJ8PN01A4N6pdLgAeTVPRe8fPQynBfzXQccBXat4VOp4OPgtOGYF+Bi4txz5U/g3OZO29Xr/2jLUb/eYEHv2DMsGCN9Z1dCD+AD+EbqOaPhpcYT+aZsgQnYumaiaq3K1ZiFv57k3bqVHt4rlEHzoJM74NDh6DDgKOQBwpWJ+r7NJSnDt6os7jNl4vv3KMPhP9AA
Key 2 fingerprint: 2aaaef4f5ce9d93154c8233bb7be4c54223f9907; value: wcBMA1qBDjHh2tL6AQgAapw1oJqK6DXRj68ccumEcPzK1e6hg+hfUpZu4j2QSw5VBz17SzADHR2yOnN1cRfrOMLgIlJ55UsvLOevvnk31OH4fq6W8j71QMlAKgKbLQTC0wnviE7YJPfv1vRb3xgnHwV1x7Te4/KBOHY2weLNkCXjnceWhSTSTfQm4849AETmMMfwnibQL6Id7JlH9myODp4PhQulEsxFe2AGZsGfA2gzV8i3xGPOmBOHcm7pZJSeWCWiRusS5QDY2nJL/kDdHDj/A3xZLviprfTI7F4D6sNYl2EG70qQk9xqr3Zp5xa+vIxtkWJblIYhXbY+5I9HnVIZj1diu6fVadIzoxOyC9LgAeTe7H1P2d4sSde3H7x5LeRr4WYF4H3go+G9HOBp4kUlgRXgkOZT09Ia+kkB7PviN/5TPvgXOSqW2AilVdj76Ap/xGeNYJuJ1T3FcVYSL5fBsaOJ9ATWV6xRzcYmrnK8kpZ060Zd4PfhOkTgJOTP1Rca2JD0u8381owbrReN4kuFt2nhbtYA
Key 3 fingerprint: 2aaaef4f5ce9d93154c8233bb7be4c54223f9907; value: wcBMA1qBDjHh2tL6AQgAvnycpk/SRGpLm4jxdJCQbOFry9uPGGrDime+AqfUQXkxAMhuCfpsEpTpyTue0BS4z10EMi9OF1t5nA0KwNzSR0MEg8XM+HiJwoqMzmxOsy/1scM0PH2oPv5gfP1lheDlG+/jXRuE6XIZKNBtjAP0FXMc/QhdYewOcpRh/wHt28zfLPVdkBR5yGlFTHxB7uJZ9+2kNdu2mhhaSTSwPLH417IlmgylVzMTkx5rKrCC/BOGdAf8Qh5eSyNUvGczdTNdBgHjXKi2BMf34ZfIE54UFho+3omfUqPqfQfDrc/T26T102h7tSPmx5jXBFg2KvfEDStmOhXtphC1FFK0jIVzcNLgAeSOTvMi0a+pCiTcDFjlvycq4fXR4DDg8OHax+AU4uiZlj/gZebsM++oItv94mt/zJ/eCcN5wyBz2OlqY6nVzKLAFNMS5PSpWjBaMMIoQjuKOm2ruBnP8RLsrS6+FG7j4DUpl+7C4IzhFxTgVOQo2aTVAB7owib/6pvT1ZXF4h2MOoHhpF4A

Operation nonce: 1064b780-e948-b1c1-0cf2-0c712057957e

The encrypted unseal keys have been backed up to "core/unseal-keys-backup"
in your physical backend. It is your responsibility to remove these if and
when desired.

Vault rekeyed with 3 keys and a key threshold of 2. Please
securely distribute the above keys. When the vault is re-sealed,
restarted, or stopped, you must provide at least 2 of these keys
to unseal it again.

Vault does not store the master key. Without at least 2 keys,
your vault will remain permanently sealed.
#保存好后删除备份的解封密钥
➜  ~ vault rekey -delete
Stored keys deleted.
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
#创建一个只有两次有效次数的token
➜  vault git:(master) ✗ vault token-create --use-limit=2 -policy=demo-policy　
Key            	Value
---            	-----
token          	6dc6d978-faba-c2eb-91b9-81bb665d9207
token_accessor 	f8d9a2e9-eb9f-16ba-978e-00b34619a8e1
token_duration 	0s
token_renewable	false
token_policies 	[root]
#在新终端中测试刚生成的token，认证使用一次，读取机密使用一次，第二次读取时vault就提示无权限了
➜  vault git:(master) ✗ vault auth
Token (will be hidden):
Successfully authenticated! You are now logged in.
token: 6dc6d978-faba-c2eb-91b9-81bb665d9207
token_duration: 0
token_policies: [root]
➜  vault git:(master) ✗ vault read secret/demo_api
Key             	Value
---             	-----
refresh_interval	768h0m0s
token           	this_is_api_token
url             	http://api.demo.com

➜  vault git:(master) ✗ vault read secret/demo_api
Error reading secret/demo_api: Error making API request.

URL: GET http://127.0.0.1:8200/v1/secret/demo_api
Code: 403. Errors:

* permission denied
#创建一个2分钟有效期的token
➜  vault git:(master) ✗ vault token-create -ttl=2m -renewable=false -policy=demo-policy　
Key            	Value
---            	-----
token          	926a2fa8-a8ad-3ff5-aa5d-7ecda58b609a
token_accessor 	bb93f49a-e463-0e92-1e34-6aa29b4d19a3
token_duration 	2m0s
token_renewable	true
token_policies 	[root]
```

token创建后就无法变更其对应的策略，如果需要修改，可以通过以下方式实现：

+ 撤销当前的token，重新生成一个附加了新策略的token
+ 修改当前token对应的策略

生成token时，会同时生成一个token_accessor，token_accessor与token是一一对应的，为保证只有被授予token的人才持有具体的token，因此不能直接存档token，但事后需要查询该token对应的信息(如附加的策略)或撤销该token时，我们可以通过记录对应的token_accessor，再通过调用/auth/token/lookup-accessor[/accessor]和/auth/token/revoke-accessor这两个接口进行(或通过应用的命令行加-accessor选项传token_accessor达成目标)。另外，在配置审计模块时，我们可以加一个hmac_accessor=false配置，这样审计系统就不会对token-accessor进行哈希了，定位具体用户就更方便了。

## AppRole认证模块

AppRole模块允许机器或服务(应用)通过预定义的角色(role-id+secret-id)进行vault认证以获取运行时需要的机密数据。该模块的流程如下：

1. 创建role，预设secret-id策略(有效时间、有效使用次数等)、生成的token的有效时间、有效使用次数和附加的策略等
2. 生成role-id，一个role只有一个role-id(可以通过api将role-id修改成自定义值)
3. 生成并分发secret-id
4. 目标机器或服务拿到role-id和secret-id后进行认证，成功后即可获得一个token
5. 使用步骤4获取的token向vault获取机密数据

与生成token分发机器或服务获取机密数据的方案相比，AppRole方案有以下优势：

+ 同一应用使用同一app-id，便于审计
+ 可以更新AppRole变更token对应的策略(token生成后无法变更策略)
+ 可以限定指定ip范围才能登录

```shell
#启用approle认证模块
➜  vault git:(master) ✗ vault auth-enable approle
Successfully enabled 'approle' at 'approle'!

#生成demo-role
➜  vault git:(master) ✗ vault write auth/approle/role/demo-role secret_id_ttl=10m token_num_uses=3 token_ttl=20m token_max_ttl=30m secret_id_num_uses=4 policies=demo-policy
Success! Data written to: auth/approle/role/demo-role

#查看新创建的demo-role
➜  vault git:(master) ✗ vault read auth/approle/role/demo-role
Key               	Value
---               	-----
bind_secret_id    	true
bound_cidr_list
period            	0
policies          	[default demo-policy]
secret_id_num_uses	4
secret_id_ttl     	600
token_max_ttl     	1800
token_num_uses    	3
token_ttl         	1200

#获取role-id
➜  vault git:(master) ✗ vault read auth/approle/role/demo-role/role-id
Key    	Value
---    	-----
role_id	e6acd222-9dc0-80f8-b8b3-728cc2f09df3
#为保证role-id的机密性，可以使用response wrapping特性来获取
➜  vault git:(master) ✗ vault read -wrap-ttl=50 auth/approle/role/demo-role/role-id
Key                          	Value
---                          	-----
wrapping_token:              	dc729e29-f4d5-9e57-24d7-4979d2de54dc
wrapping_token_ttl:          	50s
wrapping_token_creation_time:	2017-08-03 16:47:31.890395205 +0800 CST
➜  vault git:(master) ✗ vault unwrap dc729e29-f4d5-9e57-24d7-4979d2de54dc
Key    	Value
---    	-----
role_id	e6acd222-9dc0-80f8-b8b3-728cc2f09df3

#获取SecretID，同样可以使用response wrapping特性，此处省略
➜  vault git:(master) ✗ vault write -f auth/approle/role/demo-role/secret-id
Key               	Value
---               	-----
secret_id         	d3f47b60-b51f-8d41-0fd6-d87203c0ce32
secret_id_accessor	49478b25-58e1-ff06-153f-067c29f34917

#新开一个终端测试新的role-id和secret-id
➜  vault git:(master) ✗ vault write auth/approle/login role_id=e6acd222-9dc0-80f8-b8b3-728cc2f09df3 secret_id=f6b24bb0-d5b7-bd1b-5a69-a04782e443cb
Key            	Value
---            	-----
token          	337be25d-7754-5018-7520-9b62f308ad2f
token_accessor 	1b7dacad-1613-9941-0e9c-73e693466ead
token_duration 	20m0s
token_renewable	true
token_policies 	[default demo-policy]
#拿到token后认证并获取secret/demo_api的数据，根据创建demo-role时的配置，该token在20分钟或使用3次后失效
➜  vault git:(master) ✗ curl -H X-Vault-Token:bd7edde3-da0c-599a-030a-caee9bb86bfd  http://localhost:8200/v1/secret/demo_api
{"request_id":"3ab6bd31-50fe-a967-6445-d0ba0a4587b4","lease_id":"","renewable":false,"lease_duration":2764800,"data":{"token":"this_is_api_token","url":"http://api.demo.com"},"wrap_info":null,"warnings":null,"auth":null}

#根据secret-id-accessort查询secret-id情况
➜  vault git:(master) ✗ curl -X "POST" "http://127.0.0.1:8200/v1/auth/approle/role/demo-role/secret-id-accessor/lookup" \
     -H "X-Vault-Token: 831fdf18-4f67-3b7c-8937-638a29f137e9" \
     -d $'{
  "secret_id_accessor": "7a2ebf58-2aaa-f86f-b74e-a4084a375600"
}'

{"request_id":"7104cfa4-c108-a1a8-ae8d-b1437d2cce5c","lease_id":"","renewable":false,"lease_duration":0,"data":{"SecretIDNumUses":0,"cidr_list":[],"creation_time":"2017-08-03T18:00:49.527774493+08:00","expiration_time":"2017-08-03T18:10:49.527774493+08:00","last_updated_time":"2017-08-03T18:00:49.527774493+08:00","metadata":{},"secret_id_accessor":"7a2ebf58-2aaa-f86f-b74e-a4084a375600","secret_id_num_uses":4,"secret_id_ttl":600},"wrap_info":null,"warnings":["The field SecretIDNumUses is deprecated and will be removed in a future release; refer to secret_id_num_uses instead"],"auth":null}

#查询secret-id列表
➜  vault git:(master) ✗ curl "http://127.0.0.1:8200/v1/auth/approle/role/demo-role/secret-id?list=true" \
     -H "X-Vault-Token: 831fdf18-4f67-3b7c-8937-638a29f137e9"
{"request_id":"59877ba0-afb0-f2e4-a6aa-b8785fb6f427","lease_id":"","renewable":false,"lease_duration":0,"data":{"keys":["b2827fd6-81de-72de-439d-e3044adac2f2","58392d25-ceb1-1d2f-0f3b-92f27b431f50","95d47302-b159-8d63-a1f7-83908fcc63a7","bf28809d-9d97-a15e-3079-dd3d65a88d31","389a9122-8366-f44e-ada6-ddf4e94ffaa6","ca5e07cb-988b-0e7c-7401-20e36d088e41"]},"wrap_info":null,"warnings":null,"auth":null}

#撤销secret-id
curl -X "POST" "http://127.0.0.1:8200/v1/auth/approle/role/demo-role/secret-id-accessor/destroy" \
     -H "X-Vault-Token: 831fdf18-4f67-3b7c-8937-638a29f137e9" \
     -d $'{
  "secret_id_accessor": "353bd028-8088-1631-1055-69291d719560"
}'

```



## databases机密模块

```shell
#启用databases模块
➜  vault git:(master) ✗ vault mount database
Successfully mounted 'database' at 'database'!
#配置mysql插件，注意替换password为真正的密码
➜  vault git:(master) ✗ vault write database/config/mysql plugin_name=mysql-database-plugin connection_url="root:password@tcp(127.0.0.1:3306)/" allowed_roles="readonly"


The following warnings were returned from the Vault server:
* Read access to this endpoint should be controlled via ACLs as it will return the connection details as is, including passwords, if any.
#配置role
➜  vault git:(master) ✗ vault write database/roles/readonly db_name=mysql creation_statements="create user '{{name}}'@'%' identified by '{{password}}'; grant select on *.* to '{{name}}'@'%';" default_ttl="1h"
Success! Data written to: database/roles/readonly
#获取一个账号
➜  vault git:(master) ✗ vault read database/creds/readonly
Key            	Value
---            	-----
lease_id       	database/creds/readonly/a087901a-8149-77f9-07dc-67773c9d9c72
lease_duration 	1h0m0s
lease_renewable	true
password       	bc49e512-975a-94b2-4fa8-fddba0a7a527
username       	v-root-readonly-QbqYwRIkzjazZ5jc
#拿到的账号在1小时内有效，到期后该账号会被删除，但已建立的连接不会被断开，可以继续使用
```

## cubbyhole机密模块

每个token在cubbyhole都有各自的作用域，且只能操作自己作用域内的数据，一旦对应的token被销毁则对应的数据也将被销毁。

vault官方曾在一篇博文[^3]里介绍了一种基于cubbyhole来分发临时/永久token对以便应用程序获取诸如数据库密码、api token之类的方案，旨在解决直接将可以获取机密的token配置在环境变量或配置文件易泄密的问题，具体流程如下：

1. 生成一个永久token，该token可以访问应用程序需要的机密数据，如数据库密码、api token等，并附加相关安全策略
2. 生成一个临时token，指定有效期和有效使用次数(4次，认证消耗2次，写入读取各消耗1次)，将步骤1生成的永久token写入该token的cubbyhole
3. 分发步骤2生成的临时token给目标应用程序，目标应用程序认证并获取到永久token，然后再通过该永久token获取最终需要的机密数据(数据库密码、api token等)

文章还讨论了三种实现方案(push/pull/coprocesses)的优劣，但最根本的是这个方案需要开发一套token分发程序来进行分发，而后的vault 0.6版新增加的Response Wrapping特性[^4]则直接给出了一个push方案的实现，下面是使用示例：

```shell
#假设我们把把程序api token存储在了secret/demo_api下
➜  vault git:(master) ✗ vault read secret/demo_api
Key             	Value
---             	-----
refresh_interval	768h0m0s
token           	this_is_api_token
url             	http://api.demo.com
#并配置了demo-policy策略限制了对该机密的访问权限
➜  vault git:(master) ✗ vault read sys/policy/demo-policy
Key  	Value
---  	-----
name 	demo-policy
rules	# allow read secret/demo*
path "secret/demo*" {
    capabilities = ["read"]
}
#包装一个对secret/demo_api的读取访问，限制其生成的token有效期为60秒
➜  vault git:(master) ✗ vault read -wrap-ttl=60 secret/demo_api
Key                          	Value
---                          	-----
wrapping_token:              	b8f75ec5-f431-d434-6a1a-2dea982925b1
wrapping_token_ttl:          	1m0s
wrapping_token_creation_time:	2017-08-01 21:08:04.786250331 +0800 CST
#在60秒内进行unwrap操作即可得到对应的机密数据
➜  vault git:(master) ✗ vault unwrap b8f75ec5-f431-d434-6a1a-2dea982925b1
Key             	Value
---             	-----
refresh_interval	768h0m0s
token           	this_is_api_token
url             	http://api.demo.com
#尝试第二次访问时将直接提示token无效
➜  vault git:(master) ✗ vault unwrap b8f75ec5-f431-d434-6a1a-2dea982925b1
Error making API request.

URL: PUT http://127.0.0.1:8200/v1/sys/wrapping/unwrap
Code: 400. Errors:

* wrapping token is not valid or does not exist
#下面展示的是生成了一个6秒有效期，并在6秒后unwrap的情况，也是提示token无效
➜  vault git:(master) ✗ vault read -wrap-ttl=6 secret/demo_api
Key                          	Value
---                          	-----
wrapping_token:              	ac4f4e56-d817-d1c3-5ac7-d14107e72028
wrapping_token_ttl:          	6s
wrapping_token_creation_time:	2017-08-01 21:08:56.199920409 +0800 CST
➜  vault git:(master) ✗ vault unwrap ac4f4e56-d817-d1c3-5ac7-d14107e72028
Error making API request.

URL: PUT http://127.0.0.1:8200/v1/sys/wrapping/unwrap
Code: 400. Errors:

* wrapping token is not valid or does not exist
```



## 参考


[^1]: https://sreeninet.wordpress.com/2016/10/01/vault-overview/
[^2]: https://sreeninet.wordpress.com/2016/10/01/vault-use-cases/
[^3]: https://www.hashicorp.com/blog/cubbyhole-authentication-principles/
[^4]: https://www.hashicorp.com/blog/vault-0-6/
[^5]: https://www.vaultproject.io/docs/concepts/pgp-gpg-keybase.html
[^6]: http://chairnerd.seatgeek.com/practical-vault-usage/