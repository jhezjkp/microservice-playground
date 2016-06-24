# 使用Terraform来管理基础设施

[Terraform](https://www.terraform.io/)是一个使用配置来管理基础设施的工具，通过配置文件定义企业需要的基础设施，一键构建数据中心。

## 附GCE镜像名

|                NAME                 |     PROJECT     |     FAMILY      | STATUS |
| :---------------------------------: | :-------------: | :-------------: | :----: |
|         centos-6-v20160606          |  centos-cloud   |    centos-6     | READY  |
|         centos-7-v20160606          |  centos-cloud   |    centos-7     | READY  |
|   coreos-alpha-1081-1-0-v20160617   |  coreos-cloud   |  coreos-alpha   | READY  |
|   coreos-beta-1068-2-0-v20160620    |  coreos-cloud   |   coreos-beta   | READY  |
|  coreos-stable-1010-5-0-v20160527   |  coreos-cloud   |  coreos-stable  | READY  |
|      debian-8-jessie-v20160606      |  debian-cloud   |    debian-8     | READY  |
|       opensuse-13-2-v20160222       | opensuse-cloud  |                 | READY  |
|    opensuse-leap-42-1-v20160302     | opensuse-cloud  |                 | READY  |
|          rhel-6-v20160606           |   rhel-cloud    |     rhel-6      | READY  |
|          rhel-7-v20160606           |   rhel-cloud    |     rhel-7      | READY  |
|        sles-11-sp4-v20160301        |   suse-cloud    |                 | READY  |
|        sles-12-sp1-v20160301        |   suse-cloud    |                 | READY  |
|   ubuntu-1204-precise-v20160610a    | ubuntu-os-cloud | ubuntu-1204-lts | READY  |
|    ubuntu-1404-trusty-v20160620     | ubuntu-os-cloud | ubuntu-1404-lts | READY  |
|     ubuntu-1510-wily-v20160610      | ubuntu-os-cloud |   ubuntu-1510   | READY  |
|    ubuntu-1604-xenial-v20160610     | ubuntu-os-cloud | ubuntu-1604-lts | READY  |
| windows-server-2008-r2-dc-v20160502 |  windows-cloud  | windows-2008-r2 | READY  |
| windows-server-2012-r2-dc-v20160502 |  windows-cloud  | windows-2012-r2 | READY  |

获取方法：登录google cloud shell，运行以下命令

```shell
gcloud compute images list
```