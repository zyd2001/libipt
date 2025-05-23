#! /bin/bash
#
# Copyright (C) 2015-2025 Intel Corporation
# SPDX-License-Identifier: BSD-3-Clause
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
#  * Redistributions of source code must retain the above copyright notice,
#    this list of conditions and the following disclaimer.
#  * Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
#  * Neither the name of Intel Corporation nor the names of its contributors
#    may be used to endorse or promote products derived from this software
#    without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.

set -e

prog=`basename $0`
master=""
kcore=""
sysroot=""

usage() {
    cat <<EOF
usage: $prog [<options>] <perf.data-file>

Create --pevent options for ptdump and ptxed based on <perf.data-file>
and previously generated <perf.data-file>-sideband*.pevent files.

When tracing ring-0, use perf-with-kcore and supply the path to kcore_dir
using the -k option.

options:
  -h         this text
  -m <file>  set <file> as the master sideband file (current: $master)
  -k <dir>   set the kcore directory to <dir> (current: $kcore)
  -s <dir>   set the sysroot directory to <dir> (current: $sysroot)

<perf.data-file> defaults to perf.data.
EOF
}

while getopts "hm:k:s:" opt; do
    case $opt in
        h)
            usage
            exit 0
            ;;
        m)
            master="$OPTARG"
            ;;
        k)
            kcore="$OPTARG"
            ;;
        s)
            sysroot="$OPTARG"
            ;;
    esac
done

shift $(($OPTIND-1))


if [[ $# == 0 ]]; then
    file="perf.data"
elif [[ $# == 1 ]]; then
    file="$1"
    shift
else
    usage
    exit 1
fi


perf script --header-only -i $file | \
  gawk -F'[ ,]' -- '
    /^# cpuid : /  {
      vendor   = $4
      family   = strtonum($5)
      model    = strtonum($6)
      stepping = strtonum($7)

      if (vendor == "GenuineIntel") {
        printf(" --cpu %d/%d/%d", family, model, stepping)
      }
  }
'

perf script --no-itrace -i $file -D | \
  grep -A18 -e PERF_RECORD_AUXTRACE_INFO | \
  gawk -F' ' -- '
  /^ *Time Shift/           { printf(" --pevent:time-shift %s", $NF) }
  /^ *Time Muliplier/       { printf(" --pevent:time-mult %s", $NF) }
  /^ *Time Multiplier/      { printf(" --pevent:time-mult %s", $NF) }
  /^ *Time Zero/            { printf(" --pevent:time-zero %s", $NF) }
  /^ *TSC:CTC numerator/    { printf(" --cpuid-0x15.ebx %s", $NF) }
  /^ *TSC:CTC denominator/  { printf(" --cpuid-0x15.eax %s", $NF) }
  /^ *Max non-turbo ratio/  { printf(" --nom-freq %s", $NF) }
'

gawk_sample_type() {
  echo $1 | gawk -- '
  BEGIN               { RS = "[|\n]" }
  /^IP$/              { config += 0x0000001 }
  /^TID$/             { config += 0x0000002 }
  /^TIME$/            { config += 0x0000004 }
  /^ADDR$/            { config += 0x0000008 }
  /^READ$/            { config += 0x0000010 }
  /^CALLCHAIN$/       { config += 0x0000020 }
  /^ID$/              { config += 0x0000040 }
  /^CPU$/             { config += 0x0000080 }
  /^PERIOD$/          { config += 0x0000100 }
  /^STREAM$/          { config += 0x0000200 }
  /^STREAM_ID$/       { config += 0x0000200 }
  /^RAW$/             { config += 0x0000400 }
  /^BRANCH_STACK$/    { config += 0x0000800 }
  /^REGS_USER$/       { config += 0x0001000 }
  /^STACK_USER$/      { config += 0x0002000 }
  /^WEIGHT$/          { config += 0x0004000 }
  /^DATA_SRC$/        { config += 0x0008000 }
  /^IDENTIFIER$/      { config += 0x0010000 }
  /^TRANSACTION$/     { config += 0x0020000 }
  /^REGS_INTR$/       { config += 0x0040000 }
  /^PHYS_ADDR$/       { config += 0x0080000 }
  /^AUX$/             { config += 0x0100000 }
  /^CGROUP$/          { config += 0x0200000 }
  /^DATA_PAGE_SIZE$/  { config += 0x0400000 }
  /^CODE_PAGE_SIZE$/  { config += 0x0800000 }
  /^WEIGHT_STRUCT$/   { config += 0x1000000 }
  END           {
    printf("0x%lx", config)
  }
'
}

zero_config=1
perf script --header-only -i $file | grep -e '^# *event *:' | \
    sed 's/.*id = {\([^}]*\)}.*sample_type = \([^,]*\),.*/\1:\2/' | \
    while read -r conf; do
        ids=$(echo $conf | sed 's/\([^:]*\):.*/\1/' | sed 's/,//g')
        sts=$(echo $conf | sed 's/.*:\(.*\)/\1/')

        for id in $ids; do
            # The reserved zero identifier used for synthesized event
            # records uses the same sample type as the first identifier in
            # the first event.
            #
            if (( $zero_config )); then
                echo -n " --pevent:sample-config 0:$(gawk_sample_type $sts)"
                zero_config=0
            fi
            echo -n " --pevent:sample-config $id:$(gawk_sample_type $sts)"
        done
    done

perf evlist -v -i $file | grep intel_pt | gawk -F' ' -- '
  BEGIN             { RS = "," }
  /config/ {
    config = strtonum($2)
    mtc_freq = and(rshift(config, 14), 0xf)

    printf(" --mtc-freq 0x%x", mtc_freq)
  }
'

if [[ -n "$sysroot" ]]; then
    echo -n " --pevent:sysroot $sysroot"

    if [[ -r "$sysroot/vdso/vdso-x64.so" ]]; then
        echo -n " --pevent:vdso-x64 $sysroot/vdso/vdso-x64.so"
    fi

    if [[ -r "$sysroot/vdso/vdso-x32.so" ]]; then
        echo -n " --pevent:vdso-x32 $sysroot/vdso/vdso-x32.so"
    fi

    if [[ -r "$sysroot/vdso/vdso-ia32.so" ]]; then
        echo -n " --pevent:vdso-ia32 $sysroot/vdso/vdso-ia32.so"
    fi
fi

if [[ -n "$kcore" ]]; then
    if [[ ! -d "$kcore" ]]; then
        echo "$prog: kcore_dir '$kcore' is not a directory."
        exit 1
    fi

    if [[ ! -r "$kcore/kcore" ]]; then
        echo "$prog: 'kcore' not found in '$kcore' or not readable."
        exit 1
    fi

    echo -n " --pevent:kcore $kcore/kcore"

    if [[ ! -r "$kcore/kallsyms" ]]; then
        echo "$prog: 'kallsyms' not found in '$kcore' or not readable."
        exit 1
    fi

    cat "$kcore/kallsyms" | \
        gawk -M -- '
            function update_kernel_start(vaddr) {
              if (vaddr < kernel_start) {
                kernel_start = vaddr
              }
            }

            BEGIN                   { kernel_start = 0xffffffffffffffff }
            /^[0-9a-f]+ T _text$/   { update_kernel_start(strtonum("0x" $1)) }
            /^[0-9a-f]+ T _stext$/  { update_kernel_start(strtonum("0x" $1)) }
            END {
              if (kernel_start < 0xffffffffffffffff) {
                printf(" --pevent:kernel-start 0x%x", kernel_start)
              }
            }
        '
fi

fbase="$(basename "$file")"
mbase="$(basename "$master")"
sdir="$(dirname "$master")"
if [[ "$mbase" == "$master" ]]; then
    sdir="$(dirname "$file")"
fi
for sbfile in "$sdir/$fbase"-sideband*.pevent; do
    if [[ ! -e "$sbfile" ]]; then
        break
    fi

    if [[ -z "$master" || "$sbfile" == "$sdir/$mbase" ]]; then
        echo -n " --pevent:primary $sbfile"
    else
        echo -n " --pevent:secondary $sbfile"
    fi
done
