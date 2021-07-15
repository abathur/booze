
# A library of sorts providing various facilities for booze
# filesystems.

# enable -f ./booze.so booze

__getmacros() { gcc -E -dD -x c - <<<"#include <$1.h>"; }

# Define all system errno values
eval `__getmacros errno | sed -n -r 's/^#define (E[^ ]+) ([0-9]+)$/\1=\2/p;'`

# Define access(2) mask values
# eval `__getmacros unistd | sed -n -r 's/^#define ([^ ]+_OK) ([0-9]+)$/\1=\2/p;'`
# This doesn't work as expected because the macOS defs have bit shifts:
# INPUT:   'STDIN' line 1397
# PATTERN: #define F_OK 0
# COMMAND: s/^#define ([^ ]+_OK) ([0-9]+)$/\1=\2/p
# MATCHED REGEX REGISTERS
#   regex[0] = 0-14 '#define F_OK 0'
#   regex[1] = 8-12 'F_OK'
#   regex[2] = 13-14 '0'
# F_OK=0
# PATTERN: F_OK=0
# END-OF-CYCLE:
# INPUT:   'STDIN' line 1398
# PATTERN: #define X_OK (1<<0)
# COMMAND: s/^#define ([^ ]+_OK) ([0-9]+)$/\1=\2/p
# PATTERN: #define X_OK (1<<0)
# END-OF-CYCLE:
F_OK=0 X_OK=1 W_OK=2 R_OK=4

# Define O_* open(2) flags
# eval `__getmacros fcntl | sed -n -r 's/^#define (O_[^ ]+) ([0-9]+)$/\1=\2/p;'`
O_RDONLY=0 O_WRONLY=1 O_RDWR=2 O_ACCMODE=3 O_NONBLOCK=4 O_APPEND=8 O_SYNC=80 O_SHLOCK=10 O_EXLOCK=20 O_ASYNC=40 O_FSYNC=$O_SYNC O_NOFOLLOW=100 O_CREAT=200 O_TRUNC=400 O_EXCL=800 O_EVTONLY=8000 O_NOCTTY=20000 O_DIRECTORY=100000 O_SYMLINK=200000 O_DSYNC=400000 O_CLOEXEC=1000000 O_DP_GETRAWENCRYPTED=1 O_DP_GETRAWUNENCRYPTED=2 O_NDELAY=$O_NONBLOCK O_POPUP=80000000 O_ALERT=20000000
# FAPPEND=O_APPEND
# FASYNC=O_ASYNC
# FFSYNC=O_FSYNC
# FFDSYNC=O_DSYNC
# FNONBLOCK=O_NONBLOCK
# FNDELAY=O_NONBLOCK

# Define S_* mode flags
eval `__getmacros sys/stat | sed -n -r 's/^#define (S_[^ ]+) ([0-9]+)$/\1=\2/p;'`

for __t in LNK REG DIR CHR BLK SOCK; do
	eval "S_IS$__t() { [ \"\$((\$1 & \$S_IF$__t))\" -eq \"\$((S_IF$__t))\" ]; }"
done

# This one doesn't fit the S_IS*/S_IF* pattern
S_ISFIFO() { [ "$(($1 & $S_IFIFO))" -eq "$((S_IFIFO))" ]; }

BOOZE_CALL_NAMES=(getattr access readlink readdir mknod mkdir unlink rmdir symlink
	          rename link chmod chown truncate utimens open read write statfs
	          release fsync fallocate setxattr getxattr listxattr removexattr)

# Namespace cleanup
unset -v __t
unset -f __getmacros
