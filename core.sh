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

set -e

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
SCRIPT_DIR=$(2>&1
    _PATH="${0%/*}"
    case $0 in
        "$_PATH")
            _PATH=$PWD
        ;;
    esac
    cd -- "${_PATH:-/}" && 2>&1 pwd -P
)
SCRIPT_FILE="${SCRIPT_DIR%/}/${0##*/}"

SYS_LIBDIR='/usr/lib/shell'
SYS_PATH="'' '$SYS_LIBDIR'"

case ${BASH_VERSION:-} in
    '')
        _CORE_IMPORT_AS=false
    ;;
    *)
        _CORE_IMPORT_AS=true
    ;;
esac

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

get_indent ()
{
    CORE_INDENT_LEN=
    CORE_INDENT=${1:-}
    _CORE_INDENT_CHAR=${2:-" "}
    case "$CORE_INDENT" in
        0 | "")
            CORE_INDENT=
            CORE_INDENT_LEN=0
            return
        ;;
        *[!0123456789]*)
            CORE_INDENT=${#CORE_INDENT}
        ;;
    esac
    CORE_INDENT_LEN=$CORE_INDENT
    CORE_INDENT=
    _CORE_COUNT=0
    while
        case $((_CORE_COUNT == CORE_INDENT_LEN)) in
            1)
                false
            ;;
        esac
    do
        CORE_INDENT="$CORE_INDENT$_CORE_INDENT_CHAR"
        _CORE_COUNT=$((_CORE_COUNT + 1))
    done
}

_get_error ()
{
    case $1 in
        '')
            _CORE_ERROR_INDENT=
        ;;
        *)
            get_indent ${#1}
            _CORE_ERROR_INDENT=$CORE_INDENT
        ;;
    esac
    get_indent ${#2} '^'
    _CORE_ERROR=$_CORE_ERROR_INDENT$CORE_INDENT
}

_syntax_error ()
{
    $_MERGE &&
        _get_error "    $_IMPORT_COMMAND $_IMPORT_SPECS${_MODULE_NAME%%[[:blank:]]*}" "${2:-.}" ||
        _get_error "    $_IMPORT_COMMAND${_IMPORT_SPECS:+ $_IMPORT_SPECS}${_MODULE_NAME:+ ${_MODULE_NAME%%[[:blank:]]*}}" "${2:-.}"

    echo "  File \"${_FILE_PATH:-$SCRIPT_FILE}\""
    echo "    $_IMPORT_STATEMENT"
    _IMPORT_COMMAND=
    case $1 in
        1)
            echo "$_CORE_ERROR
SyntaxError: invalid syntax"
        ;;
        2)
            echo "$_CORE_ERROR
SyntaxError: leading zeros in decimal integer literals are not permitted"
        ;;
        3)
            echo "$_CORE_ERROR
SyntaxError: invalid decimal literal"
        ;;
        4)
            echo "$_CORE_ERROR
SyntaxError: trailing comma not allowed without surrounding parentheses"
        ;;
    esac
    return 1
}

is_valid_identifier ()
{
    _IDENTIFIER=$1

    IFS=.
    set -- $1
    IFS=$POSIX_IFS

    _MODULE_NAME=
    _ONE_MODULE_PART_NAME=true
    for _MODULE_PART_NAME
    do
        case $_IMPORT_COMMAND in
            from | import)
            ;;
            *)
                $_ONE_MODULE_PART_NAME &&
                 _ONE_MODULE_PART_NAME=false || _syntax_error 1
            ;;
        esac || return

        case $_MODULE_PART_NAME in
            '')
                _MODULE_NAME="${_MODULE_NAME:- }"
                case ${_IDENTIFIER#${_IDENTIFIER%%.*}} in
                    ...*)
                        _syntax_error 1 '...'
                    ;;
                    .*)
                        _syntax_error 1
                    ;;
                    *)
                        _syntax_error 1 "${_IDENTIFIER%%.*}"
                    ;;
                esac
            ;;
            0*)
                case $_MODULE_NAME in
                    '')
                        _MODULE_PART_NAME=${_MODULE_PART_NAME%%[![:digit:]]*}
                        case $_MODULE_PART_NAME in
                            *[!0]*)
                                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!0]*}
                                _MODULE_NAME=' '
                                _syntax_error 2 "$_MODULE_PART_NAME"
                            ;;
                            *)
                                _MODULE_NAME=${_MODULE_PART_NAME%?}
                                _syntax_error 2
                            ;;
                        esac
                    ;;
                    *)
                        _MODULE_PART_NAME=${_MODULE_PART_NAME%%[![:digit:]]*}
                        _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}${_MODULE_PART_NAME%?}
                        _syntax_error 3
                    ;;
                esac
            ;;
            [123456789]*)
                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[![:digit:]]*}
                _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}${_MODULE_PART_NAME%?}
                _MODULE_NAME=${_MODULE_NAME:- }
                _syntax_error 3
            ;;
            [!_[:alpha:]]*)
                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!_[:alpha:]]*}
                _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}
                _syntax_error 1 "$_MODULE_PART_NAME"
            ;;
            alias   | as        | \
            bg      | bind      | break    | builtin | \
            caller  | case      | cd       | command | compgen | complete | compopt  | continue | coproc | \
            declare | dirs      | disown   | do      | done    | \
            echo    | elif      | else     | enable  | 'esac'  | eval     | exec     | exit     | export | \
            false   | fc        | fg       | fi      | for     | from     | function | \
            getopts | \
            hash    | help      | history  | \
            if      | import    | in       | \
            jobs    | \
            kill    | \
            let     | local     | logout   | \
            mapfile | \
            popd    | printf    | pushd    | pwd    | \
            read    | readarray | readonly | return | \
            select  | set       | shift    | shopt  | source | suspend | \
            test    | then      | time     | times  | trap   | true    | type | typeset | \
            ulimit  | umask     | unalias  | unset  | until  | \
            wait    | while)
                case $_MODULE_NAME in
                    '')
                        _MODULE_NAME=' '
                    ;;
                    *)
                        _MODULE_NAME="$_MODULE_NAME."
                    ;;
                esac
                _syntax_error 1 "$_MODULE_PART_NAME"
            ;;
            *[!_[:alnum:]]*)
                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!_[:alnum:]]*}
                _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}$_MODULE_PART_NAME
                _syntax_error 1
            ;;
        esac || return
        _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}$_MODULE_PART_NAME
    done

    case $_IDENTIFIER in
        *.)
            _MODULE_NAME=${_IDENTIFIER%"${_IDENTIFIER##*[!.]}"}
            _syntax_error 1
        ;;
    esac || return
    _MODULE_NAME=
}

_check_import_syntax ()
{
    _IMPORT_BUFFER=
    _IMPORT_SPEC=

    case $# in
        0)
            _MODULE_NAME=' '
            _syntax_error 1 || return
        ;;
    esac

    _COUNT=0
    while
        case $# in
            0)
                false
            ;;
        esac
    do
        _MODULE=$1
        shift

        _COUNT=$((_COUNT + 1))
        case $_COUNT in
            1)
                case $_MODULE in
                    ,*)
                        _MODULE_NAME=' '
                        _syntax_error 1 || return
                    ;;
                    *,?*)
                        set -- "${_MODULE#*,}" "$@"
                        _MODULE="${_MODULE%%,*}"
                        is_valid_identifier "$_MODULE" || return
                        _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_MODULE'"
                        _COUNT=0
                        $_MERGE &&
                            _IMPORT_SPECS="$_IMPORT_SPECS$_MODULE," ||
                            _IMPORT_SPECS="${_IMPORT_SPECS:+$_IMPORT_SPECS }$_MODULE,"
                        _MERGE=true
                    ;;
                    *,)
                        _MODULE="${_MODULE%,}"
                        is_valid_identifier "$_MODULE" || return
                        _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_MODULE'"
                        _COUNT=0
                        $_MERGE &&
                            _IMPORT_SPECS="$_IMPORT_SPECS$_MODULE," ||
                            _IMPORT_SPECS="${_IMPORT_SPECS:+$_IMPORT_SPECS }$_MODULE,"
                        _MERGE=false
                    ;;
                    *)
                        is_valid_identifier "$_MODULE" || return
                        _IMPORT_SPEC="${_IMPORT_SPEC:+$_IMPORT_SPEC }$_MODULE"
                        $_MERGE &&
                            _IMPORT_SPECS="$_IMPORT_SPECS$_MODULE" ||
                            _IMPORT_SPECS="${_IMPORT_SPECS:+$_IMPORT_SPECS }$_MODULE"
                        _MERGE=false
                    ;;
                esac
            ;;
            2)
                case $_MODULE in
                    ,?*)
                        case $_MODULE in
                            *?,?*)
                                _MODULE=${_MODULE#,}
                                set -- "${_MODULE#*,}" "$@"
                                _MODULE=${_MODULE%%,*}
                                is_valid_identifier "$_MODULE" || return
                                _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}${_IMPORT_SPEC:+"'$_IMPORT_SPEC' "}'$_MODULE'"
                                _IMPORT_SPEC=
                                _IMPORT_SPECS="${_IMPORT_SPECS:+$_IMPORT_SPECS },$_MODULE,"
                                _COUNT=0
                                _MERGE=true
                            ;;
                            *,)
                                _MODULE=${_MODULE#,}
                                _MODULE=${_MODULE%,}
                                is_valid_identifier "$_MODULE" || return
                                _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}${_IMPORT_SPEC:+"'$_IMPORT_SPEC' "}'$_MODULE'"
                                _IMPORT_SPEC=
                                _IMPORT_SPECS="$_IMPORT_SPECS ,$_MODULE,"
                                _COUNT=0
                            ;;
                            *)
                                _MODULE_NAME=,
                                is_valid_identifier "${_MODULE#,}" || return
                                _IMPORT_SPEC="${_IMPORT_SPEC:+$_IMPORT_SPEC }$_MODULE"
                                _IMPORT_SPECS="${_IMPORT_SPECS:+$_IMPORT_SPECS }$_MODULE"
                                _COUNT=1
                            ;;
                        esac
                    ;;
                    ,)
                        _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_IMPORT_SPEC'"
                        _IMPORT_SPEC=
                        _IMPORT_SPECS="$_IMPORT_SPECS ,"
                        _COUNT=0
                    ;;
                    as)
                        case $# in
                            0)
                                _MODULE_NAME=as
                                _syntax_error 1 || return
                            ;;
                            *)
                                _IMPORT_SPEC="$_IMPORT_SPEC as"
                                _IMPORT_SPECS="$_IMPORT_SPECS as"
                            ;;
                        esac
                    ;;
                    *)
                        false
                    ;;
                esac
            ;;
            3)
                case $_MODULE in
                    ,*)
                        _MODULE_NAME=' '
                        _syntax_error 1 || return
                    ;;
                    *,?*)
                        set -- "${_MODULE#*,}" "$@"
                        _MODULE="${_MODULE%%,*}"
                        is_valid_identifier "$_MODULE" || return
                        _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_IMPORT_SPEC' '$_MODULE'"
                        _IMPORT_SPEC=
                        _IMPORT_SPECS="$_IMPORT_SPECS $_MODULE,"
                        _MERGE=true
                        _COUNT=0
                    ;;
                    *,)
                        _MODULE="${_MODULE%,}"
                        is_valid_identifier "$_MODULE" || return
                        _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_IMPORT_SPEC' '$_MODULE'"
                        _IMPORT_SPEC=
                        _IMPORT_SPECS="$_IMPORT_SPECS $_MODULE,"
                        _COUNT=0
                        case $# in
                            0)
                                _MODULE_NAME=' '
                                _syntax_error 4 || return
                            ;;
                        esac
                    ;;
                    *)
                        is_valid_identifier "$_MODULE" || return
                        _IMPORT_SPEC="${_IMPORT_SPEC:+$_IMPORT_SPEC }$_MODULE"
                        _IMPORT_SPECS="$_IMPORT_SPECS $_MODULE"
                    ;;
                esac
            ;;
            *)
                case $_MODULE in
                    ,)
                        case $# in
                            0)
                                _MODULE_NAME=,
                                _syntax_error 4 || return
                            ;;
                        esac
                        _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_IMPORT_SPEC'"
                        _IMPORT_SPEC=
                        _COUNT=0
                    ;;
                    ,*)
                        set -- "${_MODULE#,}" "$@"
                        _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_IMPORT_SPEC'"
                        _IMPORT_SPEC=
                        _COUNT=0
                    ;;
                    *)
                        false
                    ;;
                esac
            ;;
        esac || {
            _MODULE_NAME=' '
            case $_MODULE in
                ...*)
                    _syntax_error 1 '...'
                ;;
                .*)
                    _syntax_error 1
                ;;
                *)
                    _syntax_error 1 "${_MODULE%%[,.]*}"
                ;;
            esac || return
        }
    done
    case $_IMPORT_SPEC in
        ?*)
            _IMPORT_BUFFER="${_IMPORT_BUFFER:+"$_IMPORT_BUFFER "}'$_IMPORT_SPEC'"
        ;;
    esac
}

_exec_module ()
{
    ERROR=$(2>&1 . "${1:-}") || {
        say "$ERROR"
        return ${SAY_RESULT:-1}
    }
    . "$1" && _LOADED=true
}

_change_module_path ()
{
    _MODULE_PATH=$_MODULE_PATH/$1
    _SUFIX_MODULE_PATH=$_SUFIX_MODULE_PATH/$1
}

_return_module_path ()
{
    _MODULE_PATH=${_MODULE_PATH%$1}
}

_modulenotfounderror ()
{
    echo "  File \"${_FILE_PATH:-$SCRIPT_FILE}\""
    echo "    $_IMPORT_STATEMENT"
    case $1 in
        1)
            echo "ImportError: attempted relative import with no known parent package"
        ;;
        2)
            echo "ModuleNotFoundError: No module named '$_IDENTIFIER'; '$_IDENTIFIER_PART' is not a package"
        ;;
        3)
            str_replace "${2#$PWD}" '/' '.'
            echo "ModuleNotFoundError: No module named '$CORE_RESULT'"
        ;;
    esac
    return 1
}

_locate_module ()
{
    _IDENTIFIER_PART=$1
    eval set -- "$SYS_PATH"
    for SYS_PART_PATH
    do
        _MODULE_PATH="${SYS_PART_PATH:-${_MODULE_PATH:-$SCRIPT_DIR}}"
        is_file "$_MODULE_PATH/$_IDENTIFIER_PART.sh" &&
        _change_module_path "$_IDENTIFIER_PART.sh" || {
            is_dir "$_MODULE_PATH/$_IDENTIFIER_PART" &&
            _change_module_path "$_IDENTIFIER_PART"
        } && break || _MODULE_PATH=
    done
    case $_MODULE_PATH in
        '')
            _modulenotfounderror 1 || return
        ;;
    esac
}

_resolve_module_path ()
{
    _IDENTIFIER=$1
    IFS=.
    set -- $1
    IFS=$POSIX_IFS
    _SUFIX_MODULE_PATH=

    case ${1:-} in
        '')
            shift
            _MODULE_PATH=${_MODULE_PATH:-$SCRIPT_DIR}
            _IDENTIFIER_PART=
        ;;
        *)
            _locate_module "$1" || return
            shift
        ;;
    esac

    for _MODULE_PART_PATH
    do
        is_dir $_MODULE_PATH || _modulenotfounderror 2 || return

        _IDENTIFIER_PART=${_IDENTIFIER_PART:+$_IDENTIFIER_PART.}$_MODULE_PART_PATH
        if is_dir "$_MODULE_PATH/${_MODULE_PART_PATH:=..}"
        then
            _change_module_path "$_MODULE_PART_PATH"
        elif is_file "$_MODULE_PATH/$_MODULE_PART_PATH.sh"
        then
            _change_module_path "$_MODULE_PART_PATH.sh"
        else
            _modulenotfounderror 1 || return
        fi
    done
}

_exec_module ()
{
    set -- "$1" "${_FILE_PATH:-}"
    _FILE_PATH=$1
    . "$1"
    _FILE_PATH=$2
}

_import_function ()
{
    _MODULE_PATH=$1
    _FUNCTION_NAME=$2
    _NEW_FUNCTION_NAME=${3:-$2}

    $_CORE_IMPORT_AS || {
        echo "  File \"${_FILE_PATH:-$SCRIPT_FILE}\""
        echo "    $_IMPORT_STATEMENT"
        echo "ModuleError: [import ... as ...] not implemented"
        return 1
    }

    _FUNCTION=$(
        2>&1 bash -c ". '$_MODULE_PATH' && type '$_FUNCTION_NAME'"
    ) && {
        str_replace "$_FUNCTION" "$_FUNCTION_NAME is a function
$_FUNCTION_NAME" "$_NEW_FUNCTION_NAME"
        eval "$CORE_RESULT"
    } || _modulenotfounderror 3 "$_FUNCTION_NAME"
}

_import_package ()
{
    if is_file "$1/__init__.sh"
    then
        _exec_module "$1/__init__.sh"
    else
        for _MODULE in "$1"/*.sh
        do
            _exec_module "$_MODULE"
        done
    fi
}

_import_module ()
{
    case $# in
        1)
            case ${_MODULE_PATH:-} in
                '')
                    false
                ;;
                *)
                    is_file "$_MODULE_PATH" &&
                    _import_function "$_MODULE_PATH" "$1"
                ;;
            esac || {
                _resolve_module_path "$1" || return
                set -- "$_SUFIX_MODULE_PATH"
                if is_file "$_MODULE_PATH"
                then
                    _exec_module "$_MODULE_PATH"
                    _return_module_path "$1"
                elif is_dir "$_MODULE_PATH"
                then
                    _import_package "$_MODULE_PATH"
                    _return_module_path "$1"
                else
                    _modulenotfounderror 3 "$_MODULE_PATH/$1"
                fi
            }
            return
        ;;
        3)
            _resolve_module_path "$1"
            _import_function "$_MODULE_PATH" "$1" "$3"
            return
        ;;
    esac
}

_import_buffer ()
{
    eval set -- "$_IMPORT_BUFFER"
    _IMPORT_BUFFER=
    for _MODULE
    do
        _import_module $_MODULE
    done
}

import ()
{
    _IMPORT_STATEMENT=import${*:+ $*}
    _IMPORT_COMMAND=import
    _IMPORT_SPECS=
    _MERGE=false
    _check_import_syntax "$@"
    _import_buffer
}

from ()
{
    _IMPORT_STATEMENT=from${*:+ $*}
    _IMPORT_COMMAND=from
    _IMPORT_SPECS=
    _MERGE=false
    _PATH_FROM=${1:-}

    case $# in
        [!0]*)
            shift
        ;;
    esac

    case $_PATH_FROM in
        '')
            _MODULE_NAME=' '
            false
        ;;
        .)
            case ${1:-} in
                import)
                    shift
                    _IMPORT_COMMAND='from . import'
                    _MODULE_NAME=
                    _check_import_syntax "$@" &&
                    _import_buffer || return
                ;;
                *)
                    _MODULE_NAME='. '
                    false
                ;;
            esac
        ;;
        *)
            _MODULE_NAME=
            case $_PATH_FROM in
                *[!.]*)
                    case $_PATH_FROM in
                        .*)
                            is_valid_identifier "${_PATH_FROM#?}"
                        ;;
                        *)
                            is_valid_identifier "$_PATH_FROM"
                        ;;
                    esac || return
                ;;
            esac
            case ${1:-} in
                import)
                    shift
                    _IMPORT_COMMAND="from $_PATH_FROM import"
                    _check_import_syntax "$@" &&
                    _resolve_module_path "$_PATH_FROM" && {
                        set -- "$_SUFIX_MODULE_PATH"
                        _import_buffer && _return_module_path "$1"
                    } || return
                ;;
                *)
                    false
                ;;
            esac
        ;;
    esac || _syntax_error 1 "${1:-}"
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
