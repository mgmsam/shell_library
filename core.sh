#!/bin/sh

# core.sh. A collection of primitives for developing portable shell scripts.
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

COLOR_PROMPT=
case ${TERM:-} in
    xterm* | rxvt* | screen* | linux* | vt100* | vt220* | putty* | Eterm* | alacritty* | tmux* | kitty*)
        COLOR_PROMPT=true
    ;;
    *)
        type tput &&
        case $(tput colors) in
            '' | [01] | -*)
                false
            ;;
            *)
                COLOR_PROMPT=true
            ;;
        esac || COLOR_PROMPT=false
    ;;
esac >/dev/null 2>&1

_set_color_var ()
{
    RESET_ALL=${_SET_COLOR:+'\033[0m'}
    # text color
    R_TEXT=${_SET_COLOR:+'\033[39m'}
    T_BLACK=${_SET_COLOR:+'\033[30m'}
    T_BLUE=${_SET_COLOR:+'\033[34m'}
    T_CYAN=${_SET_COLOR:+'\033[36m'}
    T_GREEN=${_SET_COLOR:+'\033[32m'}
    T_MAGENTA=${_SET_COLOR:+'\033[35m'}
    T_RED=${_SET_COLOR:+'\033[31m'}
    T_WHITE=${_SET_COLOR:+'\033[37m'}
    T_YELLOW=${_SET_COLOR:+'\033[33m'}
    # text attributes
    R_ATTR=${_SET_COLOR:+'\033[22;24;25;26;27;28m'}
    A_BOLD=${_SET_COLOR:+'\033[1m'}              R_BOLD=${_SET_COLOR:+'\033[22m'}
    A_HALF_BRIGHT=${_SET_COLOR:+'\033[2m'}       R_HALF_BRIGHT=${_SET_COLOR:+'\033[22m'}
    A_UNDERLINE=${_SET_COLOR:+'\033[4m'}         R_UNDERLINE=${_SET_COLOR:+'\033[24m'}
    A_DOUBLE_UNDERLINE=${_SET_COLOR:+'\033[21m'} R_DOUBLE_UNDERLINE=${_SET_COLOR:+'\033[24m'}
    A_BLINK=${_SET_COLOR:+'\033[5m'}             R_BLINK=${_SET_COLOR:+'\033[25m'}
    A_INVERSION=${_SET_COLOR:+'\033[7m'}         R_INVERSION=${_SET_COLOR:+'\033[27m'}
    A_INVISIBLE=${_SET_COLOR:+'\033[8m'}         R_INVISIBLE=${_SET_COLOR:+'\033[28m'}
    # background color
    R_BG=${_SET_COLOR:+'\033[49m'}
    B_BLACK=${_SET_COLOR:+'\033[40m'}
    B_BLUE=${_SET_COLOR:+'\033[44m'}
    B_CYAN=${_SET_COLOR:+'\033[46m'}
    B_GREEN=${_SET_COLOR:+'\033[42m'}
    B_MAGENTA=${_SET_COLOR:+'\033[45m'}
    B_RED=${_SET_COLOR:+'\033[41m'}
    B_WHITE=${_SET_COLOR:+'\033[47m'}
    B_YELLOW=${_SET_COLOR:+'\033[43m'}
}

reset_color ()
{
    _SET_COLOR= _set_color_var
}

init_color ()
{
    $COLOR_PROMPT && {
        _SET_COLOR=1 _set_color_var
    } || reset_color
}

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

PUTS_LENGHT_PREFIX=
SAY_DIVIDER=
SAY_ESCAPE=
SAY_INDENT=
SAY_NEWLINE=
SAY_BATCH=true
SAY_ESCAPE=$PUTS_ESCAPE
LF='
'

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
    SAY_PREFIX="${LOG_PREFIX:-$0}: "
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

PWD=$(pwd)
CR=$(puts '\r')
TAB=$(puts '\t')
SPACE=' '
BLANK=$SPACE$TAB
POSIX_IFS=$SPACE$TAB$LF
IFS=$POSIX_IFS
SYS_LIB_DIR='/usr/lib/shell'
PKG_DIR=$(2>&1
    _PATH="${0%/*}"
    case $0 in
        "$_PATH")
            _PATH=$PWD
        ;;
    esac
    cd -- "${_PATH:-/}" && 2>&1 pwd -P
)

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

str_replace ()
{
########################################################################
    # replace sub string in string
    # $1 - pattern
    # $2 - replace
########################################################################
    _CORE_REPEAT=false
    while true
    do
        case "$1" in
            --)
                shift
                break
            ;;
            -l)
                _CORE_REPEAT=true
                shift
            ;;
            *)
                break
            ;;
        esac
    done
    _CORE_STRING="$1"
    while
        case $_CORE_STRING in
            *$2*)
            ;;
            *)
                false
            ;;
        esac
    do
        _CORE_BUFFER=
        while
            case $_CORE_STRING in
                "")
                    false
                ;;
            esac
        do
            _CORE_LEFT=${_CORE_STRING%%$2*}
            case "$_CORE_LEFT" in
                "$_CORE_STRING")
                    break
                ;;
            esac
            _CORE_BUFFER=$_CORE_BUFFER$_CORE_LEFT${3:-}
            _CORE_STRING=${_CORE_STRING#*$2}
        done
        _CORE_STRING=$_CORE_BUFFER$_CORE_STRING _CORE_BUFFER=
        $_CORE_REPEAT || break
    done
}

_module_not_found ()
{
    case ${1:-} in
        "$SYS_LIB_DIR"*)
            str_replace "${1#${SYS_LIB_DIR%/}/}" '/' '.'
        ;;
        "$PKG_DIR"*)
            str_replace "${1#${PKG_DIR%/}/}" '/' '.'
        ;;
        *)
            _CORE_STRING=${1:-}
        ;;
    esac
    say 1 "ModuleNotFoundError: No module named '$_CORE_STRING'"
    return 1
}

_resolve_module ()
{
    case "${1:-}" in
        */*)
            _LIB_PATH=${2:-}
            set -- "${1#/}"
        ;;
        *. | '')
            false
        ;;
        *[!"$SPACE"]*)
            _LIB_PATH=${2:-}
            IFS=.
            set -- $1
            IFS=$POSIX_IFS
            case ${1:-} in
                '')
                    case $_LIB_PATH in
                        ?*)
                            shift
                        ;;
                    esac
                ;;
                *)
                    _LIB_PATH=
                ;;
            esac
        ;;
        *)
            false
        ;;
    esac || {
        say 1 "SyntaxError: invalid syntax: '${1:-}'"
        return 1
    }

    for i
    do
        case $i in
            '')
                case $_LIB_PATH in
                    '')
                        _LIB_PATH=${PKG_DIR%/}
                    ;;
                    *)
                        _LIB_PATH=${_LIB_PATH%/*}
                    ;;
                esac
            ;;
            */*)
                _LIB_PATH=${_LIB_PATH%/}/$i
                is_dir "$_LIB_PATH" || is_file "$_LIB_PATH" ||
                    _module_not_found "$_LIB_PATH" || return
            ;;
            *)
                case $_LIB_PATH in
                    '')
                        _LIB_PATH=${SYS_LIB_DIR%/}/$i
                    ;;
                    *)
                        _LIB_PATH=$_LIB_PATH/$i
                    ;;
                esac
                is_dir "$_LIB_PATH" || is_file "$_LIB_PATH" ||
                    _module_not_found "$_LIB_PATH" || return
            ;;
        esac
    done
    echo "$_LIB_PATH"
}

_import ()
{
    ERROR=$(2>&1 . "${1:-}") || {
        say "$ERROR"
        return ${SAY_RESULT:-1}
    }
    . "$1"
}

_import_module ()
{
    if is_dir "${1:-}"
    then
        is_file "$1/__init__.sh" || return 0
        str_replace "$1" "'" "'\''"
        _SUB_MODULE="${_SUB_MODULE:+$_SUB_MODULE }'$_CORE_STRING'"
    else
        is_file "${1%.sh}.sh" || _module_not_found "$1" &&
        _import "${1%.sh}.sh" || return
    fi
}

_import_package ()
{
    _IMPORT_EXEC=false
    while IFS=$POSIX_IFS read -r _LINE || is_not_empty "$_LINE"
    do
        case $_LINE in
            "from "*)
                set -- $_LINE
                shift
                from "$@"
            ;;
            "import "*)
                set -- $_LINE
                shift
                for j
                do
                    j=$(2>&1 _resolve_module "$j" "$i") || {
                        echo "$j"
                        return 1
                    }
                    _import_module "$j" || return
                done
                _IMPORT_EXEC=true
            ;;
        esac
    done < "$i/__init__.sh"

    $_IMPORT_EXEC ||
    for j in "$i"/*.sh
    do
        case $j in
            */__init__.sh)
            ;;
            *)
                _import "$j" || return
            ;;
        esac
    done
}

import ()
{
    _SUB_MODULE=
    for i
    do
        case $i in
            */*)
                if is_dir "$i"
                then
                    is_file "$i/__init__.sh" || continue
                    _import_package || die 1
                else
                    is_file "$i" || _module_not_found "$i" &&
                    _import "$i" || die 1
                fi
            ;;
            *)
                i=$(2>&1 _resolve_module "$i") || {
                    echo "$i"
                    die 1
                }
                _import_module "$i" || die 1
            ;;
        esac
    done

    case $_SUB_MODULE in
        ?*)
            eval set -- "$_SUB_MODULE"
            for i
            do
                import "$i" || die 1
            done
        ;;
    esac
}

from ()
{
    _LIB_PATH=$(_resolve_module "${1:-}") || {
        echo "$_LIB_PATH"
        die 1
    }
    is_dir "$_LIB_PATH" || {
        is_file "$_LIB_PATH" &&
            die 1 "ModuleError: loading from module not implemented: '$_LIB_PATH'" ||
            die 1 "ModuleError: not a directory: '$_LIB_PATH'"
    }
    shift
    case ${1:-} in
        import)
            shift
            _IMPORT_EXEC=false
            _SUB_MODULE=
            for j
            do
                j=$(2>&1 _resolve_module "$j" "$_LIB_PATH") || {
                    echo "$j"
                    die 1
                }
                _import_module "$j" || die 1
                _IMPORT_EXEC=true
            done
            case $_SUB_MODULE in
                ?*)
                    eval set -- "$_SUB_MODULE"
                    for i
                    do
                        _import_package || die 1
                    done
                ;;
            esac
            $_IMPORT_EXEC
        ;;
        *)
            false
        ;;
    esac || die 1 "SyntaxError: invalid syntax"
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
    (cd_print "$1")
}

copy ()
{
    STATUS=$(2>&1 cp -frv -- "$@") || say "$STATUS"
    return ${SAY_RESULT:-0}
}

move ()
{
    STATUS=$(2>&1 mv -fv -- "$@") || say "$STATUS"
    return ${SAY_RESULT:-0}
}

remove ()
{
    STATUS=$(2>&1 rm -frv -- "$@") || say "$STATUS"
    return ${SAY_RESULT:-0}
}

makedir ()
{
    STATUS=$(2>&1 mkdir -pv -- "$@") || say "$STATUS"
    return ${SAY_RESULT:-0}
}

symlink ()
{
    STATUS=$(2>&1 ln -fsv -- "$@") || say "$STATUS"
    return ${SAY_RESULT:-0}
}

hardlink ()
{
    STATUS=$(2>&1 ln -fpv -- "$@") || say "$STATUS"
    return ${SAY_RESULT:-0}
}
