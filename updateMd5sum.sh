#!/bin/bash
md5sumFile="md5sum.txt"

if [ ! -f $md5sumFile ]; then
    touch $md5sumFile
fi

function log()
{
    local level=$1
    shift
    local msg=$*
    case $level in
            info)   echo -e "[INFO] $msg";;
            note)   echo -e "[NOTE] \033[92m$msg\033[0m";;
            warn)   echo -e "[WARN] \033[93m$msg\033[0m";;
            error)  echo -e "[ERROR] \033[91m$msg\033[0m";;
    esac
}

function usage()
{
    echo "usage: `basename $0` <chk|update> [file.bin|all|outer|inner]"
}

# 检查
function chkRecord()
{
    if [ $# -eq 0 ]; then
        checkAllLocalFilesMd5sum
    else
        checkFileInRecords $1
    fi
}

function checkFileInRecords()
{
    local filename=$1
    grep -vE "^#" $md5sumFile | grep -E "${filename}$"
    if [ $? -ne 0 ]; then
        log warn "$md5sumFile 中尚未有此文件的记录: $filename"
    fi
}

function checkMd5sumInRecords()
{
    log info "检查 $md5sumFile 中的 MD5SUM 记录 :"
    md5sum -c $md5sumFile --quiet
    rs=$?
    if [ $rs -eq 0 ]; then
        log note "已有的记录与本地完全一致"
    fi
    return $rs
}

function checkAllLocalFilesMd5sum()
{
    checkMd5sumInRecords
    rs1=$?

    log info "检查尚未加入记录中的文件的 MD5SUM :"
    rs2=0
    fileList=$(ls *.bin)
    for file in $fileList; do
        grep $file $md5sumFile >/dev/null
        if [ $? -ne 0 ]; then
            md5sum $file
            ((++rs2))
        fi
    done

    t=$(expr $rs1 + $rs2)
    if [ $t -eq 0 ]; then
        log note "不需要更新 $md5sumFile 中的记录"
    else
        log warn "需要更新 $md5sumFile 中的记录"
    fi
} 

# 更新记录
function updateRecord()
{
    case $1 in
        all)   updateAllRecords;;
        inner)  updateInnerRecords;;
        outer)  updateOuterRecords;;
        *)      updateFileRecord $1;;
    esac
}

# 更新一个文件的 MD5sum 记录
function updateFileRecord()
{
    local filename=$1
    if [ "$filename" == "" ]; then
        usage
        exit 1
    fi
    echo $filename | grep -E "*.bin" >/dev/null
    if [ $? -ne 0 ]; then
        log error "错误的文件格式，必须以 .bin 结尾：$filename"
        exit 1
    fi
    if [ ! -f $filename ]; then
        log error "找不到指定的文件：$filename"
        exit 1
    fi
    newRecord=$(md5sum $filename)
    grep -vE "^#" $md5sumFile | grep -E ".*${filename}$" >/dev/null
    if [ $? -eq 0 ]; then
        sed -i "s/^[a-z0-9].*${filename}$/${newRecord}/" $md5sumFile
    else
        echo $newRecord >> $md5sumFile
    fi
    cp $md5sumFile .tmp
    sort .tmp | uniq > $md5sumFile
    log note "$filename - update ok"
}

function updateAllRecords()
{
    local fileList=$(ls *.bin)
    for file in $fileList; do
        updateFileRecord $file
    done
}

function updateInnerRecords()
{
    local fileList=$(grep -vE "^#" $md5sumFile | awk '{print $2}')
    for file in $fileList; do
        updateFileRecord $file
    done
}

function updateOuterRecords()
{
    local innerFileList=$(grep -vE "^#" $md5sumFile | awk '{print $2}')
    local outerFileList=$(ls *.bin)
    local updateFileList=
    for outfile in $outerFileList; do
        isDup=0
        for infile in $innerFileList; do
            if [ "$outfile" == "$infile" ]; then
                isDup=1
                break
            fi
        done
        if [ $isDup -eq 0 ]; then
            updateFileList="$updateFileList $outfile"
        fi
    done
    if [ "$updateFileList" == "" ]; then
        log warn "没有记录需要更新"
        exit 1
    fi
    for file in $updateFileList; do
        updateFileRecord $file
    done

}

case $1 in
    chk)    chkRecord $2;;
    update) updateRecord $2;;
    *)      usage; exit 1;; 
esac
