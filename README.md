# 带有nginx-headers-more的nginx镜像

## 构建镜像
docker build -t  zerowgd/nginx:1.22.1-alpine  .

## 推送镜像
以docker hub为例：
1. 登录
``` shell
docker login --username=zerowgd
```
2. 推送镜像
``` shell
docker push zerowgd/nginx:1.22.1-alpine  
```