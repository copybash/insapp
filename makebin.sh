#!/bin/bash

function usage()
{
cat << eof
Usage:  sh `basename $0` inspath app.tar.gz
        sh `basename $0` inspath app/

       inspath - install.sh 文件目录
       srcpath - 源文件根目录或者 tar.gz 文件
eof
}

function log()
{
    local level=$1
    shift
    local msg=$*
    case $level in
        info)   echo -e "$msg";;
        note)   echo -e "\033[92m$msg\033[0m";;
        warn)   echo -e "\033[93m$msg\033[0m";;
        error)  echo -e "\033[91m$msg\033[0m";;
    esac
}

function makebin()
{
    local inspath=$1
    local srcpath=$2

    echo $srcpath | grep -E ".*.tar.gz$" >/dev/null 2>&1
    rs=$?
    if [ $rs -eq 0 ]; then
        if [ ! -f $srcpath ]; then
            log error "该文件不存在：$srcpath"
            exit 1
        fi
    else
        if [ ! -d $srcpath ]; then
            log error "该目录不存在: $srcpath"
            exit 1
        fi
    fi

    if [ ! -z $inspath ] && [ ! -f $inspath ]; then
        log error "该文件不存在：$inspath"
        exit 1
    fi

    local src_base_home=$(dirname $srcpath)
    local src_base_name=$(basename $srcpath)
    local script_base_name=$(basename $inspath)
    cd $src_base_home
    if [ $rs -eq 0 ]; then
        echo "[1/1] 不需要压缩，正在生成可执行二进制文件"
        catall $src_base_name $script_base_name
    else
        echo "[1/2] 正在压缩文件 ..."
        compress $src_base_name
        echo "[2/2] 正在生成可执行二进制文件"
        catall $src_base_name $script_base_name
    fi
}

# 压缩文件 
function compress()
{
    local srcname=$1
    local tarball="${srcname}.tar.gz"
    echo -ne "$tarball\t"
    tar -zcf $tarball $srcname --exclude=".git*" --exclude=".log" --exclude=".out"
    if [ $? -eq 0  ]; then
        log note "成功"
    else
        log error "失败"
        exit 1
    fi
}

# 制作可执行二进制文件 
function catall()
{
    local srcname=$1
    local inspath=$2

    echo $srcname | grep -E ".*.tar.gz$" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        local tarball=$srcname
        local binball=$(echo ${srcname} | sed 's#tar.gz#bin#g')
    else
        local tarball="${srcname}.tar.gz"
        local binball="${srcname}.bin"
    fi

    echo -ne "$binball\t"
    cat $inspath $tarball > $binball
    if [ $? -eq 0 ]; then
        chmod u+x $binball
        log note "成功"
    else
        log error "失败"
    fi
}

################## main ###################
if [ $# -ne 2 ]; then usage; exit 1; fi
makebin $* 

