## 制作 bin 文件

准备 2 个文件：

- app.tar.gz 压缩包
- install.sh 安装脚本，名字随意

或者

- app/ 非压缩包
- install.sh 安装脚本

修改 install.sh

> vim install.sh

```
APP_INSTALL_HOME=/data/app
APP_SOFT_LINK=/usr/local/hbase
```

运行脚本：

> ./makebin.sh app.tar.gz install.sh

或者

> ./makebin.sh app/ install.sh

或者手动生成 bin 文件：

> tar -zcf app.tar.gz app/

> cat install.sh app.tar.gz > app.bin

cat 的时候文件有顺序要求：install.sh 必须在 app.tar.gz 前面

## 把 bin 文件放到合适目录

> mv app.bin /data/www/os/repo/app/packages/

## 更新 MD5SUM 记录

> cd packages/

> ./updateMd5sum.sh update app.bin

查看该 app 的 MD5SUM 记录：

> grep app.bin md5sum.txt

## 配置 nginx

> vim insapp.conf

```
server
{
    listen 10088;
    server_name 192.168.2.26;
    charset utf-8;
    access_log /data/logs/www/nginx/insapp.log ;
    error_log  /data/logs/www/nginx/insapp.err ;
    root /data/www/os/repo/app/;
    client_max_body_size 1024m;

    autoindex on;
    autoindex_exact_size off;
    autoindex_localtime on;
}
```

> nginx -t

> nginx -s reload

## 运行 insapp 进行验证

需要 python2.3 +

修改 insapp 脚本里面的配置

```
HTTP_SERVER = "192.168.2.26:10088"
```

把 insapp 脚本放在 /usr/bin/ 目录

查看 app 文件列表

> sudo insapp -l

安装 app

> sudo insapp -i app
