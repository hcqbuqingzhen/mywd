all=` curl https://api.bilibili.com/x/web-interface/view?bvid=BV1Af4y117ZK`
echo $all
aid=` jq -n "${all}" |jq .data.aid `
pages=`jq -n "${all}" |jq .data.pages `
length=`jq -n "${pages}" | jq '. | length' ` 
aidcidname="{ \"aid\":${aid},\"cids\":["
    i=0
    while(( ${i}<10 )) 
    do
        
        page=`jq -n "${pages}" | jq .[${i}] `
        echo ${page}
        cid=`jq -n "${page}" | jq .cid`
        name=`jq -n "${page}" | jq .part`
        	
	if [ $i == 9 ]
            then
            aidcidname=${aidcidname}"{\"cid\":${cid},\"name\":${name}}"
	else
	    aidcidname=${aidcidname}"{ \"cid\":${cid},\"name\":${name} },"
	fi
	let i++
        echo ${name} ${cid}
    done
    aidcidname=${aidcidname}" ] }"
    echo $aidcidname
    jq -n "${aidcidname}"
#echo ${a}
echo ${length}

