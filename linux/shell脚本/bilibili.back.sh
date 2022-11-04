#!/usr/bin/bash
# 获取bi站视频下载地址
SESSDATA='c2b0567a%2C1616718422%2C37486*91'
if [ $2 ]; then
    SESSDATA=$2
fi

# 获取aid cid 10 18
getaidcid() {
    getAllaidcidUrl="https://api.bilibili.com/x/web-interface/view?bvid="$1
    echo $getAllaidcidurl
    all=$(curl ${getAllaidcidUrl})
    aid=$(jq -n "${all}" | jq .data.aid)
    pages=$(jq -n "${all}" | jq .data.pages)
    length=$(jq -n "${pages}" | jq '. | length')

    aidcidname="{ \"aid\":${aid},\"cids\":["
    i=0
    while ((${i} < ${length})); do
        page=$(jq -n "${pages}" | jq .[${i}])
        echo ${page}
        cid=$(jq -n "${page}" | jq .cid)
        name=$(jq -n "${page}" | jq .part)

        if [ i==${length} ]; then
            aidcidname=${aidcidname}"{\"cid\":${cid},\"name\":${name}}"
        else
            aidcidname=${aidcidname}"{\"cid\":${cid},\"name\":${name}},"
        fi
        echo ${name} ${cid}
        let i++
    done
    aidcidname=${aidcidname}"]}"
    echo $aidcidname
    return 0
}

# 获取一个下载地址 1aid  2cid 3sessdata
getone() {
    if [ $1 -a $2 ]; then
        url="https://api.bilibili.com/x/player/playurl?avid=$1&cid=$2&qn=80"
         #curl -b "SESSDATA":"c2b0567a%2C1616718422%2C37486*91" "https://api.bilibili.com/x/player/playurl?avid=330238687&cid=254893805&qn=80"
        down=$(curl -b "SESSDATA":"${SESSDATA}" "${url}")
        data=$(jq -n "${down}" | jq .data | jq .durl)
        myurl=$(jq -n "${data}" | jq .[0] | jq .url)
        echo ${myurl}      
        return 0
    fi
}

#获取所有的下载地址 bv
getall() {
    #循环的次数,调用方法获取aidcid
    data=$(getaidcid $1)
    datalength=$(jq -n "${data}" | jq .cids | jq '. | length')
    aid=$(jq -n "${data}" | jq .aid)
    cids=$(jq -n "${data}" | jq .cids)
    resultstr="{\"aid\":${aid},"
    i=1
    while [ ${i} -lt ${datalength} ]; do
        onecidname=$(jq -n "${cids}" | jq .[${i}])
        onecid=$(jq -n "${cads}" | jq .cid)
        onename=$(jq -n "${cads}" | jq .name)

        oneurl=$(getone "$aid" "$onecid")

        if [ i==${datalength} ]; then
            resultst=${resultst}"{\"cid\":${onecid},\"name\":${onename},\"url\":${oneurl}}"
        else
            resultst=${resultst}"{\"cid\":${onecid},\"name\":${onename},\"url\":${oneurl}},"
        fi
        let i++
    done

    resultstr=${resultstr}']}'

    echo ${resultstr}

}

if [ $1 ]; then
    getall "$1"
else
    echo '请输入bv'
fi
