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
    _CORE_REPLACE_ALL=false
    while true
    do
        case "$1" in
            --)
                shift
                break
            ;;
            -l)
                _CORE_REPLACE_ALL=true
                shift
            ;;
            *)
                break
            ;;
        esac
    done
    CORE_RESULT="$1"
    while
        case $CORE_RESULT in
            *$2*)
            ;;
            *)
                false
            ;;
        esac
    do
        _CORE_ACCUMULATOR=
        while
            case $CORE_RESULT in
                "")
                    false
                ;;
            esac
        do
            _CORE_LEFT=${CORE_RESULT%%$2*}
            case "$_CORE_LEFT" in
                "$CORE_RESULT")
                    break
                ;;
            esac
            _CORE_ACCUMULATOR=$_CORE_ACCUMULATOR$_CORE_LEFT${3:-}
            CORE_RESULT=${CORE_RESULT#*$2}
        done
        CORE_RESULT=$_CORE_ACCUMULATOR$CORE_RESULT _CORE_ACCUMULATOR=
        $_CORE_REPLACE_ALL || break
    done
}

_modulenotfounderror ()
{
    case ${1:-} in
        "$SYS_LIB_DIR"*)
            str_replace "${1#${SYS_LIB_DIR%/}/}" '/' '.'
        ;;
        "$PKG_DIR"*)
            str_replace "${1#${PKG_DIR%/}/}" '/' '.'
        ;;
        *)
            CORE_RESULT=${1:-}
        ;;
    esac
    say 1 "ModuleNotFoundError: No module named '$CORE_RESULT'"
    return 1
}

_validate_module_path ()
{
    is_dir "$_MODULE_PATH" ||
        is_file "${_MODULE_PATH%.sh}.sh" ||
            is_file "$_MODULE_PATH" ||
                _modulenotfounderror "$_MODULE_PATH"
}

_resolve_module ()
{
    case "${1:-}" in
        */*)
            _MODULE_PATH=${2:+"${2%/}/"}$1
            _validate_module_path || return
            echo "$_MODULE_PATH"
            return
        ;;
        *. | '')
            false
        ;;
        *[!"$SPACE"]*)
            _MODULE_PATH=${2:-}
            IFS=.
            set -- $1
            IFS=$POSIX_IFS
            case ${1:-} in
                '')
                    case $_MODULE_PATH in
                        ?*)
                            shift
                        ;;
                    esac
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
                case $_MODULE_PATH in
                    '')
                        _MODULE_PATH=${PKG_DIR%/}
                    ;;
                    *)
                        _MODULE_PATH=${_MODULE_PATH%/*}
                    ;;
                esac
            ;;
            */*)
                _MODULE_PATH=${_MODULE_PATH:+${_MODULE_PATH%/}/}$i
                _validate_module_path || return
            ;;
            *)
                case $_MODULE_PATH in
                    '')
                        _MODULE_PATH=${SYS_LIB_DIR%/}/$i
                    ;;
                    *)
                        _MODULE_PATH=$_MODULE_PATH/$i
                    ;;
                esac
                _validate_module_path || return
            ;;
        esac
    done
    echo "$_MODULE_PATH"
}

_append_list_modules ()
{
    _MODULES=
    for _MODULE
    do
        _MODULE=$(_resolve_module "$_MODULE" "$_MODULE_PATH") || {
            echo "$_MODULE"
            die 1
        }
        str_replace "$_MODULE" "'" "'\''"
        _MODULES="${_MODULES:+$_MODULES }'$CORE_RESULT'"
    done
    _LIST_MODULES=$_LIST_MODULES$LF$_MODULES
}

_resolve_from ()
{
    _MODULE_PATH=$(_resolve_module "${1:-}" ${_PACKAGE:+"$_PACKAGE"}) || {
        echo "$_MODULE_PATH"
        die 1
    }
    is_dir "$_MODULE_PATH" || {
        is_file "$_MODULE_PATH" &&
            die 1 "ModuleError: loading from module not implemented: '$_MODULE_PATH'" ||
            die 1 "ModuleError: not a directory: '$_MODULE_PATH'"
    }
    shift
    case ${1:-} in
        import)
            shift
            _append_list_modules "$@"
        ;;
        *)
            false
        ;;
    esac || die 1 "SyntaxError: invalid syntax"
}

_exec_module ()
{
    ERROR=$(2>&1 . "${1:-}") || {
        say "$ERROR"
        return ${SAY_RESULT:-1}
    }
    . "$1" && _LOADED=true
}

_load_module_list ()
{
    while
        read -r _MODULE ||
        case $_MODULE in
            '')
                false
            ;;
        esac
    do
        case $_MODULE in
            ?*)
                eval set -- "$_MODULE"
                import "$@"
            ;;
        esac
    done <<EOF
$_LIST_MODULES
EOF
}

_load_package_context ()
{
    _LIST_MODULES=
    while
        read -r _LINE ||
        case $_LINE in
            '')
                false
            ;;
        esac
    do
        case $_LINE in
            "import "*)
                set -- $_LINE
                shift
                _MODULE_PATH=$_PACKAGE
                _append_list_modules "$@"
            ;;
            "from "*)
                set -- $_LINE
                shift
                _resolve_from "$@"
            ;;
        esac
    done < "$_PACKAGE/__init__.sh"

    case $_LIST_MODULES in
        '')
            for _MODULE in "$_PACKAGE"/*.sh
            do
                case $_MODULE in
                    */__init__.sh)
                    ;;
                    *)
                        _exec_module "$_MODULE" || return
                    ;;
                esac
            done
        ;;
        *)
            _load_module_list
        ;;
    esac
}

_import_module ()
{
    if is_dir "${1:-}"
    then
        is_file "$1/__init__.sh" || return 0
        _PACKAGE="$1"
        _load_package_context
    else
        _MODULE="${1%.sh}.sh"
        is_file "$_MODULE" || {
            _MODULE="$1"
            is_file "$_MODULE"
        } || _modulenotfounderror "$1" && _exec_module "$_MODULE" || return
    fi
}

import ()
{
    _LOADED=false
    _SUB_MODULE=
    for _MODULE
    do
        _MODULE=$(2>&1 _resolve_module "$_MODULE") || {
            echo "$_MODULE"
            die 1
        }
        _import_module "$_MODULE" || die 1
    done
    $_LOADED
}

from ()
{
    _LIST_MODULES=
    _resolve_from "$@"
    _load_module_list
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
