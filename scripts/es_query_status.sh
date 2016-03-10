#!/bin/sh
#
# 从 ES 里查询统计故障返回码
#

#env
export PATH="/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin"

#variables
readonly DT2="date '+%Y-%m-%d %H:%M:%S'"
readonly localkey=$(date '+%Y-%m-%d'|tr -d '\n'|md5sum|cut -d ' ' -f 1)

# 检查输入参数
if test -z "$2" || test $1 -lt 200 || test $2 -le 0 ;then
	echo "usage: $0 http_satus threshold"
	exit
else
	# 要查询的状态码
	readonly http_status="$1"
	# 次数阀值
	readonly threshold="$2"
fi

# 查询条件:最近1小时内,status:>=500的请求的数量,按域名和状态码等...分组
readonly query_str="
{
    \"query\": {
        \"filtered\": {
            \"query\": {
                \"query_string\": {
                    \"query\": \"status:>=500\",
                    \"analyze_wildcard\": true
                }
            },
            \"filter\": {
                \"bool\": {
                    \"must\": [
                        {
                            \"range\": {
                                \"@timestamp\": {
                                    \"gte\": $(date -d '-1 hour' +%s000),
                                    \"lte\": $(date +%s000) 
                                }
                            }
                        }
                    ],
                    \"must_not\": []
                }
            }
        }
    },
    \"size\": 0,
    \"aggs\": {
        \"2\": {
            \"terms\": {
                \"field\": \"domain_name.raw\",
                \"size\": 20,
                \"order\": {
                    \"_count\": \"desc\"
                }
            },
            \"aggs\": {
                \"14\": {
                    \"terms\": {
                        \"field\": \"status\",
                        \"size\": 20,
                        \"order\": {
                            \"_count\": \"desc\"
                        }
                    },
                    \"aggs\": {
                        \"9\": {
                            \"cardinality\": {
                                \"field\": \"cookie___URM_UID__.raw\"
                            }
                        },
                        \"10\": {
                            \"cardinality\": {
                                \"field\": \"cookie_phpsessid.raw\"
                            }
                        },
                        \"12\": {
                            \"cardinality\": {
                                \"field\": \"http_x_forwarded_for.raw\"
                            }
                        },
                        \"15\": {
                            \"cardinality\": {
                                \"field\": \"remote_addr.raw\"
                            }
                        },
                        \"16\": {
                            \"cardinality\": {
                                \"field\": \"upstream_addr.raw\"
                            }
                        }
                    }
                }
            }
        }
    }
}
"

# 查询条件:最近1小时内,status:=503的请求的数量,按域名和状态码分组
readonly query_str2="
{
    \"query\": {
        \"filtered\": {
            \"query\": {
                \"query_string\": {
                    \"query\": \"status:503\",
                    \"analyze_wildcard\": true
                }
            },
            \"filter\": {
                \"bool\": {
                    \"must\": [
                        {
                            \"range\": {
                                \"@timestamp\": {
                                    \"gte\": $(date -d '-1 hour' +%s000),
                                    \"lte\": $(date +%s000) 
                                }
                            }
                        }
                    ],
                    \"must_not\": []
                }
            }
        }
    },
    \"size\": 0,
    \"aggs\": {
        \"2\": {
            \"terms\": {
                \"field\": \"domain_name.raw\",
                \"size\": 20,
                \"order\": {
                    \"_count\": \"desc\"
                }
            },
            \"aggs\": {
                \"14\": {
                    \"terms\": {
                        \"field\": \"status\",
                        \"size\": 20,
                        \"order\": {
                            \"_count\": \"desc\"
                        }
                    }
                }
            }
        }
    }
}
"

# 查询条件:最近1小时内,status:=503的请求的数量,按域名分组
readonly query_str3="
{
    \"query\": {
        \"filtered\": {
            \"query\": {
                \"query_string\": {
                    \"query\": \"status:${http_status}\",
                    \"analyze_wildcard\": true
                }
            },
            \"filter\": {
                \"bool\": {
                    \"must\": [
                        {
                            \"range\": {
                                \"@timestamp\": {
                                    \"gte\": $(date -d '-12 hour' +%s000),
                                    \"lte\": $(date +%s000) 
                                }
                            }
                        }
                    ],
                    \"must_not\": []
                }
            }
        }
    },
    \"size\": 0,
    \"aggs\": {
        \"2\": {
            \"terms\": {
                \"field\": \"domain_name.raw\",
                \"size\": 20,
                \"order\": {
                    \"_count\": \"desc\"
                }
            }
        }
    }
}
"

# ES接口
readonly ES_URI='http://10.0.0.23:9200/_search'

# 查询获取结果
query_result=$(
	/usr/bin/curl \
		-m 10 \
		-s \
		-d "${query_str3}" \
		${ES_URI} 2>&1
	)

# 解析查询结果
message=''	# 域名:返回码个数
status_sum=0	# 返回码总计个数
#set -x
while read domain_name status_number ;do
	if [ ${status_number:-0} -ge 1 ];then
		message="${message}${domain_name}:${status_number},"
		status_sum=$((${status_sum}+${status_number}))
	fi
done <<EOF
$(echo ${query_result} \
| php -r "\$a = json_decode(file_get_contents('php://stdin'));print_r(\$a->aggregations);" \
| grep -A 1 '\[key\]'|sed 's/.*>//'| tr -d '\n' |sed 's/--/\n/g' )
EOF

# 输出返回码总计个数
echo $status_sum

#如果返回码总计个数超过阀值,发送邮件报警
if [ $status_sum -ge $threshold ];then
	to_list="willwan@icatholic.net.cn"; [ $http_status -eq 503 ] && to_list="willwan@icatholic.net.cn,dkding@icatholic.net.cn,youngyang@icatholic.net.cn"
	subject="最近1小时内,共发生${status_sum}次状态码为${http_status}的请求"
	content="${message}"
	#content=$(echo -e "${content}")
	#echo $content
	#set -x
	echo "${localkey}" sendemail "${to_list}" "${subject}" "${content%,*}" | /usr/bin/gearman -h 10.0.0.200 -f CommonWorker_10.0.0.200 -b
	#set +x
fi
#set +x
