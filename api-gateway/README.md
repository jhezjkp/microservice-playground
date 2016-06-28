# api gateway: Kong

## 两张架构/部署图解析Kong


常规架构：各api服务各自实现自己的认证、限流、日志、缓存等功能模块，带来重复发开、管理烦杂问题。
![常规架构](https://getkong.org/assets/images/homepage/diagram-left.png)

引入Kong后的架构：由Kong统一负责用户认证、日志记录、缓存、限流等，开箱即用、集中管控。
![Kong架构](https://getkong.org/assets/images/homepage/diagram-right.png)

## 实战Kong部署
1、启动相关服务

```shell
docker-compose up
```

ps: 如果kong没有成功启动则再运行一下docker start kong

2、注册api

获取提供微服务的容器IP：

```shell
docker inspect -f '{{ .NetworkSettings.Networks.apigateway_default.IPAddress }}' demo
```

向kong注册api(172.25.0.3为提微供服务的容器IP)：

```shell
curl -i -X POST \
  --url http://localhost:8001/apis/ \
  --data 'name=demo' \
  --data 'upstream_url=http://172.25.0.3:5000/' \
  --data 'request_host=vivia.me'
```

3、测试api调用

case #1:

```shell
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: vivia.me'
```

case #2:

```shell
curl -i -X GET \
  --url http://localhost:8000/info \
  --header 'Host: vivia.me'
```

case #3:

```shell
curl -i -X GET \
  --url http://localhost:8000/echo?param=vivia \
  --header 'Host: vivia.me'
```

4、配置插件

增加一个consumer：

```shell
curl -d "username=common" http://localhost:8001/consumers/
```

给新增加的consumer配置一个credential(用户名demo密码123456)：

```shell
curl -X POST http://localhost:8001/consumers/common/basic-auth \
    --data "username=demo" \
    --data "password=123456"
```

给demo api配置Basic Authentication插件：

```shell
curl -X POST http://localhost:8001/apis/demo/plugins \
    --data "name=basic-auth" \
    --data "config.hide_credentials=true"
```

查看demo api的插件启用情况：

```shell
curl -X "GET" "http://localhost:8001/apis/demo/plugins"
```

测试不提供认证数据情况下能否成功调用：

```shell
curl -i -X GET \
  --url http://localhost:8000/ \
  --header 'Host: vivia.me'
```

测试提供正确认证数据情况下能否成功调用：

```shell
curl -i -X "GET" "http://localhost:8000/" \
	-H "Authorization: Basic ZGVtbzoxMjM0NTY=" \
	-H "Host: vivia.me"
```

ps: 认证数据是在发送之前是以用户名追加一个冒号然后串接上口令，并将得出的结果字符串再用Base64算法编码(echo -n "demo:123456" | base64)





