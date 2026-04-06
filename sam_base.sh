#!/bin/sh

# sam_base.sh. A collection of primitives for developing portable shell scripts.
#
# Copyright (c) 2026 Semyon A Mironov
#
# Authors: Semyon A Mironov <s.mironov@mgmsam.pro>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

eval 'ERROR=$(:)' 2>/dev/null || {
    echo "error: POSIX command substitution \$(...) is not supported by this shell."
    exit 1
}

eval 'ERROR=$((0))' 2>/dev/null || {
    echo "error: POSIX arithmetic expansion \$((...)) is not supported by this shell."
    exit 1
}

eval 'ERROR=${ERROR#*:}' 2>/dev/null || {
    echo "error: POSIX parameter expansion \${VAR#*}, \${VAR%*}, is not supported by this shell."
    exit 1
}

(type type) 2>/dev/null 1>&2 || {
    echo "error: shell built-in 'type' is not supported. Unable to verify system commands."
    exit 1
}

PUTS_LENGHT_PREFIX=
SAY_DIVIDER=
SAY_ESCAPE=
SAY_INDENT=
SAY_NEWLINE=

LF='
'

case "${KSH_VERSION:-}" in
    ?*)
        PUTS_TYPE=print PUTS_ESCAPE=true
        puts ()
        {
            "$SAY_ESCAPE" && PUTS_FORMAT=-n || PUTS_FORMAT="-n -r"
            "$SAY_BATCH" && print $PUTS_FORMAT "$*${SAY_SUFFIX:-}" || {
                PUTS="print $PUTS_FORMAT"
                puts_stream "$*"
            }
        }
    ;;
    *)
        false
    ;;
esac ||
if type printf
then
    printf '%b' '\033[0m' &&
    PUTS_ESCAPE=true || PUTS_ESCAPE=false
    PUTS_TYPE=printf
    puts ()
    {
        "$SAY_ESCAPE" && PUTS_FORMAT=%b || PUTS_FORMAT=%s
        "$SAY_BATCH" && printf $PUTS_FORMAT "$*${SAY_SUFFIX:-}" || {
            PUTS="printf $PUTS_FORMAT"
            puts_stream "$*"
        }
    }
elif type echo
then
    case "X$(echo -n)" in
        X-n)
            case "X$(echo '\033[0m')" in
                'X\033[0m')
                    PUTS_ESCAPE=false || PUTS_ESCAPE=true
                    PUTS_TYPE=echo
                    puts ()
                    {
                        "$SAY_BATCH" && echo "$*${SAY_SUFFIX:-}\c" || {
                            case "${SAY_SUFFIX:-}" in
                                "")
                                    SAY_SUFFIX="\c"
                                ;;
                                *)
                                    SAY_SUFFIX=
                                ;;
                            esac
                            PUTS="echo"
                            puts_stream "$*"
                        }
                    }
                ;;
                *)
                    false
                ;;
            esac
        ;;
    esac ||
    case "X$(echo -e)" in
        X-e)
            case "X$(echo '\033[0m')" in
                'X\033[0m')
                    PUTS_ESCAPE=false || PUTS_ESCAPE=true
                    PUTS_TYPE=echo_n
                    puts ()
                    {
                        "$SAY_BATCH" && echo -n "$*${SAY_SUFFIX:-}" || {
                            PUTS="echo -n"
                            puts_stream "$*"
                        }
                    }
                ;;
                *)
                    false
                ;;
            esac
        ;;
    esac || {
        PUTS_TYPE=echo_ne PUTS_ESCAPE=true
        puts ()
        {
            "$SAY_ESCAPE" && PUTS_FORMAT="-ne" || PUTS_FORMAT="-n"
            "$SAY_BATCH" && echo $PUTS_FORMAT "$*${SAY_SUFFIX:-}" || {
                PUTS="echo $PUTS_FORMAT"
                puts_stream "$*"
            }
        }
    }
else
    exit 1
fi >/dev/null 2>&1

if type sleep
then
    CAN_SLEEP=true
    sleep 0.0 && CAN_SLEEP_FLOAT=true || CAN_SLEEP_FLOAT=false
else
    CAN_SLEEP=false
    CAN_SLEEP_FLOAT=false
fi >/dev/null 2>&1

puts_stream ()
{
    PUTS_LINE=$($PUTS "$*")${SAY_SUFFIX:-}
    while case "${PUTS_LINE:-}" in "") false ;; esac
    do
        PUTS_CHAR=${PUTS_LINE%${PUTS_LINE#?}}
        PUTS_LINE=${PUTS_LINE#?}
        $PUTS "$PUTS_CHAR"
        case "$PUTS_CHAR" in
            [[:alnum:]])
                sleep "${SAY_TIMEOUT:-0.05}"
            ;;
        esac
    done
}

puts_indented ()
{
    if $SAY_PREFIX_INDENT
    then
        case "${PUTS_LENGHT_PREFIX:-}" in
            "${SAY_LENGHT_INDENT:-0}")
            ;;
            *)
                PUTS_LENGHT_PREFIX=${SAY_LENGHT_INDENT:-${#SAY_PREFIX}}
                SAY_COUNT=$PUTS_LENGHT_PREFIX
                SAY_INDENT=
                while case $SAY_COUNT in 0) false ;; esac
                do
                    SAY_COUNT=$((SAY_COUNT - 1))
                    SAY_INDENT="${SAY_INDENT:-} "
                done
            ;;
        esac
        case "${SAY_PREFIX:-}" in
            ?*)
                case "$((${#SAY_PREFIX} + ${#SAY_DIVIDER}))" in
                    "${PUTS_LENGHT_PREFIX:-}")
                    ;;
                    *)
                        SAY_COUNT=$((PUTS_LENGHT_PREFIX - ${#SAY_PREFIX}))
                        SAY_DIVIDER=
                        while case "$((SAY_COUNT > 0))" in 0) false ;; esac
                        do
                            SAY_COUNT=$((SAY_COUNT - 1))
                            SAY_DIVIDER="${SAY_DIVIDER:-} "
                        done
                    ;;
                esac
                SAY_PREFIX=$SAY_PREFIX${SAY_DIVIDER:-}
            ;;
        esac
        case $# in
            [!01])
                SAY_SUFFIX=$LF
                puts "${SAY_PREFIX:-${SAY_INDENT:-}}${1:-}"
                shift
                SAY_PREFIX=${SAY_INDENT:-}
                $SAY_NEWLINE || SAY_SUFFIX=
            ;;
            *)
                SAY_PREFIX=${SAY_PREFIX:-${SAY_INDENT:-}}
            ;;
        esac
    fi
    case $# in
        [!01])
            SAY_SUFFIX=$LF
            while case $# in 1) false ;; esac
            do
                puts "${SAY_PREFIX:-}$1"
                shift
            done
            $SAY_NEWLINE || SAY_SUFFIX=
        ;;
    esac
    puts "${SAY_PREFIX:-}${1:-}"
}

say ()
{
    SAY_RESULT=$?

    SAY_BATCH=true
    SAY_ESCAPE=$PUTS_ESCAPE
    SAY_LIST=false
    SAY_NEWLINE=true
    SAY_PREFIX="${LOG_PREFIX:-$0: }"
    SAY_PREFIX_INDENT=false
    SAY_SUFFIX="$LF"

    set -- ${SAY_OPTIONS:-} "$@"

    while case $# in 0) false ;; esac
    do
        case "${1:-}" in
            -c*)
                case "$1" in
                    -c[!0-9\.]* | -c[0-9]*[!0-9\.]* | -c\.*[!0-9]* | *\.*\.*)
                        false
                    ;;
                    *)
                        if $CAN_SLEEP
                        then
                            case "${1#??}" in
                                *\.*)
                                    if $CAN_SLEEP_FLOAT
                                    then
                                        false
                                    fi
                                ;;
                                *)
                                    false
                                ;;
                            esac || {
                                SAY_BATCH=false
                                SAY_TIMEOUT="${1#??}"
                            }
                        fi
                    ;;
                esac
            ;;
            *)
                false
            ;;
        esac ||
        case "${1:-}" in
            -i*)
                case "$1" in
                    -i[!0-9]* | -i[0-9]*[!0-9]*)
                        false
                    ;;
                    *)
                        SAY_PREFIX_INDENT=true
                        SAY_LENGHT_INDENT="${1#??}"
                    ;;
                esac
            ;;
            *)
                false
            ;;
        esac ||
        case "${1:-}" in
            -l)
                SAY_LIST=true
            ;;
            -n)
                SAY_NEWLINE=false
                SAY_SUFFIX=
            ;;
            -p)
                SAY_PREFIX=
            ;;
            -r)
                SAY_ESCAPE=false
            ;;
            "" | *[!0-9]*)
                break
            ;;
            *)
                SAY_RESULT=$1
            ;;
        esac
        shift
    done
    case "$SAY_RESULT" in
        0)
            EXIT_CODE=${EXIT_CODE:-0}
        ;;
        *)
            EXIT_CODE=$SAY_RESULT
        ;;
    esac
    case "$*" in
        ?*)
            if "$SAY_LIST"
            then
                puts_indented ${1:+"$@"}
            else
                puts_indented ${1:+"$*"}
            fi
        ;;
    esac
}

die ()
{
    say "$@" >&2
    exit $EXIT_CODE
}

is_diff ()
{
    case "${1:-}" in
        "${2:-}")
            return 1
        ;;
    esac
}

is_empty ()
{
    case "${1:-}" in
        ?*)
            return 1
        ;;
    esac
}

is_not_empty ()
{
    case "${1:-}" in
        "")
            return 1
        ;;
    esac
}

is_same ()
{
    case "${1:-}" in
        "${2:-}")
            return 0
        ;;
    esac
    return 1
}

is_equal ()
{
    case "$((${1:-0} == ${2:-0}))" in
        0)
            return 1
        ;;
    esac
}

is_greater ()
{
    case "$((${1:-0} > ${2:-0}))" in
        0)
            return 1
        ;;
    esac
}

is_less ()
{
    case "$((${1:-0} < ${2:-0}))" in
        0)
            return 1
        ;;
    esac
}

is_digit ()
{
    case "${1:-}" in
        *[!0-9]*)
            return 1
        ;;
    esac
}

is_dir ()
{
    test -d "${1:-}"
}

is_file ()
{
    test -f "${1:-}"
}

is_read ()
{
    test -r "${1:-}"
}

is_term ()
{
    test -t "${1:-1}" && IS_TERM=true || IS_TERM=false
    $IS_TERM
}

is_root_access ()
{
    type id >/dev/null 2>&1 && {
        case "$(id -u 2>/dev/null)" in 0) return 0 ;; esac
        return 1
    } || test -w /
}

loop ()
{
    :
}

set_env ()
{
    PWD=$(pwd)
    CR=$(puts '\r')
    TAB=$(puts '\t')
    SPACE=' '
    BLANK=$SPACE$TAB
    POSIX_IFS=$SPACE$TAB$LF
    IFS=$POSIX_IFS
}

include ()
{
    test -f "$1" || {
        say "lib not found: '$1'"
        return ${SAY_RESULT:-1}
    } >&2

    test -r "$1" || {
        say "no read permissions: '$1'"
        return ${SAY_RESULT:-1}
    } >&2

    ERROR=$(2>&1 . "$1") || {
        say "$ERROR"
        return ${SAY_RESULT:-1}
    } >&2

    . "$1"
}

full_path ()
{
    # resolve path

    # arguments
    # "$1": path to file/directory

    # variables
    # HOME: path to the user's home directory
    # PWD: full path to the current working directory
    # TMP: path for parsing
    # DIR: path directory
    # TARGET: the result of getting the full path to the file/directory

    # commands
    # test: The test utility shall evaluate the expression and indicate
    # the result of the evaluation by its exit status
    # : This utility shall only expand command arguments

    # return code:
    # 0: success

    # launch examples:
    # fpath '~/../alisa/.//.ssh/'
########################################################################
    # resolve path ~/../alisa/.//.ssh/ to /home/bob/../alisa/.//.ssh/
    TARGET=${1:-}
    case "$TARGET" in
        \~)     TARGET=${HOME%/} ;;
        \~/*)   TARGET=${HOME%/}/${TARGET#?} ;;
         ./*)   case "$PWD" in
                    / ) TARGET=${TARGET#?} ;;
                    * ) TARGET=$PWD${TARGET#?} ;;
                esac ;;
        [!/]*)  case "$PWD" in
                    / ) TARGET=/$TARGET ;;
                    * ) TARGET=$PWD/$TARGET ;;
                esac ;;
    esac
    # resolve path /home/bob/../alisa/.//.ssh/ to /home/alisa/.ssh
    ARG=${TARGET:-}
    TARGET=
    while case "${ARG:-}" in "") false ;; esac
    do
        DIR=${ARG%%/*}
        case "${DIR:-}" in
             .) : ;;
            '') DIR=${ARG%%[!/]*} ;;
            ..) TARGET=${TARGET%/*} ;;
             *) TARGET=${TARGET%/}/$DIR ;;
        esac
        ARG=${ARG#$DIR}
        TARGET=${TARGET:=/}
    done
}

cd_print ()
{
    2>&1 cd -- "$1" && 2>&1 pwd -P
}

resolve_path ()
{
    (cd_print)
}
