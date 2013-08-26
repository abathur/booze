
. ./booze.sh

booze_getattr()
{
	local now=`date +%s`
	local times="$now $now $now"
	local ids="`id -u` `id -g`"
	if [ "$1" == "/" ]; then
		booze_out="0 $(printf '%o' $((S_IFDIR | 0755))) 2 $ids 0 0 0 $times"
		return 0
	elif [ "$1" == "/booze" ]; then
		booze_out="1 $(printf '%o' $((S_IFREG | 0644))) 1 $ids 0 7 1 $times"
		return 0
	else
		booze_err=-$ENOENT
		return 1
	fi
}

booze_readdir()
{
	booze_out="./../booze"
	return 0
}

booze_open()
{
	if [ "$1" == "/booze" ]; then
		return 0
	else
		booze_err=-$ENOENT
		return 1
	fi
}

data=$'Booze!\n'
booze_read()
{
	if [ "$1" != "/booze" ]; then
		booze_err=-$ENOENT
		return 1
	fi

	local readlen="$2"
	local offset="$3"

	local datalen="${#data}"

	if [ "$offset" -lt "$datalen" ]; then
		if [ "$((offset + readlen))" -gt "$datalen" ]; then
			readlen="$((datalen - offset))"
		fi
		booze_out="${data:offset:readlen}"
	else
		booze_out=""
	fi

	return 0
}

booze "$1"