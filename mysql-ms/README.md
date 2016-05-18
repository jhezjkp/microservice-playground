# MySQL主从复制

## 1.启动实例

```shell
docker-compose up -d
```

## 2.在主库上创建MySQL账号：

进入主库容器：

```shell
docker exec -it master bash
```

使用root/123456连接数据库并执行以下命令：

```mysql
grant replication slave on *.* to 'slave'@'%' identified by 'slave_123456';
```

## 3.在从库上设置主库：

进入从库容器：

```shell
docker exec -it slave bash
```

使用root/123456连接数据库并执行以下命令：

```mysql
change master to master_host='master', master_user='slave', master_password='slave_123456';
start slave;
```

设置完毕！

