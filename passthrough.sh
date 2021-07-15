#!/usr/bin/env bash

if [[ $# -ne 2 ]]; then
	echo >&2 "Usage: `basename $0` DIR MNTPT"
	exit 1
fi

rootdir="$(readlink -f "$1")"
mntpt="$2"

. ./booze.sh

set -u
shopt -s nullglob
shopt -s dotglob

dostat()
{
	local st ino mode rest
	st=$(stat -c '%i 0x%f %h %u %g %d %s %b %X %Y %Z' "$1") || return 1
	read ino mode rest <<<"$st"
	printf '%d %o %s\n' $ino $mode "$rest"
}

pt_fallocate(){ echo "pt_fallocate($@)"; }
pt_fsync(){ echo "pt_fsync($@)"; }
pt_getxattr(){ echo "pt_getxattr($@)"; }
pt_listxattr(){ echo "pt_listxattr($@)"; }
pt_release(){ echo "pt_release($@)"; }
pt_removexattr(){ echo "pt_fallocate($@)"; }
pt_setxattr(){ echo "pt_setxattr($@)"; }

pt_setattr()
{
	echo "pt_setattr($@)"
	return 0
}

pt_getattr()
{
	echo "pt_getattr($@)"
	[[ -e "$rootdir/$1" ]] || { booze_err=-$ENOENT; return 1; }
	booze_out=`dostat "$rootdir/$1"`
}

pt_access()
{
	echo "pt_access($@)"
	[[ -e "$rootdir/$1" ]] || { booze_err=-$ENOENT; echo returning 1; return 1; }
	[[ "$2" == "$F_OK" ]] && echo returning 0 && return 0

	if { [[ "$(($2 & $R_OK))" -ne 0 ]] && ! [[ -r "$rootdir/$1" ]]; } ||
		{ [[ "$(($2 & $W_OK))" -ne 0 ]] && ! [[ -w "$rootdir/$1" ]]; } ||
		{ [[ "$(($2 & $X_OK))" -ne 0 ]] && ! [[ -x "$rootdir/$1" ]]; }; then
		booze_err=-$EACCES
		echo returning 1; return 1
	else
		echo returning 0 && return 0
	fi
}

pt_readlink()
{
	echo "pt_readlink($@)"
	[[ -e "$rootdir/$1" ]] || { booze_err=-$ENOENT; return 1; }

	[[ -L "$rootdir/$1" ]] || { booze_err=-$EINVAL; return 1; }
	booze_out="$(readlink "$rootdir/$1")"
	return $?
}

pt_readdir()
{
	echo "pt_readdir($@)"
	[[ -e "$rootdir/$1" ]] || { booze_err=-$ENOENT; return 1; }
	[[ -d "$rootdir/$1" ]] || { booze_err=-$ENOTDIR; return 1; }
	booze_out="./.."
	# try to handle weird filenames correctly
	local prefix="$rootdir/$1/"
	for p in "$prefix"*; do
		booze_out+="/${p#$prefix}"
	done
	return 0
}

pt_mknod()
{
	echo "pt_mknod($@)"
	local perms=`printf %o $(($2 & 07777))`

	if S_ISREG $2; then
		[[ -e "$rootdir/$1" ]] && { booze_err=-$EEXIST; return 1; }
		touch "$rootdir/$1" &&  chmod $perms "$rootdir/$1"
		return
	elif S_ISFIFO $2; then
		mkfifo -m $perms "$rootdir/$1"
		return
	else
		booze_err=-$EOPNOTSUPP
		return 1
	fi
}

pt_mkdir() { echo "pt_mkdir($@)"; mkdir -m `printf %o $2` "$rootdir/$1"; }
pt_unlink() { echo "pt_unlink($@)"; rm -f "$rootdir/$1"; }
pt_rmdir() { echo "pt_rmdir($@)"; rmdir "$rootdir/$1"; }
pt_symlink() { echo "pt_symlink($@)"; ln -sn "$rootdir/$1" "$2"; }
pt_rename() { echo "pt_rename($@)"; mv -f "$rootdir/$1" "$rootdir/$2"; }
pt_link() { echo "pt_link($@)"; ln -n "$rootdir/$1" "$rootdir/$2"; }
pt_chmod() { echo "pt_chmod($@)"; chmod `printf %o $(($2 & 07777))` "$rootdir/$1"; }
pt_chown() { echo "pt_chown($@)"; chown -h $2:$3 "$rootdir/$1"; }
pt_truncate() { echo "pt_truncate($@)"; truncate -s $2 "$rootdir/$1"; }
pt_utimens() { echo "pt_utimens($@)"; touch -h -d @$2 "$rootdir/$1" && touch -h -d @$3 "$rootdir/$1"; }

pt_open()
{
	echo "pt_open($@)"
	return 0
	if ! [[ -e "$rootdir/$1" ]]; then
		echo "! -e rootdir/1"
		echo pt_open with: $2 & $O_CREAT "$(($2 & $O_CREAT))"
		if [[ "$(($2 & $O_CREAT))" -ne 0 ]]; then
			touch "$rootdir/$1"
		else
			booze_err=-$ENOENT
			return 1
		fi
	fi
	echo pt_open with: $2 and $O_TRUNC "$(($2 & $O_TRUNC))"
	if [[ "$(($2 & $O_TRUNC))" -ne 0 ]]; then
		> "$rootdir/$1"
	fi
	return 0
}

pt_read()
{
	echo "pt_read($@)" >2
	dd if="$rootdir/$1" bs=1 count=$2 skip=$3
	return 0
}

pt_write()
{
	echo "pt_write($@)"
	dd of="$rootdir/$1" bs=1 count=$2 seek=$3 || {
		booze_err=-$EIO
		booze_out=-$EIO
		return 1
	}
	booze_out="$2"
	return 0
}

pt_statfs() { echo "pt_statfs($@)"; booze_out="$(stat -L -f "$rootdir" -c "%S %b %f %a %c %d 2")"; }

declare -A passthrough_ops

for name in ${BOOZE_CALL_NAMES[@]}; do
	if [[ "`type -t pt_$name`" == "function" ]]; then
		passthrough_ops[$name]=pt_$name
	fi
done

# pt_access three; echo $?
# pt_access fake; echo $?
# pt_access two; echo $?
set -x
booze -d passthrough_ops "$mntpt"
