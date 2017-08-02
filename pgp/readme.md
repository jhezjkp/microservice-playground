# pgp

## 下载安装

到[gnupg官网](https://www.gnupg.org/download/index.en.html)下载安装即可。

## 生成密钥

使用pgp --gen-key密码，按提示输入名字和email及一段口令即可生成，记得把口令记录下来，导出私钥、解密时会用到。

```shell
➜  ~ gpg --gen-key
gpg (GnuPG) 2.1.22; Copyright (C) 2017 Free Software Foundation, Inc.
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Note: Use "gpg --full-generate-key" for a full featured key generation dialog.

GnuPG needs to construct a user ID to identify your key.

Real name: Gorge Jiang
Email address: jhezjkp@163.com
You selected this USER-ID:
    "Gorge Jiang <jhezjkp@163.com>"

Change (N)ame, (E)mail, or (O)kay/(Q)uit? O
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
We need to generate a lot of random bytes. It is a good idea to perform
some other action (type on the keyboard, move the mouse, utilize the
disks) during the prime generation; this gives the random number
generator a better chance to gain enough entropy.
gpg: /Users/vivia/.gnupg/trustdb.gpg: trustdb created
gpg: key B7BE4C54223F9907 marked as ultimately trusted
gpg: directory '/Users/vivia/.gnupg/openpgp-revocs.d' created
gpg: revocation certificate stored as '/Users/vivia/.gnupg/openpgp-revocs.d/2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907.rev'
public and secret key created and signed.

pub   rsa2048 2017-08-02 [SC] [expires: 2019-08-02]
      2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907
uid                      Gorge Jiang <jhezjkp@163.com>
sub   rsa2048 2017-08-02 [E] [expires: 2019-08-02]

```

如上所示，我的密钥用户标识是"Gorge Jiang <jhezjkp@163.com>"，对应的用户ID是2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907，这个也是我的公钥指纹。

## 导出并提交公钥

使用gpg --armor --output public-key.txt --export [用户ID]命令即可将公钥文件导出到public-key.txt文件中，打开https://pgp.mit.edu/或https://pgp.key-server.io/，将其中的内容粘贴到“Submit a key“区域的文本区，点击提交即可完成公钥的提交。

同样的，在提交页面上的Search String文件框中输入你的用户ID，并在前面加上"0x"，如"0x2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907"，然后点击"Do the search!"即可查询并下载公钥。

ps1：直接搜索用户标识"Gorge Jiang <jhezjkp@163.com>"也可以找到对应公钥。

ps2：用户标识可以随意定，所以标识某人提并的并不一定就是那个人提交的。通常，你可以在网站上公布一个公钥指纹，让其他人核对下载到的公钥是否为真。

```shell
#导出公钥
➜  ~ gpg --armor --output public-key.txt --export 2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907
```



## 导出私钥

使用gpg --armor --output private-key.txt --export-secret-keys [用户ID]命令，再输入生成密钥时的口令，即可将私钥导出到private.txt中，请妥善保存私钥。

## 导入公钥

拿到其他人的公钥后，需要导入才能使用。

```shell
#假设要导入的公钥是someone.key
➜  ~ gpg --import someone.key
gpg: key 02C7D3F28CFE6E3A: public key "xxx <yyy@zz.com>" imported
gpg: Total number processed: 1
gpg:               imported: 1
#列出目前管理的公钥
➜  ~ gpg --list-keys
/Users/vivia/.gnupg/pubring.kbx
-------------------------------
pub   rsa2048 2017-08-02 [SC] [expires: 2019-08-02]
      2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907
uid           [ultimate] Gorge Jiang <jhezjkp@163.com>
sub   rsa2048 2017-08-02 [E] [expires: 2019-08-02]

pub   dsa1024 2005-09-08 [SC]
      7BD25BC8DD496D44C2EB517802CXXXXXXXXXXXX
uid           [ unknown] xxx <yyy@zz.com>
sub   elg4096 2005-09-08 [E]
```



## 加解密和签名

```shell
#加密
➜  ~ echo 'this is a test.测试数据' | gpg --recipient 223F9907 --encrypt --output encrypt.txt
#解密，需要输入私钥口令
➜  ~ gpg --decrypt encrypt.txt
gpg: encrypted with 2048-bit RSA key, ID 5A810E31E1DAD2FA, created 2017-08-02
      "Gorge Jiang <jhezjkp@163.com>"
this is a test.测试数据

#签名
➜  ~ echo "this file is create by Gorge Jiang." >> demo.txt
➜  ~ gpg --sign demo.txt
#将在当前目录下生成demo.txt.gpg文件，这就是签名后的文件，这个文件默认采用二进制储存
#验证签名
➜  ~ gpg --verify demo.txt.gpg
gpg: Signature made 三  8/ 2 16:22:28 2017 CST
gpg:                using RSA key 2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907
gpg: Good signature from "Gorge Jiang <jhezjkp@163.com>" [ultimate]

#明文签名
➜  ~ gpg --clearsign demo.txt
#将在当前目录下生成demo.txt.asc，签名内包含内容
➜  ~ cat demo.txt.asc
-----BEGIN PGP SIGNED MESSAGE-----
Hash: SHA256

this file is create by Gorge Jiang.
-----BEGIN PGP SIGNATURE-----

iQEzBAEBCAAdFiEEKqrvT1zp2TFUyCM7t75MVCI/mQcFAlmBjGkACgkQt75MVCI/
mQcBBwf+PWjT/0nQFn+V78pUzBsRk3FUDdbr+CE+jIDcwVxPyzJFAYbn/NLP0hKu
obWRJ1Kf1hcC32rfHGhLJI7LUEvZB2ctLTa+Fa/j3cQXJBdJoziSxk3XnEwKEqPE
ZK4IAP34XvF38zPukyzEpgBZkW1P5ovR4O8heksDnkHlUXQl7HPp2UeYMmKVueKS
n6HDtnKyGtqCO64J0pGdAS5L2XqHX1PopZ+fZoBam2OM3YZwyHhJJr5OYS6SgwhL
8m3JSbvnKkXJJFZxLaTi/cOHhH14qvIrDq2wTkzQRfz1U4yDFm8JsOl3UlLn8Stf
tE7ZDtVJ6sBFaan7b5MgkLPu2uXXCQ==
=IyDC
-----END PGP SIGNATURE-----
#验证签名
➜  ~ gpg --verify demo.txt.asc
gpg: Signature made 三  8/ 2 16:25:13 2017 CST
gpg:                using RSA key 2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907
gpg: Good signature from "Gorge Jiang <jhezjkp@163.com>" [ultimate]
gpg: WARNING: not a detached signature; file 'demo.txt' was NOT verified!

#将签名文件单独存放的签名，加--armor参数是让签名文件ascii转码输出，否则将是一个二进制签名
➜  ~ gpg --armor --detach-sign demo.txt
➜  ~ cat demo.txt.asc
-----BEGIN PGP SIGNATURE-----

iQEzBAABCAAdFiEEKqrvT1zp2TFUyCM7t75MVCI/mQcFAlmBjXgACgkQt75MVCI/
mQdVsQf9HnKCl5OjPXW1aAqbGK8yk2ZGxC5vnXYgjY4vmCCtsOI7Lj6weU6qXbo6
D90fWo0EbMdp9tDXMrABiD6ZQPENx1M4spgYHkLPuglS03j2nDxnnuU3+JcIhB1f
g24s2c+hX3+6xWr9HUEtGOY/SyGfECbyH5kMfA0/fMABzQl22k8M74x1Anf/x8jw
nHGBm/jJzslM45c1eFl/8FHutQLZ969LzPQAMKTtiHxxmCLxNnM9Aot4Itr2dzHK
FfKM10P3YIA70d7DSeOuLaKLSPRiNbDnr3DMooIbq4oFWrd2arfJvy5qozGa52yH
9W90c+ROAj7sXa6VJlOFSI1lVI3YSg==
=emJf
-----END PGP SIGNATURE-----
#验证签名
➜  ~ gpg --verify demo.txt.asc demo.txt
gpg: Signature made 三  8/ 2 16:29:44 2017 CST
gpg:                using RSA key 2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907
gpg: Good signature from "Gorge Jiang <jhezjkp@163.com>" [ultimate]

#加密并签名
#格式：gpg --local-user [发信者ID] --recipient [接收者ID] --armor --sign --encrypt demo.txt
#ps：需要输入密钥口令
➜  ~ gpg --local-user 24A4F63A2F03AA013C722EC3FA9FDABAE43E2218 --recipient 2AAAEF4F5CE9D93154C8233BB7BE4C54223F9907 --armor --sign --encrypt demo.txt
➜  ~ gpg --verify demo.txt.asc
gpg: verify signatures failed: Unexpected error
➜  ~ cat demo.txt.asc
-----BEGIN PGP MESSAGE-----

hQEMA1qBDjHh2tL6AQf9EUZyURrdIYBfHo58rPL2j/7UwEyf0EzI+DSlxPsRj3WF
sqLCGWU3IchyWT/rqyuSjs1YCNtguanXkbwsIOrcfp7b02casg6ZVKAOMfII5XUA
bIyWtltfW2qc4Elh+1DqM3fAZbux/gldlfut7lu8iPkaLf++sSlm8ZTSzoCv01fI
C2URwSOWLiogQzD4pobPQISyUjv/etTkamk9oVVaVngQ0byanYOGmnunRZWWy0Iz
xp0ybBO1boiBP43cnNLewHCAgGKNW7sQTyE/H732sxmnSGTEN2YLao4ipYOMneno
uk7sv8+2+5R/7J6B3ULQZOtgwZNaE8UWmheag+Mjg9LA7AF6PjGVoV3TrVycLnNX
S77UE9NuIe5SSXEpjwTn68dHzwjC6wWo/k4Q5CQhL9oidXFeEGvH+vBQHv5QI3gO
8VR/ve1NV9/wJVEQHwxFLsQi1FJf7fMy9kDsEwmDjmF66tj9BNSwHsOfWaxsAc0V
fFH/LCzIM5I1XF7kc05aVlbva6lJWswXvvEPusEV4uHt8+k+h7IRTJ1oJC1f1nXI
46Ozy9h1YU3tQT6WmD7IuoU+mZQ7r2igRvfJKQOEIv7mpmZWGwSdcahF5jHD0Xs8
oPsulPQzPyI/tM/4eAeKod5G7kEh5McGBDyb7R9oNSpV+DyKLmrTlFizSFiOHOAx
P/453MquaEyZ7Z6KofwhUEiB0ynPOTWce2+H6AfgwUiW94cDLcBllI7icUQkHkJa
VoG3DbKGN3oCvPKZgHkUejL8QsvnLEj1s3YIDJrq+f+CsZ06Tb3DGeE4XOEX0peB
SMtAgvgPHV9dsMvjfjFmCSTUxuAAb0y9gMjcAONfZ8JhvwErkC+SnAFJKvuO9dne
kwGEHscVHCsKqiTQWwgU8fLz6SHjqvahKHUHULGU
=fRwL
-----END PGP MESSAGE-----
#解密并验证签名
➜  ~ gpg --decrypt demo.txt.asc
gpg: encrypted with 2048-bit RSA key, ID 5A810E31E1DAD2FA, created 2017-08-02
      "Gorge Jiang <jhezjkp@163.com>"
this file is create by Gorge Jiang.
gpg: Signature made 三  8/ 2 17:22:57 2017 CST
gpg:                using RSA key 24A4F63A2F03AA013C722EC3FA9FDABAE43E2218
gpg: Good signature from "testPGP <testPGP@unknown.com>" [ultimate]
```

