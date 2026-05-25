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

set -eu

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

SAY_BATCH=true
case ${KSH_VERSION:-} in
    ?*)
        PUTS_TYPE=print PUTS_ESCAPE=true
        puts ()
        {
            $SAY_ESCAPE && PUTS_FORMAT=-n || PUTS_FORMAT='-n -r'
            $SAY_BATCH && print $PUTS_FORMAT "$*${SAY_SUFFIX:-}" || {
                PUTS="print $PUTS_FORMAT"
                _puts_stream "$*"
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
        $SAY_ESCAPE && PUTS_FORMAT=%b || PUTS_FORMAT=%s
        $SAY_BATCH && printf $PUTS_FORMAT "$*${SAY_SUFFIX:-}" || {
            PUTS="printf $PUTS_FORMAT"
            _puts_stream "$*"
        }
    }
elif type echo
then
    case "X`echo -n`" in
        X-n)
            case "X`echo '\033[0m'`" in
                'X\033[0m')
                    PUTS_ESCAPE=false
                ;;
                *)
                    PUTS_ESCAPE=true
                ;;
            esac

            PUTS_TYPE=echo
            echo_c_helper ()
            {
                echo "$*\c"
            }

            puts ()
            {
                $SAY_BATCH && echo "$*${SAY_SUFFIX:-}\c" || {
                    case ${SAY_SUFFIX:-} in
                        '')
                            SAY_SUFFIX='\c'
                        ;;
                        *)
                            SAY_SUFFIX=
                        ;;
                    esac
                    PUTS=echo_c_helper
                    _puts_stream "$*"
                }
            }
        ;;
        *)
            false
        ;;
    esac ||
    case "X`echo -e`" in
        X-e)
            case "X`echo '\033[0m'`" in
                'X\033[0m')
                    PUTS_ESCAPE=false
                ;;
                *)
                    PUTS_ESCAPE=true
                ;;
            esac

            PUTS_TYPE=echo_n
            puts ()
            {
                $SAY_BATCH && echo -n "$*${SAY_SUFFIX:-}" || {
                    PUTS='echo -n'
                    _puts_stream "$*"
                }
            }
        ;;
        *)
            false
        ;;
    esac || {
        PUTS_ESCAPE=true
        PUTS_TYPE=echo_ne
        puts ()
        {
            $SAY_ESCAPE && PUTS_FORMAT=-ne || PUTS_FORMAT=-n
            $SAY_BATCH && echo $PUTS_FORMAT "$*${SAY_SUFFIX:-}" || {
                PUTS="echo $PUTS_FORMAT"
                _puts_stream "$*"
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

_puts_stream ()
{
    PUTS_LINE=`$PUTS "$*"`${SAY_SUFFIX:-}
    while
        case ${PUTS_LINE:-} in
            '')
                false
            ;;
        esac
    do
        PUTS_CHAR=${PUTS_LINE%"${PUTS_LINE#?}"}
        PUTS_LINE=${PUTS_LINE#?}
        $PUTS "$PUTS_CHAR"
        case $PUTS_CHAR in
            [$C_ALNUM])
                sleep "${SAY_TIMEOUT:-0.05}"
            ;;
        esac
    done
}

PUTS_LENGHT_PREFIX=
SAY_DIVIDER=
SAY_INDENT=
SAY_NEWLINE=
SAY_ESCAPE=$PUTS_ESCAPE
LF='
'

_puts_indented ()
{
    $SAY_PREFIX_INDENT &&
    case ${PUTS_LENGHT_PREFIX:-} in
        ${SAY_LENGHT_INDENT:-0})
        ;;
        *)
            PUTS_LENGHT_PREFIX=${SAY_LENGHT_INDENT:-${#SAY_PREFIX}}
            SAY_COUNT=$PUTS_LENGHT_PREFIX
            SAY_INDENT=
            while
                case $SAY_COUNT in
                    0)
                        false
                    ;;
                esac
            do
                SAY_COUNT=$((SAY_COUNT - 1))
                SAY_INDENT="${SAY_INDENT:-} "
            done
        ;;
    esac &&
    case ${SAY_PREFIX:-} in
        ?*)
            case $((${#SAY_PREFIX} + ${#SAY_DIVIDER})) in
                ${PUTS_LENGHT_PREFIX:-})
                ;;
                *)
                    SAY_COUNT=$((PUTS_LENGHT_PREFIX - ${#SAY_PREFIX}))
                    SAY_DIVIDER=
                    while
                        case $((SAY_COUNT > 0)) in
                            0)
                                false
                            ;;
                        esac
                    do
                        SAY_COUNT=$((SAY_COUNT - 1))
                        SAY_DIVIDER="${SAY_DIVIDER:-} "
                    done
                ;;
            esac
            SAY_PREFIX=$SAY_PREFIX${SAY_DIVIDER:-}
        ;;
    esac &&
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
    esac || :
    case $# in
        [!01])
            SAY_SUFFIX=$LF
            while
                case $# in
                    1)
                        false
                    ;;
                esac
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
    SAY_ESCAPE=false
    SAY_LIST=false
    SAY_NEWLINE=true
    SAY_PREFIX="${LOG_PREFIX:-$0}: "
    SAY_PREFIX_INDENT=false
    SAY_SUFFIX=$LF

    set -- ${SAY_OPTIONS:-} "$@"

    while
        case $# in
            0)
                false
            ;;
        esac
    do
        case ${1:-} in
            -c*)
                case $1 in
                    -c[!\.$C_DIGIT]* | -c[$C_DIGIT]*[!\.$C_DIGIT]* | -c\.*[!$C_DIGIT]* | *\.*\.*)
                        false
                    ;;
                    *)
                        case $CAN_SLEEP:$CAN_SLEEP_FLOAT:${1#??} in
                            true:true:* | true:false:*[!.]*)
                                SAY_BATCH=false
                                SAY_TIMEOUT=${1#??}
                            ;;
                        esac
                    ;;
                esac
            ;;
            *)
                false
            ;;
        esac ||
        case ${1:-} in
            -i*)
                case $1 in
                    -i[!$C_DIGIT]* | -i[$C_DIGIT]*[!$C_DIGIT]*)
                        false
                    ;;
                    *)
                        SAY_PREFIX_INDENT=true
                        SAY_LENGHT_INDENT=${1#??}
                    ;;
                esac
            ;;
            *)
                false
            ;;
        esac ||
        case ${1:-} in
            -e)
                $PUTS_ESCAPE && SAY_ESCAPE=true || :
            ;;
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
            "" | *[!$C_DIGIT]*)
                break
            ;;
            *)
                SAY_RESULT=$1
            ;;
        esac
        shift
    done

    case $SAY_RESULT in
        0)
            EXIT_CODE=${EXIT_CODE:-0}
        ;;
        *)
            EXIT_CODE=$SAY_RESULT
        ;;
    esac

    case $* in
        ?*)
            case $SAY_LIST in
                true)
                    _puts_indented ${1:+"$@"}
                ;;
                *)
                    _puts_indented ${1:+"$*"}
                ;;
            esac

        ;;
    esac
}

_is_interactive_shell ()
{
    case $- in
        *i*)
            return 0
        ;;
        *)
            return 1
        ;;
    esac
}

die ()
{
    say "$@" >&2
    _is_interactive_shell || exit $EXIT_CODE
    set -e
    return $EXIT_CODE
}

 CR=$(puts '\015')
 FF=$(puts '\014')
SOH=$(puts '\001')
TAB=$(puts '\011')
 VT=$(puts '\013')

# --- BASIC CHARACTER CLASSES (ASCII) ---
C_LOWER=abcdefghijklmnopqrstuvwxyz
C_UPPER=ABCDEFGHIJKLMNOPQRSTUVWXYZ
C_DIGIT=0123456789
C_ODIGIT=01234567
C_XDIGIT=${C_DIGIT}abcdefABCDEF
C_PUNCT="!\"#\$%&'()*+,-./:;<=>?@[\\]^_\`{|}~"

C_ALPHA=$C_LOWER$C_UPPER
C_ALNUM=$C_ALPHA$C_DIGIT
C_WORD=_$C_ALNUM

# --- WHITESPACE CLASSES ---
SPACE=' '
C_BLANK=$SPACE$TAB
C_SPACE=$SPACE$TAB$LF$CR$VT$FF
POSIX_IFS=$SPACE$TAB$LF
IFS=$POSIX_IFS

# --- GLOBAL ENVIRONMENT PATH VARIABLES ---
PWD=$(pwd)
SCRIPT_DIR=$(
    _PATH=${0%/*}
    case $0 in
        $_PATH)
            _PATH=$PWD
        ;;
    esac
    2>&1 cd -- "${_PATH:-/}" && 2>&1 pwd -P
) || 
SCRIPT_FILE=${SCRIPT_DIR%/}/${0##*/}
SYS_LIBDIR=/usr/lib/shell
SYS_PATH="'' '$SYS_LIBDIR'"

which ()
{
    IFS=:
    for i in ${PATH:-}
    do
        case $i in
            '')
                i=.
            ;;
        esac
        CORE_RESULT=${i%/}/$1
        test -f "$CORE_RESULT" && {
            IFS=$POSIX_IFS
            test -x "$CORE_RESULT" && return || return 126
        }
    done
    IFS=$POSIX_IFS
    CORE_RESULT=
    return 127
}

_CURRENT_SHELL=
case ${BASH_VERSION:-} in
    '')
        case ${ZSH_VERSION:-} in
            '')
                case ${KSH_VERSION:-} in
                    *MIRBSD*)
                        _CURRENT_SHELL=mksh
                    ;;
                esac
            ;;
            *)
                _CURRENT_SHELL=zsh
            ;;
        esac
    ;;
    *)
        _CURRENT_SHELL=bash
    ;;
esac
case $_CURRENT_SHELL in
    bash | mksh | zsh)
        which "$_CURRENT_SHELL"
        _CURRENT_SHELL=$CORE_RESULT
        _IMPORT_AS=true
        _IMPORT_PREFIX_SEP=.
    ;;
    *)
        _IMPORT_AS=false
        _IMPORT_PREFIX_SEP=_
    ;;
esac

type awk >/dev/null 2>&1 && {
    _IMPORT_TYPE=awk
} || _IMPORT_TYPE=shell

is_diff ()
{
    case ${1:-} in
        ${2:-})
            return 1
        ;;
    esac
}

is_empty ()
{
    case ${1:-} in
        ?*)
            return 1
        ;;
    esac
}

is_not_empty ()
{
    case ${1:-} in
        '')
            return 1
        ;;
    esac
}

is_same ()
{
    case ${1:-} in
        ${2:-})
            return 0
        ;;
    esac
    return 1
}

is_equal ()
{
    case $((${1:-0} == ${2:-0})) in
        0)
            return 1
        ;;
    esac
}

is_greater ()
{
    case $((${1:-0} > ${2:-0})) in
        0)
            return 1
        ;;
    esac
}

is_less ()
{
    case $((${1:-0} < ${2:-0})) in
        0)
            return 1
        ;;
    esac
}

is_digit ()
{
    case ${1:-} in
        *[!$C_DIGIT]*)
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
        case $(id -u 2>/dev/null) in
            0)
                return 0
            ;;
        esac
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
        case ${1:-} in
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

    CORE_RESULT=${1:-}
    while
        case $CORE_RESULT in
            *${2:-}*)
            ;;
            *)
                false
            ;;
        esac
    do
        _CORE_ACCUMULATOR=
        while
            case $CORE_RESULT in
                '')
                    false
                ;;
            esac
        do
            _CORE_LEFT=${CORE_RESULT%%"$2"*}
            case $_CORE_LEFT in
                $CORE_RESULT)
                    break
                ;;
            esac
            _CORE_ACCUMULATOR=$_CORE_ACCUMULATOR$_CORE_LEFT${3:-}
            CORE_RESULT=${CORE_RESULT#*"$2"}
        done
        CORE_RESULT=$_CORE_ACCUMULATOR$CORE_RESULT _CORE_ACCUMULATOR=

        $_CORE_REPLACE_ALL || break
    done
}

get_indent ()
{
    CORE_INDENT_LEN=
    CORE_INDENT=${1:-}
    _CORE_INDENT_CHAR=${2:- }
    case $CORE_INDENT in
        0 | '')
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
        CORE_INDENT=$CORE_INDENT$_CORE_INDENT_CHAR
        _CORE_COUNT=$((_CORE_COUNT + 1))
    done
}

# IMPORT
_get_error ()
{
    case $1 in
        '')
            _CTX_INDENT=
        ;;
        *)
            get_indent ${#1}
            _CTX_INDENT=$CORE_INDENT
        ;;
    esac

    get_indent ${#2} ^
    _CTX_POINTER=$_CTX_INDENT$CORE_INDENT
}

_syntax_error ()
{
    $_CTX_TIGHT &&
        _get_error "    $_CTX_COMMAND $_CTX_SPECS${_MODULE_NAME%%[$C_BLANK]*}" "${2:-.}" ||
        _get_error "    $_CTX_COMMAND${_CTX_SPECS:+ $_CTX_SPECS}${_MODULE_NAME:+ ${_MODULE_NAME%%[$C_BLANK]*}}" "${2:-.}"

    case $1 in
        1)
            set "$_CTX_POINTER" "SyntaxError: invalid syntax"
        ;;
        2)
            set "$_CTX_POINTER" "SyntaxError: leading zeros in decimal integer literals are not permitted"
        ;;
        3)
            set "$_CTX_POINTER" "SyntaxError: invalid decimal literal"
        ;;
        4)
            set "$_CTX_POINTER" "SyntaxError: trailing comma not allowed without surrounding parentheses"
        ;;
    esac

    die -p -l "  File \"${_CTX_FILE:-$SCRIPT_FILE}\"" "    $_CTX_STATEMENT" "$@"
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
        case $_CTX_COMMAND in
            from)
            ;;
            import)
                case $_IMPORT_TOKEN_COUNT in
                    3)
                        $_ONE_MODULE_PART_NAME &&
                         _ONE_MODULE_PART_NAME=false || _syntax_error 1
                    ;;
                esac
            ;;
            *)
                $_ONE_MODULE_PART_NAME &&
                 _ONE_MODULE_PART_NAME=false || _syntax_error 1
            ;;
        esac || return

        case $_MODULE_PART_NAME in
            '')
                _MODULE_NAME=${_MODULE_NAME:- }
                case ${_IDENTIFIER#"${_IDENTIFIER%%.*}"} in
                    ...*)
                        _syntax_error 1 '...'
                    ;;
                    .*)
                        _MODULE_NAME=$_MODULE_NAME.
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
                        _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!$C_DIGIT]*}
                        case $_MODULE_PART_NAME in
                            *[!0]*)
                                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!0]*}
                                _MODULE_NAME=$SPACE
                                _syntax_error 2 "$_MODULE_PART_NAME"
                            ;;
                            *)
                                _MODULE_NAME=${_MODULE_PART_NAME%?}
                                _syntax_error 2
                            ;;
                        esac
                    ;;
                    *)
                        _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!$C_DIGIT]*}
                        _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}${_MODULE_PART_NAME%?}
                        _syntax_error 3
                    ;;
                esac
            ;;
            [123456789]*)
                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!$C_DIGIT]*}
                _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}${_MODULE_PART_NAME%?}
                _MODULE_NAME=${_MODULE_NAME:- }
                _syntax_error 3
            ;;
            [!_$C_ALPHA]*)
                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!_$C_ALPHA]*}
                _MODULE_NAME=${_MODULE_NAME:+$_MODULE_NAME.}
                _syntax_error 1 "$_MODULE_PART_NAME"
            ;;
            case | do | done | elif | else | 'esac' | fi | for | from | function | if | import | in | then | until | while)
                case $_MODULE_NAME in
                    '')
                        _MODULE_NAME=$SPACE
                    ;;
                    *)
                        _MODULE_NAME=$_MODULE_NAME.
                    ;;
                esac
                _syntax_error 1 "$_MODULE_PART_NAME"
            ;;
            *[!$C_WORD]*)
                _MODULE_PART_NAME=${_MODULE_PART_NAME%%[!$C_WORD]*}
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
    _CTX_BUFFER=
    _CTX_SPEC=

    case $# in
        0)
            _MODULE_NAME=$SPACE
            _syntax_error 1 || return
        ;;
    esac

    _IMPORT_TOKEN_COUNT=0
    while
        case $# in
            0)
                false
            ;;
        esac
    do
        _MODULE=$1
        shift

        _IMPORT_TOKEN_COUNT=$((_IMPORT_TOKEN_COUNT + 1))
        case $_IMPORT_TOKEN_COUNT in
            1)
                case $_MODULE in
                    ,*)
                        _MODULE_NAME=$SPACE
                        _syntax_error 1 || return
                    ;;
                    *,?*)
                        set -- "${_MODULE#*,}" "$@"
                        _MODULE=${_MODULE%%,*}
                        is_valid_identifier "$_MODULE" || return
                        _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_MODULE'"
                        _IMPORT_TOKEN_COUNT=0
                        $_CTX_TIGHT &&
                            _CTX_SPECS=$_CTX_SPECS$_MODULE, ||
                            _CTX_SPECS=${_CTX_SPECS:+$_CTX_SPECS }$_MODULE,
                        _CTX_TIGHT=true
                    ;;
                    *,)
                        _MODULE=${_MODULE%,}
                        is_valid_identifier "$_MODULE" || return
                        _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_MODULE'"
                        _IMPORT_TOKEN_COUNT=0
                        $_CTX_TIGHT &&
                            _CTX_SPECS=$_CTX_SPECS$_MODULE, ||
                            _CTX_SPECS=${_CTX_SPECS:+$_CTX_SPECS }$_MODULE,
                        _CTX_TIGHT=false
                    ;;
                    *)
                        is_valid_identifier "$_MODULE" || return
                        _CTX_SPEC=${_CTX_SPEC:+$_CTX_SPEC }$_MODULE
                        $_CTX_TIGHT &&
                            _CTX_SPECS=$_CTX_SPECS$_MODULE ||
                            _CTX_SPECS=${_CTX_SPECS:+$_CTX_SPECS }$_MODULE
                        _CTX_TIGHT=false
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
                                _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }${_CTX_SPEC:+"'$_CTX_SPEC' "}'$_MODULE'"
                                _CTX_SPEC=
                                _CTX_SPECS=${_CTX_SPECS:+$_CTX_SPECS },$_MODULE,
                                _IMPORT_TOKEN_COUNT=0
                                _CTX_TIGHT=true
                            ;;
                            *,)
                                _MODULE=${_MODULE#,}
                                _MODULE=${_MODULE%,}
                                is_valid_identifier "$_MODULE" || return
                                _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }${_CTX_SPEC:+"'$_CTX_SPEC' "}'$_MODULE'"
                                _CTX_SPEC=
                                _CTX_SPECS="$_CTX_SPECS ,$_MODULE,"
                                _IMPORT_TOKEN_COUNT=0
                            ;;
                            *)
                                _MODULE_NAME=,
                                is_valid_identifier "${_MODULE#,}" || return
                                _CTX_SPEC=${_CTX_SPEC:+$_CTX_SPEC }$_MODULE
                                _CTX_SPECS=${_CTX_SPECS:+$_CTX_SPECS }$_MODULE
                                _IMPORT_TOKEN_COUNT=1
                            ;;
                        esac
                    ;;
                    ,)
                        _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_CTX_SPEC'"
                        _CTX_SPEC=
                        _CTX_SPECS="$_CTX_SPECS ,"
                        _IMPORT_TOKEN_COUNT=0
                    ;;
                    as)
                        case $# in
                            0)
                                _MODULE_NAME=as
                                _syntax_error 1 || return
                            ;;
                            *)
                                _CTX_SPEC="$_CTX_SPEC as"
                                _CTX_SPECS="$_CTX_SPECS as"
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
                        _MODULE_NAME=$SPACE
                        _syntax_error 1 || return
                    ;;
                    *,?*)
                        set -- "${_MODULE#*,}" "$@"
                        _MODULE=${_MODULE%%,*}
                        is_valid_identifier "$_MODULE" || return
                        _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_CTX_SPEC $_MODULE'"
                        _CTX_SPEC=
                        _CTX_SPECS="$_CTX_SPECS $_MODULE,"
                        _CTX_TIGHT=true
                        _IMPORT_TOKEN_COUNT=0
                    ;;
                    *,)
                        _MODULE=${_MODULE%,}
                        is_valid_identifier "$_MODULE" || return
                        _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_CTX_SPEC $_MODULE'"
                        _CTX_SPEC=
                        _CTX_SPECS="$_CTX_SPECS $_MODULE,"
                        _IMPORT_TOKEN_COUNT=0
                        case $# in
                            0)
                                _MODULE_NAME=$SPACE
                                _syntax_error 4 || return
                            ;;
                        esac
                    ;;
                    *)
                        is_valid_identifier "$_MODULE" || return
                        _CTX_SPEC=${_CTX_SPEC:+$_CTX_SPEC }$_MODULE
                        _CTX_SPECS="$_CTX_SPECS $_MODULE"
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
                        _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_CTX_SPEC'"
                        _CTX_SPEC=
                        _IMPORT_TOKEN_COUNT=0
                    ;;
                    ,*)
                        set -- "${_MODULE#,}" "$@"
                        _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_CTX_SPEC'"
                        _CTX_SPEC=
                        _IMPORT_TOKEN_COUNT=0
                    ;;
                    *)
                        false
                    ;;
                esac
            ;;
        esac || {
            _MODULE_NAME=$SPACE
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

    case $_CTX_SPEC in
        ?*)
            _CTX_BUFFER="${_CTX_BUFFER:+$_CTX_BUFFER }'$_CTX_SPEC'"
        ;;
    esac
}

_push_module_path ()
{
    _MODULE_PATH=$_MODULE_PATH/$1
    _SUFFIX_MODULE_PATH=$_SUFFIX_MODULE_PATH/$1
}

_pop_module_path ()
{
    _MODULE_PATH=${_MODULE_PATH%"$1"}
}

_IMPORT_PREFIX_NAME=
_push_prefix_name ()
{
    _IMPORT_PREFIX_NAME=${_IMPORT_PREFIX_NAME:+$_IMPORT_PREFIX_NAME$_IMPORT_PREFIX_SEP}$1
}

_pop_prefix_name ()
{
    case $1 in
        ..)
            _IMPORT_PREFIX_NAME=${_IMPORT_PREFIX_NAME%"$_IMPORT_PREFIX_SEP"*}
        ;;
        *)
            _IMPORT_PREFIX_NAME=${_IMPORT_PREFIX_NAME%"$_IMPORT_PREFIX_SEP${1%.sh}"}
        ;;
    esac
}

_modulenotfounderror ()
{
    case $1 in
        0)
            set "ModuleError: 'import ... as ...' not supported in this shell (requires bash|mksh|zsh)"
        ;;
        1)
            set "ImportError: attempted relative import with no known parent package"
        ;;
        2)
            set "ModuleNotFoundError: No module named '$_IDENTIFIER'; '$_IDENTIFIER_PART' is not a package"
        ;;
        3)
            str_replace "${2#"$PWD"}" / .
            set "ModuleNotFoundError: No module named '$CORE_RESULT'"
        ;;
        4)
            set "ImportError: cannot import name '$2' from '${_CTX_PATH_FROM:-$_IDENTIFIER}' ($_MODULE_PATH)"
        ;;
    esac

    die -p -l "  File \"${_CTX_FILE:-$SCRIPT_FILE}\"" "    $_CTX_STATEMENT" "$@"
}

_locate_module ()
{
    _IDENTIFIER_PART=$1
    eval set -- "$SYS_PATH"

    for SYS_PART_PATH
    do
        _MODULE_PATH=${SYS_PART_PATH:-${_MODULE_PATH:-$SCRIPT_DIR}}
        is_file "$_MODULE_PATH/$_IDENTIFIER_PART.sh" &&
        _push_module_path "$_IDENTIFIER_PART.sh" || {
            is_dir "$_MODULE_PATH/$_IDENTIFIER_PART" &&
            _push_module_path "$_IDENTIFIER_PART"
        } && break || _MODULE_PATH=
    done

    case $_MODULE_PATH in
        '')
            _modulenotfounderror 1
        ;;
    esac
}

_resolve_module_path ()
{
    _IDENTIFIER=$1
    IFS=.
    set -- $1
    IFS=$POSIX_IFS
    _SUFFIX_MODULE_PATH=

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
        case $_MODULE_PART_PATH in
            '')
                is_dir "$_MODULE_PATH/.." &&
                _push_module_path '..'
                _IDENTIFIER_PART=${_IDENTIFIER_PART:+$_IDENTIFIER_PART.}$_MODULE_PART_PATH
            ;;
            *)
                is_file "$_MODULE_PATH/$_MODULE_PART_PATH.sh" &&
                _push_module_path "$_MODULE_PART_PATH.sh" && {
                    _IDENTIFIER_PART=${_IDENTIFIER_PART:+$_IDENTIFIER_PART.}$_MODULE_PART_PATH
                    break
                } || {
                    is_dir "$_MODULE_PATH/$_MODULE_PART_PATH" &&
                    _push_module_path "$_MODULE_PART_PATH"
                } || break
            ;;
        esac || _modulenotfounderror 1 || return
    done
}

_import_module_awk ()
{
    _MODULE_FUNCS=$(
        2>&1 awk '
            BEGIN {
                in_heredoc = 0
                hd_token = ""
                soh = "'"${SOH:-}"'"
                bash_env_list = "'"${_BASH_ENV_LIST:-}"'"
                split(bash_env_list, bash_env, " ")
                for (x in bash_env) env_vars[bash_env[x]] = 1

                _function_list = "'" ${_FUNCTION_LIST:-} "'"

                # PARSE ALIAS MAP: from "FUNC_MAP: func1:func1 func2:boo"
                f_map = "'"${_FUNCTION_MAP:-}"'"
                if (f_map ~ /^FUNC_MAP:/) {
                    sub(/^FUNC_MAP:[ \t]*/, "", f_map)
                    split(f_map, pairs, " ")
                    for (p in pairs) {
                        split(pairs[p], kv, ":")
                        alias_map[kv[1]] = kv[2]
                    }
                }
            }
            {
                lines[NR] = $0
                _SKIP_PARSING = 0

                if (in_heredoc) {
                    _SKIP_PARSING = 1
                    trimmed = $0; sub(/^[ \t]+/, "", trimmed)
                    if ($0 == hd_token || trimmed == hd_token) { in_heredoc = 0; hd_token = "" }
                    next
                } else if (match($0, /<<-?[ \t]*[\047"\042\\]?[a-zA-Z0-9_]+[\047"\042]?/)) {
                    # Added \\ to regex above for detecting <<\FILE
                    _SKIP_PARSING = 1; in_heredoc = 1
                    chunk = substr($0, RSTART, RLENGTH)
                    sub(/^<<-?/, "", chunk)
                    # Clean token from quotes and backslash
                    gsub(/[ \t\047"\042\\]/, "", chunk)
                    hd_token = chunk
                }
                if (_SKIP_PARSING) next

                clean = $0; gsub(/(^|[ \t;])#.*/, "\\1", clean)
                if (clean_total == "") clean_total = clean
                else clean_total = clean_total soh clean
            }
            END {
                f_prefix = "'"${_IMPORT_PREFIX_NAME:-}${_IMPORT_PREFIX_SEP:-}"'"
                v_prefix = "'"${_IMPORT_PREFIX_NAME:-}"'_"
                gsub(/\./, "_", v_prefix)

                # Initialize filter gateway
                use_filter = 0
                print_zone = 1
                if (_function_list != "") {
                    use_filter = 1
                    print_zone = 0
                    split(_function_list, ft, " ")
                    for (f in ft) targets_arr[ft[f]] = 1
                }
                o_br = 0; c_br = 0; close_func_now = 0

                # --- PASS 1: CHARACTER-BY-CHARACTER MODULE FUNCTION COLLECTION ---
                t_len = length(clean_total)
                expect_func = 0
                for (pos = 1; pos <= t_len; pos++) {
                    ch = substr(clean_total, pos, 1)
                    if (ch ~ /[a-zA-Z_]/) {
                        word = ""
                        w_start = pos
                        while (pos <= t_len && substr(clean_total, pos, 1) ~ /[a-zA-Z0-9_.]/) {
                            word = word substr(clean_total, pos, 1)
                            pos++
                        }
                        pos--

                        if (word == "function") { expect_func = 1; continue }
                        if (env_vars[word]) { expect_func = 0; continue }

                        prev_ch = (w_start > 1) ? substr(clean_total, w_start - 1, 1) : ""
                        if (prev_ch == "/") { expect_func = 0; continue }

                        # Strict lookahead for empty parentheses on Pass 1
                        t_ptr = pos + 1
                        while (t_ptr <= t_len) {
                            next_ch = substr(clean_total, t_ptr, 1)
                            if (next_ch == " " || next_ch == "\t" || next_ch == soh) t_ptr++
                            else break
                        }

                        is_a_func = 0
                        next_ch = substr(clean_total, t_ptr, 1)
                        if (next_ch == "(") {
                            t_ptr++
                            while (t_ptr <= t_len) {
                                nt_ch = substr(clean_total, t_ptr, 1)
                                if (nt_ch == " " || nt_ch == "\t" || nt_ch == soh) t_ptr++
                                else break
                            }
                            if (substr(clean_total, t_ptr, 1) == ")") is_a_func = 1
                        } else if (next_ch == "{" && expect_func == 1) {
                            is_a_func = 1
                        } else if (expect_func == 1) {
                            # Character-by-character function body lookahead (protection against cat, grep, ls)
                            tail_ptr = pos + 1
                            while (tail_ptr <= t_len) {
                                nt_ch = substr(clean_total, tail_ptr, 1)
                                if (nt_ch == " " || nt_ch == "\t" || nt_ch == soh || nt_ch == ";") { tail_ptr++; continue }
                                if (nt_ch == "{") { is_a_func = 1; break }
                                break
                            }
                        }

                        if (is_a_func) names[word] = 1
                        expect_func = 0
                    }
                }

                if (use_filter) {
                    for (t in targets_arr) {
                        if (!(t in names)) {
                            # Erase everything, output only lost function name and exit with system code 1
                            print t
                            exit 1
                        }
                    }
                }

                # --- PASS 2: GENERATE OUTPUT ---
                for (i = 1; i <= NR; i++) {
                    line = lines[i]
                    if (in_heredoc) {
                        print line; trimmed = line; sub(/^[ \t]+/, "", trimmed)
                        if (line == hd_token || trimmed == hd_token) { in_heredoc = 0; hd_token = "" }
                        continue
                    }
                    if (match(line, /<<-?[ \t]*[\047"\042\\]?[a-zA-Z0-9_]+[\047"\042]?/)) {
                        in_heredoc = 1; chunk = substr(line, RSTART, RLENGTH)
                        sub(/^<<-?/, "", chunk); gsub(/[ \t\047"\042\\]/, "", chunk); hd_token = chunk
                        print line; continue
                    }
                    code_part = line; comment_part = ""
                    if (match(line, /(^|[ \t;])#.*/)) {
                        match_pos = RSTART; if (substr(line, RSTART, 1) != "#") match_pos++
                        code_part = substr(line, 1, match_pos - 1); comment_part = substr(line, match_pos)
                    }

                    new_code = ""; c_len = length(code_part); s_quotes = 0; d_quotes = 0; expect_var = 0; unset_mode = ""

                    for (c_pos = 1; c_pos <= c_len; c_pos++) {
                        curr_ch = substr(code_part, c_pos, 1)

                        if (curr_ch == "\047" && d_quotes == 0) { s_quotes = (s_quotes == 0) ? 1 : 0; new_code = new_code curr_ch; continue }
                        if (curr_ch == "\042" && s_quotes == 0) { d_quotes = (d_quotes == 0) ? 1 : 0; new_code = new_code curr_ch; continue }

                        if (s_quotes == 1) {
                            if (curr_ch ~ /[a-zA-Z_]/ && unset_mode != "") {
                                word = ""
                                while (c_pos <= c_len && substr(code_part, c_pos, 1) ~ /[a-zA-Z0-9_]/) { word = word substr(code_part, c_pos, 1); c_pos++ }
                                remain_tail = substr(code_part, c_pos)
                                full_word = word
                                if (remain_tail ~ /^\.[a-zA-Z_]/) {
                                    sub(/^\./, "", remain_tail); match(remain_tail, /^[a-zA-Z0-9_]/)
                                    full_word = word "." substr(remain_tail, RSTART, RLENGTH)
                                    c_pos += (RLENGTH + 1)
                                }
                                c_pos--

                                # MAP: function name replacement in single quotes (e.g., unset 'func2')
                                if (unset_mode == "f" && alias_map[full_word] != "") {
                                    new_code = new_code f_prefix alias_map[full_word]
                                } else if (unset_mode == "f") {
                                    new_code = new_code f_prefix full_word
                                } else {
                                    new_code = new_code v_prefix full_word
                                }
                            } else {
                                new_code = new_code curr_ch
                            }
                            continue
                        }

                        if (curr_ch == "$") { expect_var = 1; new_code = new_code curr_ch; continue }

                        if (curr_ch ~ /[a-zA-Z_]/) {
                            word = ""
                            w_start = c_pos
                            while (c_pos <= c_len && substr(code_part, c_pos, 1) ~ /[a-zA-Z0-9_.]/) {
                                word = word substr(code_part, c_pos, 1)
                                c_pos++
                            }
                            c_pos--

                            remain_tail = substr(code_part, c_pos + 1)
                            is_func_decl = (remain_tail ~ /^[ \t]*\([ \t]*\)/) ? 1 : 0
                            is_assignment = (remain_tail ~ /^=/) ? 1 : 0

                            # For arrays, check for [index]= immediately after the word
                            if (!is_assignment) is_assignment = (remain_tail ~ /^\[[^\]]+\]=/) ? 1 : 0

                            next_char = substr(code_part, w_start + length(word), 1)
                            prev_ch_code = (length(new_code) > 0) ? substr(new_code, length(new_code), 1) : ""

                            if (prev_ch_code == "-") {
                                last_flag = substr(word, length(word), 1)
                                if (last_flag == "f" || last_flag == "v") unset_mode = last_flag
                                new_code = new_code word
                            } else if (word == "unset") {
                                unset_mode = "v"
                                new_code = new_code word
                            } else if (env_vars[word]) {
                                new_code = new_code word
                            } else if (prev_ch_code == "/") {
                                new_code = new_code word
                            } else if (unset_mode != "") {
                                # MAP: when function is removed via unset -f func2
                                if (unset_mode == "f" && alias_map[word] != "") new_code = new_code f_prefix alias_map[word]
                                else if (unset_mode == "f") new_code = new_code f_prefix word
                                else new_code = new_code v_prefix word
                            } else if (expect_var == 1 || is_assignment == 1) {
                                # Replacement happens EXCLUSIVELY based on dynamic string context!
                                new_code = new_code v_prefix word
                            } else if (is_func_decl == 1 || names[word] == 1) {
                                # INSERT: encountered declaration of requested function
                                if (use_filter && targets_arr[word]) {
                                    print_zone = 1
                                    o_br = 0; c_br = 0; close_func_now = 0
                                    # Remember the remainder of the line strictly AFTER the function name
                                    body_tail = substr(code_part, c_pos + 1)

                                    # SURGICAL CLEANING OF DIRT IN AWK:
                                    # Check declaration style based on accumulated new_code
                                    if (new_code ~ /function/) {
                                        # Ksh style: keep only the keyword
                                        new_code = "function "
                                    } else {
                                        # POSIX style: completely erase other history
                                        new_code = ""
                                    }
                                }
                                # MAP: Intercept function declaration and call from alias map
                                target_word = (alias_map[word] != "") ? alias_map[word] : word
                                if (d_quotes == 1) new_code = new_code target_word
                                else new_code = new_code f_prefix target_word
                            } else {
                                new_code = new_code word
                            }
                            expect_var = 0
                        } else {
                            if (curr_ch != " " && curr_ch != "\t" && curr_ch != "{" && curr_ch != "#") expect_var = 0
                            if (curr_ch == ";" || curr_ch == "&" || curr_ch == "|") unset_mode = ""
                            new_code = new_code curr_ch
                        }
                    }
                    # Count curly braces for current line in print zone
                    if (print_zone == 1) {
                        # Take clean original line from file
                        br_line = (body_tail != "") ? body_tail : lines[i]
                        # clear for subsequent lines
                        body_tail = ""

                        # SURGICAL LINE CLEANING:
                        # strip comments
                        gsub(/(^|[ \t;])#.*/, "", br_line)
                        # completely remove ALL variable substitutions ${...}
                        gsub(/\$\{[^\}]+\}/, "", br_line)
                        # ignore closing of esac construct
                        gsub(/^[ \t]*esac[ \t;{]*$/, "", br_line)

                        # Count clean opening braces
                        o_line = br_line
                        o_br += gsub(/\{/, "{", o_line)

                        # Count clean closing braces
                        c_line = br_line
                        c_br += gsub(/\}/, "}", c_line)

                        if (o_br > 0 && o_br <= c_br) {
                            close_func_now = 1
                        }
                    }

                    # OUTPUT GATE
                    if (print_zone == 1 || use_filter == 0) {
                        print new_code comment_part
                    }

                    if (close_func_now == 1) {
                        print_zone = 0; o_br = 0; c_br = 0; close_func_now = 0
                    }
                }
            }
        ' <<_MODULE_BODY
$_MODULE_BODY
_MODULE_BODY
    )
}

_import_module_shell ()
{
    case $_IMPORT_PREFIX_SEP in
        _)
            _F_PREFIX=${_IMPORT_PREFIX_NAME}_
            _V_PREFIX=${_IMPORT_PREFIX_NAME}_
        ;;
        .)
            _F_PREFIX=${_IMPORT_PREFIX_NAME}.
            str_replace "$_IMPORT_PREFIX_NAME" . _
            _V_PREFIX=${CORE_RESULT}_
        ;;
    esac

    # --- PARSE ALIAS MAP FOR FUNCTION IMPORT ---
    _USE_MAP=0
    case ${_FUNCTION_MAP:-} in
        FUNC_MAP:*)
            _USE_MAP=1
            _MAP_DATA=${_FUNCTION_MAP#FUNC_MAP:$SPACE}
        ;;
    esac

    _ALL_LINES=
    _CURRENT_TARGET=
    _LIST_FUNCS=$SPACE
    _IN_HEREDOC=0
    _HD_TOKEN=
    _MODULE_FUNCS=

    # --- PASS 1: CHARACTER-BY-CHARACTER COLLECTION OF EXPLICITLY DECLARED FUNCTIONS ---
    IFS=
    while read -r _RAW_LINE ||
        case $_RAW_LINE in
            '')
                false
            ;;
        esac
    do
        # --- FUNCTION FILTERING AT PASS 1 STAGE ---
        _MARKER=
        case ${_FUNCTION_LIST:+$_CURRENT_TARGET} in
            ?*)
                # If inside target function, mark line with marker
                _MARKER=_KEEP_:
            ;;
        esac

        case $_ALL_LINES in
            '')
                _ALL_LINES=$_MARKER$_RAW_LINE
            ;;
            *)
                _ALL_LINES=$_ALL_LINES$SOH$_MARKER$_RAW_LINE
            ;;
        esac

        _CLEAN_LINE=${_RAW_LINE%%#*}
        _REST_PARSE=$_CLEAN_LINE
        _EXPECT_FUNC=0
        while
            case $_REST_PARSE in
                '')
                    false
                ;;
            esac
        do
            _CURR_CH=${_REST_PARSE%"${_REST_PARSE#?}"}
            case $_CURR_CH in
                [_$C_ALPHA])
                    _WORD=
                    while
                        case $_REST_PARSE in
                            '')
                                false
                            ;;
                        esac
                    do
                        _W_CH=${_REST_PARSE%"${_REST_PARSE#?}"}
                        case $_W_CH in
                            [\.$C_WORD])
                                _WORD=$_WORD$_W_CH
                                _REST_PARSE=${_REST_PARSE#?}
                            ;;
                            *)
                                break
                            ;;
                        esac
                    done

                    case $_WORD in
                        function)
                            _EXPECT_FUNC=1
                            continue
                        ;;
                    esac

                    case $_BASH_ENV_LIST in
                        *" $_WORD "*)
                            _EXPECT_FUNC=0
                            continue
                        ;;
                    esac

                    _TAIL=$_REST_PARSE
                    _IS_A_FUNC=0
                    while
                        case $_TAIL in
                            '')
                                false
                            ;;
                        esac
                    do
                        _T_CH=${_TAIL%"${_TAIL#?}"}
                        case $_T_CH in
                            $SPACE | $TAB)
                                _TAIL=${_TAIL#?}
                            ;;
                            *)
                                break
                            ;;
                        esac
                    done

                    case ${_TAIL%"${_TAIL#?}"} in
                        '(')
                            _TAIL=${_TAIL#?}
                            while
                                case $_TAIL in
                                    '')
                                        false
                                    ;;
                                esac
                            do
                                _T_CH=${_TAIL%"${_TAIL#?}"}
                                case $_T_CH in
                                    $SPACE | $TAB)
                                        _TAIL=${_TAIL#?}
                                    ;;
                                    *)
                                        break
                                    ;;
                                esac
                            done

                            case ${_TAIL%"${_TAIL#?}"} in
                                ')')
                                    _IS_A_FUNC=1
                                    _REST_PARSE=${_TAIL#?}
                                ;;
                            esac
                        ;;
                        *)
                            case $_EXPECT_FUNC in
                                1)
                                    # Check command tail cleanliness for function name
                                    _F_TAIL=$_TAIL
                                    _IS_CLEAN_LINE=1
                                    while
                                        case $_F_TAIL in
                                            '')
                                                false
                                            ;;
                                        esac
                                    do
                                        _FT_CH=${_F_TAIL%"${_F_TAIL#?}"}
                                        case $_FT_CH in
                                            [\;{] | $SPACE | $TAB)
                                                _F_TAIL=${_F_TAIL#?}
                                            ;;
                                            *)
                                                _IS_CLEAN_LINE=0
                                                break
                                            ;;
                                        esac
                                    done

                                    case $_IS_CLEAN_LINE in
                                        1)
                                            _IS_A_FUNC=1
                                        ;;
                                    esac
                                ;;
                            esac
                        ;;
                    esac

                    case $_IS_A_FUNC in
                        1)
                            case $_LIST_FUNCS in
                                *" $_WORD "*)
                                ;;
                                *)
                                    _LIST_FUNCS=$_LIST_FUNCS$_WORD$SPACE
                                ;;
                            esac

                            # INSERT: Character parser found target function
                            case " ${_FUNCTION_LIST:-} " in
                                *" $_WORD "*)
                                    _CURRENT_TARGET=$_WORD
                                    # Since the function header is on the CURRENT line,
                                    # we must retroactively mark it with a preservation marker,
                                    # if not already marked
                                    case $_ALL_LINES in
                                        _KEEP_*)
                                        ;;
                                        *)
                                            case $_ALL_LINES in
                                                *$SOH*)
                                                    _ALL_PREV=${_ALL_LINES%"$SOH"*}
                                                    _ALL_CURR=${_ALL_LINES##*"$SOH"}
                                                    _ALL_LINES=$_ALL_PREV${SOH}_KEEP_:$_ALL_CURR
                                                ;;
                                                *)
                                                    _ALL_LINES=_KEEP_:$_ALL_LINES
                                                ;;
                                            esac
                                        ;;
                                    esac
                                ;;
                            esac
                        ;;
                    esac
                    _EXPECT_FUNC=0
                ;;
                '&' | ';' | '|')
                    # Reset function expectation flag on hard command separators, spaces and tabs within same command preserve it
                    _EXPECT_FUNC=0
                    _REST_PARSE=${_REST_PARSE#?}
                ;;
                *)
                    _REST_PARSE=${_REST_PARSE#?}
                ;;
            esac
        done

        case $_CLEAN_LINE in
            *unset*[-$C_WORD]*)
                _U_TAIL=${_CLEAN_LINE#*unset}
                _U_REST=$_U_TAIL
                _U_MODE=
                while
                    case $_U_REST in
                        '')
                            false
                        ;;
                    esac
                do
                    _U_CH=${_U_REST%"${_U_REST#?}"}
                    case $_U_CH in
                        [_$C_ALPHA])
                            _U_WORD=
                            while
                                case $_U_REST in
                                    '')
                                        false
                                    ;;
                                esac
                            do
                                _UW_CH=${_U_REST%"${_U_REST#?}"}
                                case $_UW_CH in
                                    # decreasing the correct _U_REST variable
                                    [\.$C_WORD])
                                        _U_WORD=$_U_WORD$_UW_CH
                                        _U_REST=${_U_REST#?}
                                    ;;
                                    *)
                                        break
                                    ;;
                                esac
                            done

                            _U_PREV_CHAR=
                            _U_NEW_PART=${_U_TAIL%"$_U_REST"}
                            _U_NEW_PART=${_U_NEW_PART%"$_U_WORD"}
                            case $_U_NEW_PART in
                                ?*)
                                    _U_PREV_CHAR=${_U_NEW_PART#"${_U_NEW_PART%?}"}
                                ;;
                            esac

                            case $_U_PREV_CHAR in
                                -)
                                    _LAST_F=${_U_WORD#"${_U_WORD%?}"}
                                    case $_LAST_F in
                                        [fv])
                                            _U_MODE=$_LAST_F
                                        ;;
                                    esac
                                ;;
                                *)
                                    case $_U_MODE in
                                        f)
                                            case $_U_WORD in
                                                '' | unset)
                                                ;;
                                                *)
                                                    case $_LIST_FUNCS in
                                                        *" $_U_WORD "*)
                                                        ;;
                                                        *)
                                                            _LIST_FUNCS=$_LIST_FUNCS$_U_WORD$SPACE
                                                        ;;
                                                    esac
                                                ;;
                                            esac
                                        ;;
                                    esac
                                ;;
                            esac
                            ;;
                        '&' | ';' | '|')
                            _U_MODE=
                            _U_REST=${_U_REST#?}
                        ;;
                        *)
                            _U_REST=${_U_REST#?}
                        ;;
                    esac
                done
            ;;
        esac

        # If function closed (} character on line without indentation)
        case ${_CURRENT_TARGET:+${_RAW_LINE##[$SPACE$TAB]*}} in
            '}')
                _CURRENT_TARGET=
            ;;
        esac
    done <<_MODULE_BODY
$_MODULE_BODY
_MODULE_BODY
    IFS=$POSIX_IFS

    # --- INITIALIZE PRINT GATE ---
    case ${_FUNCTION_LIST:-} in
        '')
            # Bulk import: gate always open
            _PRINT_ZONE=1
        ;;
        *)
            # Iterate over requested targets stored in $_FUNCTION_LIST with space separation
            for _TARGET in $_FUNCTION_LIST
            do
                case $_LIST_FUNCS in
                    *" $_TARGET "*)
                        # Found, great
                    ;;
                    *)
                        # Not found - write its name to buffer and exit with error
                        _MODULE_FUNCS=$_TARGET
                        return 1
                    ;;
                esac
            done
            # Single import: gate locked, waiting for function
            _PRINT_ZONE=0
        ;;
    esac

    # --- PASS 2: REPLACEMENT TOKENIZER WITH ACCUMULATION INTO VARIABLE ---
    _IN_HEREDOC=0
    _HD_TOKEN=
    _REST_LINES=$_ALL_LINES
    _O_BR=0 _C_BR=0
    while
        case $_REST_LINES in
            '')
                false
            ;;
        esac
    do
        case $_REST_LINES in
            *$SOH*)
                _LINE=${_REST_LINES%%"$SOH"*}
                _REST_LINES=${_REST_LINES#*"$SOH"}
            ;;
            *)
                _LINE=$_REST_LINES
                _REST_LINES=
        esac

        # Intercept line marker immediately after extraction!
        _SHOULD_PRINT=0
        case $_LINE in
            _KEEP_:*)
                _SHOULD_PRINT=1
                _LINE=${_LINE#_KEEP_:}
            ;;
        esac

        case $_IN_HEREDOC in
            1)
                _MODULE_FUNCS=${_MODULE_FUNCS:+$_MODULE_FUNCS$LF}$_LINE
                _TRIMMED_LINE=${_LINE##[$SPACE$TAB]*}
                case $_HD_TOKEN in
                    $_LINE | $_TRIMMED_LINE)
                        _IN_HEREDOC=0
                        _HD_TOKEN=
                    ;;
                esac
                continue
            ;;
        esac

        _IS_HD_START=0
        case $_LINE in
            *'<<-'* | *'<<'* )
                _HD_PART=
                case $_LINE in
                    *'<<-'*)
                        _HD_PART=${_LINE#*<<-}
                    ;;
                    *'<<'*)
                        _HD_PART=${_LINE#*<<}
                    ;;
                esac
                _HD_PART=${_HD_PART##[$SPACE$TAB]*}
                _RAW_TOKEN=${_HD_PART%%[$SPACE$TAB;]*}

                _CLEAN_TOKEN=
                _T_REST=$_RAW_TOKEN
                while
                    case $_T_REST in
                        '')
                            false
                        ;;
                    esac
                do
                    _T_CH=${_T_REST%"${_T_REST#?}"}
                    case $_T_CH in
                        "'" | '"' | '\' )
                            # NOW RESET BACKSLASH \
                        ;;
                        *)
                            _CLEAN_TOKEN=$_CLEAN_TOKEN$_T_CH
                        ;;
                    esac
                    _T_REST=${_T_REST#?}
                done

                case $_CLEAN_TOKEN in
                    ?*)
                        _IN_HEREDOC=1
                        _HD_TOKEN=$_CLEAN_TOKEN
                        _IS_HD_START=1
                    ;;
                esac
            ;;
        esac

        case $_IS_HD_START in
            1)
                _MODULE_FUNCS=${_MODULE_FUNCS:+$_MODULE_FUNCS$LF}$_LINE
                continue
            ;;
        esac

        _CODE_PART=$_LINE
        _COMM_PART=
        case $_LINE in
            *#*)
                _BEFORE_HASH=${_LINE%%#*}
                case $_BEFORE_HASH in
                    *\${*)
                        _CODE_PART=$_LINE
                        _COMM_PART=
                    ;;
                    *)
                        _CODE_PART=${_LINE%%#*}
                        _COMM_PART=#${_LINE#*#}
                    ;;
                esac
            ;;
        esac

        _NEW_LINE=
        _REST=$_CODE_PART
        _S_QUOTES=0
        _D_QUOTES=0
        _EXPECT_VAR=0
        _WORD=
        _UNSET_MODE=
        while
            case $_REST in
                '')
                    false
                ;;
            esac
        do
            _CH=${_REST%"${_REST#?}"}
            _REST=${_REST#?}
            case $_S_QUOTES in
                1)
                    case $_CH in
                        "'")
                            _S_QUOTES=0
                            _NEW_LINE=$_NEW_LINE$_CH
                        ;;
                        [\.$C_WORD])
                            case $_UNSET_MODE in
                                '')
                                    _NEW_LINE=$_NEW_LINE$_CH
                                ;;
                                *)
                                    _WORD=
                                    _REST_QUOTES=$_CH$_REST
                                    while
                                        case $_REST_QUOTES in
                                            '')
                                                false
                                            ;;
                                        esac
                                    do
                                        _Q_CH=${_REST_QUOTES%"${_REST_QUOTES#?}"}
                                        case $_Q_CH in
                                            [\.$C_WORD])
                                                _WORD=$_WORD$_Q_CH
                                                _REST_QUOTES=${_REST_QUOTES#?}
                                            ;;
                                            *)
                                                break
                                            ;;
                                        esac
                                    done
                                    _REST=$_REST_QUOTES

                                    case $_UNSET_MODE in
                                        f)
                                            _NEW_LINE=$_NEW_LINE$_F_PREFIX$_WORD
                                        ;;
                                        *)
                                            _NEW_LINE=$_NEW_LINE$_V_PREFIX$_WORD
                                        ;;
                                    esac
                                    _WORD=
                                ;;
                            esac
                        ;;
                        *)
                            _NEW_LINE=$_NEW_LINE$_CH
                        ;;
                    esac
                    continue
                ;;
            esac

            case $_CH in
                [\.$C_WORD])
                    case $_WORD in
                        '')
                            case $_CH in
                                [_$C_ALPHA])
                                    _WORD=$_CH
                                ;;
                                *)
                                    _NEW_LINE=$_NEW_LINE$_CH
                                ;;
                            esac
                        ;;
                        *)
                            _WORD=$_WORD$_CH
                        ;;
                    esac
                ;;
                *)
                    case $_WORD in
                        ?*)
                            _PREV_CHAR=
                            case $_NEW_LINE in
                                ?*)
                                    _PREV_CHAR=${_NEW_LINE#"${_NEW_LINE%?}"}
                                ;;
                            esac

                            case $_PREV_CHAR in
                                -)
                                    _LAST_FLAG=${_WORD#"${_WORD%?}"}
                                    case $_LAST_FLAG in
                                        [fv])
                                            _UNSET_MODE=$_LAST_FLAG
                                        ;;
                                    esac
                                    _NEW_LINE=$_NEW_LINE$_WORD
                                ;;
                                *)
                                    case $_WORD in
                                        unset)
                                            _UNSET_MODE=v
                                            _NEW_LINE=$_NEW_LINE$_WORD
                                        ;;
                                        *)
                                            false
                                        ;;
                                    esac
                                ;;
                            esac || {
                                _REST_CONTEXT=$_CH$_REST
                                _IS_SYS_VAR=0
                                case $_BASH_ENV_LIST in
                                    *" $_WORD "*)
                                        _IS_SYS_VAR=1
                                    ;;
                                esac

                                case $_IS_SYS_VAR in
                                    1)
                                        _NEW_LINE=$_NEW_LINE$_WORD
                                    ;;
                                    *)
                                        case $_PREV_CHAR in
                                            /)
                                                _NEW_LINE=$_NEW_LINE$_WORD
                                            ;;
                                            *)
                                                false
                                            ;;
                                        esac
                                    ;;
                                esac || {
                                    _IS_FUNC_DECL=0
                                    _IS_ASSIGNMENT=0
                                    case $_REST_CONTEXT in
                                        =*)
                                            _IS_ASSIGNMENT=1
                                        ;;
                                        \[*\]=*)
                                            _IS_ASSIGNMENT=1
                                        ;;
                                        *)
                                            _F_REST=$_REST_CONTEXT
                                            while
                                                case $_F_REST in
                                                    '')
                                                        false
                                                    ;;
                                                esac
                                            do
                                                _FT_CH=${_F_REST%"${_F_REST#?}"}
                                                case $_FT_CH in
                                                    $SPACE | $TAB)
                                                        _F_REST=${_F_REST#?}
                                                    ;;
                                                    *)
                                                        break
                                                    ;;
                                                esac
                                            done

                                            case ${_F_REST%"${_F_REST#?}"} in
                                                '(')
                                                    _F_REST=${_F_REST#?}
                                                    while
                                                        case $_F_REST in
                                                            '')
                                                                false
                                                            ;;
                                                        esac
                                                    do
                                                        _FT_CH=${_F_REST%"${_F_REST#?}"}
                                                        case $_FT_CH in
                                                            $SPACE | $TAB)
                                                                _F_REST=${_F_REST#?}
                                                            ;;
                                                            *)
                                                                break
                                                            ;;
                                                        esac
                                                    done

                                                    case ${_F_REST%"${_F_REST#?}"} in
                                                        ')')
                                                            _IS_FUNC_DECL=1
                                                        ;;
                                                    esac
                                                ;;
                                            esac
                                        ;;
                                    esac

                                    case $_EXPECT_VAR in
                                        1)
                                            true
                                        ;;
                                        *)
                                            case $_IS_ASSIGNMENT in
                                                1)
                                                    true
                                                ;;
                                                *)
                                                    false
                                                ;;
                                            esac
                                    esac && _NEW_LINE=$_NEW_LINE$_V_PREFIX$_WORD ||
                                    case $_UNSET_MODE in
                                        '')
                                            # Extract alias by original name from map
                                            _TARGET_WORD=$_WORD
                                            case $_USE_MAP in
                                                1)
                                                    case $_MAP_DATA in
                                                        *"$_WORD:"*)
                                                            _M_TAIL=${_MAP_DATA#*$_WORD:}
                                                            _TARGET_WORD=${_M_TAIL%%$SPACE*}
                                                        ;;
                                                    esac
                                                ;;
                                            esac

                                            case $_IS_FUNC_DECL in
                                                1)
                                                    true
                                                ;;
                                                *)
                                                    case $_LIST_FUNCS in
                                                        *" $_WORD "*)
                                                            true
                                                        ;;
                                                        *)
                                                            false
                                                        ;;
                                                    esac
                                                ;;
                                            esac && {
                                                case $_D_QUOTES in
                                                    1)
                                                        case $_UNSET_MODE in
                                                            '')
                                                                _NEW_LINE=$_NEW_LINE$_TARGET_WORD
                                                            ;;
                                                            *)
                                                                false
                                                            ;;
                                                        esac
                                                    ;;
                                                    *)
                                                        false
                                                    ;;
                                                esac || _NEW_LINE=$_NEW_LINE$_F_PREFIX$_TARGET_WORD
                                            } || _NEW_LINE=$_NEW_LINE$_WORD
                                        ;;
                                        f)
                                            _NEW_LINE=$_NEW_LINE$_F_PREFIX$_WORD
                                        ;;
                                        *)
                                            _NEW_LINE=$_NEW_LINE$_V_PREFIX$_WORD
                                        ;;
                                    esac
                                }
                            }

                            case " ${_FUNCTION_LIST:-} " in
                                *" $_WORD "*)
                                    _PRINT_ZONE=1
                                    _O_BR=0 _C_BR=0
                                    # Remember the tail of the line strictly after function name
                                    _BODY_TAIL=$_REST
                                    # SURGICAL CLEANING OF DIRT AT LINE START:
                                    # Check if the word 'function' was before the function name
                                    case $_NEW_LINE in
                                        *function*)
                                            # Keep only Ksh style and new name
                                            _NEW_LINE="function $_F_PREFIX$_TARGET_WORD"
                                        ;;
                                        *)
                                            # Clean POSIX: erase everything foreign, keep only function name
                                            _NEW_LINE=$_F_PREFIX$_TARGET_WORD
                                        ;;
                                    esac
                                ;;
                            esac
                            _WORD=
                        ;;
                    esac

                    case $_CH in
                        "'")
                            case $_D_QUOTES in
                                0) _S_QUOTES=1 ;;
                                *) false ;;
                            esac
                        ;;
                        *) false ;;
                    esac ||
                    case $_CH in
                        '"')
                            case $_D_QUOTES in
                                0) _D_QUOTES=1 ;;
                                *) _D_QUOTES=0 ;;
                            esac
                        ;;
                        $)
                            _EXPECT_VAR=1
                        ;;
                        [}%:-])
                            _EXPECT_VAR=0
                        ;;
                        '&' | ';' | '|' | $SPACE | $TAB)
                            _EXPECT_VAR=0
                            case $_CH in
                                '&' | ';' | '|')
                                    _UNSET_MODE=
                                ;;
                            esac
                        ;;
                    esac
                    _NEW_LINE=$_NEW_LINE$_CH
                ;;
            esac
        done

        case $_WORD in
            ?*)
                _PREV_CHAR=
                case $_NEW_LINE in
                    ?*)
                        _PREV_CHAR=${_NEW_LINE#"${_NEW_LINE%?}"}
                    ;;
                esac

                case $_PREV_CHAR in
                    -)
                        _NEW_LINE=$_NEW_LINE$_WORD
                    ;;
                    *)
                        _IS_SYS_VAR=0
                        case $_BASH_ENV_LIST in
                            *" $_WORD "*)
                                _IS_SYS_VAR=1
                            ;;
                        esac

                        case $_IS_SYS_VAR in
                            1)
                                _NEW_LINE=$_NEW_LINE$_WORD
                            ;;
                            *)
                                case $_PREV_CHAR in
                                    /)
                                        _NEW_LINE=$_NEW_LINE$_WORD
                                    ;;
                                    *)
                                        case $_UNSET_MODE in
                                            '')
                                                _TARGET_WORD=$_WORD
                                                case $_USE_MAP in
                                                    1)
                                                        case $_MAP_DATA in
                                                            *$_WORD:*)
                                                                _M_TAIL=${_MAP_DATA#*$_WORD:}
                                                                _TARGET_WORD=${_M_TAIL%%$SPACE*}
                                                            ;;
                                                        esac
                                                    ;;
                                                esac

                                                case $_EXPECT_VAR in
                                                    1)
                                                        _NEW_LINE=$_NEW_LINE$_V_PREFIX$_WORD
                                                    ;;
                                                    *)
                                                        case $_LIST_FUNCS in
                                                            *" $_WORD "*)
                                                                _NEW_LINE=$_NEW_LINE$_F_PREFIX$_TARGET_WORD
                                                            ;;
                                                            *)
                                                                _NEW_LINE=$_NEW_LINE$_WORD
                                                            ;;
                                                        esac
                                                    ;;
                                                esac
                                            ;;
                                            f)
                                                _NEW_LINE=$_NEW_LINE$_F_PREFIX$_WORD
                                            ;;
                                            *)
                                                _NEW_LINE=$_NEW_LINE$_V_PREFIX$_WORD
                                            ;;
                                        esac
                                    ;;
                                esac
                            ;;
                        esac
                    ;;
                esac
            ;;
        esac

        # Brace counting for current line in print zone
        case $_PRINT_ZONE in
            1)
                # If this is the first line (header), analyze only the tail AFTER the function name
                case ${_BODY_TAIL+set} in
                    '')
                        _BR_LINE=${_NEW_LINE%%#*}
                    ;;
                    *)
                        _BR_LINE=${_BODY_TAIL%%#*}
                        # Clear so that subsequent lines are analyzed as full lines
                        unset _BODY_TAIL
                    ;;
                esac

                _TMP_BR=$_BR_LINE
                while
                    case $_TMP_BR in
                        *'{'*)
                            true
                        ;;
                        *)
                            false
                        ;;
                    esac
                do
                    _BEFORE_BR=${_TMP_BR%%{*}
                    case ${_BEFORE_BR#"${_BEFORE_BR%?}"} in
                        '$')
                        ;;
                        *)
                            _O_BR=$((_O_BR + 1))
                        ;;
                    esac
                    _TMP_BR=${_TMP_BR#*{}
                done

                _TMP_BR=$_BR_LINE
                while
                    case $_TMP_BR in
                        *'}'*)
                            true
                        ;;
                        *)
                            false
                        ;;
                    esac
                do
                    _BEFORE_BR=${_TMP_BR%%'}'*}
                    case $_BEFORE_BR in
                        *esac* | *'$'*)
                        ;;
                        *)
                            _C_BR=$((_C_BR + 1))
                        ;;
                    esac
                    _TMP_BR=${_TMP_BR#*'}'}
                done

                case $(( _O_BR > 0 && _O_BR <= _C_BR )) in
                    1)
                        _CLOSE_FUNC_NOW=1
                    ;;
                    0)
                        _CLOSE_FUNC_NOW=0
                    ;;
                esac

                _MODULE_FUNCS=${_MODULE_FUNCS:+$_MODULE_FUNCS$LF}$_NEW_LINE$_COMM_PART
            ;;
            *)
                case ${_FUNCTION_LIST:-} in
                    '')
                        _MODULE_FUNCS=${_MODULE_FUNCS:+$_MODULE_FUNCS$LF}$_NEW_LINE$_COMM_PART
                    ;;
                esac
            ;;
        esac

        case ${_CLOSE_FUNC_NOW:-0} in
            1)
                _CLOSE_FUNC_NOW=0
                _PRINT_ZONE=0
                _O_BR=0
                _C_BR=0
            ;;
        esac
    done
}

_get_bash_env_list ()
{
    _BASH_ENV_LIST=' ? ! * @ # $ - _ '
    _BASH_ENV_LIST="$_BASH_ENV_LIST BASH BASHOPTS BASHPID BASH_ALIASES BASH_ARGC BASH_ARGV BASH_ARGV0 BASH_CMDS BASH_COMMAND BASH_COMPAT BASH_ENV BASH_EXECUTION_STRING BASH_LINENO BASH_LOADABLES_PATH BASH_REMATCH BASH_SOURCE BASH_SUBSHELL BASH_VERSINFO BASH_VERSION BASH_XTRACEFD "
    _BASH_ENV_LIST="$_BASH_ENV_LIST CDPATH CHILD_MAX COLUMNS COMP_CWORD COMP_LINE COMP_POINT COMP_TYPE COMP_KEY COMP_WORDBREAKS COMP_WORDS COMPREPLY COPROC "
    _BASH_ENV_LIST="$_BASH_ENV_LIST DIRSTACK "
    _BASH_ENV_LIST="$_BASH_ENV_LIST EMACS ENV EPOCHREALTIME EPOCHSECONDS EUID EXECIGNORE "
    _BASH_ENV_LIST="$_BASH_ENV_LIST FCEDIT FIGNORE FUNCNAME FUNCNEST "
    _BASH_ENV_LIST="$_BASH_ENV_LIST GLOBIGNORE GROUPS "
    _BASH_ENV_LIST="$_BASH_ENV_LIST histchars "
    _BASH_ENV_LIST="$_BASH_ENV_LIST HOME HISTCMD HISTCONTROL HISTFILE HISTFILESIZE HISTIGNORE HISTSIZE HISTTIMEFORMAT HOSTFILE HOSTNAME HOSTTYPE "
    _BASH_ENV_LIST="$_BASH_ENV_LIST IFS IGNOREEOF INPUTRC INSIDE_EMACS "
    _BASH_ENV_LIST="$_BASH_ENV_LIST LANG LC_ALL LC_COLLATE LC_CTYPE LC_MESSAGES LC_NUMERIC LC_TIME LINENO LINES "
    _BASH_ENV_LIST="$_BASH_ENV_LIST MAIL MAILPATH MACHTYPE MAILCHECK MAPFILE "
    _BASH_ENV_LIST="$_BASH_ENV_LIST OLDPWD OPTERR OSTYPE OPTARG OPTIND "
    _BASH_ENV_LIST="$_BASH_ENV_LIST PATH PIPESTATUS POSIXLY_CORRECT PPID PROMPT_COMMAND PROMPT_DIRTRIM PS0 PS1 PS2 PS3 PS4 PWD "
    _BASH_ENV_LIST="$_BASH_ENV_LIST RANDOM READLINE_ARGUMENT READLINE_LINE READLINE_MARK READLINE_POINT REPLY "
    _BASH_ENV_LIST="$_BASH_ENV_LIST SECONDS SHELL SHELLOPTS SHLVL SRANDOM "
    _BASH_ENV_LIST="$_BASH_ENV_LIST TIMEFORMAT TMOUT TMPDIR "
    _BASH_ENV_LIST="$_BASH_ENV_LIST UID USER "
}

_import_module ()
{
    _MODULE_FUNCS=
    case ${_BASH_ENV_LIST:-} in
        '')
            _get_bash_env_list
        ;;
    esac

    _import_module_$_IMPORT_TYPE
    case $_MODULE_FUNCS in
        ?*)
            eval "$_MODULE_FUNCS"
    esac || _modulenotfounderror 3 "$_IMPORT_PREFIX_NAME"
}

_load_module ()
{
    IFS=
    _MODULE_BODY=
    while read -r _LINE ||
        case $_LINE in
            '')
                false
            ;;
        esac
    do
        _MODULE_BODY=$_MODULE_BODY$_LINE$LF
    done < "$_MODULE_PATH"
    IFS=$POSIX_IFS
}

_import_function ()
{
    $_IMPORT_AS || _modulenotfounderror 0 || return

    # 1. Load module content into memory
    _load_module

    # 2. Run tokenizer (it will filter and rename everything in one pass)
    _import_module_$_IMPORT_TYPE || _modulenotfounderror 4 "$_MODULE_FUNCS" || return

    case $_MODULE_FUNCS in
        ?*)
            eval "$_MODULE_FUNCS"
    esac || _modulenotfounderror 3 "$_FUNCTION_LIST"

    # Clear temporary filter after execution
    _FUNCTION_LIST=
}

_import_package ()
{
    if is_file "$1/__init__.sh"
    then
        set -- "$1/__init__.sh" "${_CTX_FILE:-}"
        _CTX_FILE=$1
        . "$1"
        _CTX_FILE=$2
    else
        for _MODULE in "$1"/*.sh
        do
            _MODULE_NAME=${_MODULE##*/}
            _push_prefix_name "${_MODULE_NAME%.sh}"
            _import_module
            _pop_prefix_name "${_MODULE_NAME%.sh}"
        done
    fi
}

_import ()
{
    # $1     - _CTX_SPEC (package/module/function_name)
    # ${2:-} - as
    # ${3:-} - _ALIAS

    _resolve_module_path "$1" || return

    if is_file "$_MODULE_PATH"
    then
        case $_IDENTIFIER in
            $_IDENTIFIER_PART)
                # from subpackage import module as alias
                # import subpackage.module as alias
                set -- "$_SUFFIX_MODULE_PATH" "$@"
                _push_prefix_name "${4:-$2}"
                _load_module
                _import_module
            ;;
            *)
                # from subpackage import module.func as alias
                # import subpackage.module.func as alias
                case $# in
                    1)
                        _push_prefix_name "$_IDENTIFIER_PART"
                        _parse_import_list "${_IDENTIFIER#"$_IDENTIFIER_PART."}"
                    ;;
                    *)
                        shift
                        _parse_import_list "${_IDENTIFIER#"$_IDENTIFIER_PART."} $*"
                    ;;
                esac
                set -- "$_SUFFIX_MODULE_PATH" "$_IDENTIFIER_PART"
                _import_function
                _pop_module_path "$1"
                _pop_prefix_name "$2"
                return
            ;;
        esac || return
    elif is_dir "$_MODULE_PATH"
    then
        # from . import subpackage as alias
        #        import subpackage as alias
        set -- "$_SUFFIX_MODULE_PATH" "$@"
        _push_prefix_name "${4:-$2}"
        _import_package "$_MODULE_PATH"
    else
        _modulenotfounderror 3 "$_MODULE_PATH" || return
    fi

    _pop_module_path "$1"
    _pop_prefix_name "${4:-$2}"
}

_gen_function_map ()
{
    case $# in
        1)
            _FUNCTION_MAP="$_FUNCTION_MAP $1:$1"
        ;;
        3)
            _FUNCTION_MAP="$_FUNCTION_MAP $1:$3"
        ;;
    esac
    _FUNCTION_LIST="$_FUNCTION_LIST $1"
}

_parse_import_list ()
{
    _FUNCTION_MAP=FUNC_MAP:
    _FUNCTION_LIST=
    for i
    do
        _gen_function_map $i
    done
    _FUNCTION_LIST=${_FUNCTION_LIST#?}
}

_parse_import_buffer ()
{
    eval set -- "$_CTX_BUFFER"
    _CTX_BUFFER=

    is_file "${_MODULE_PATH:-/}" && {
        # from subpackage.module import func1, func2 as alias
        _parse_import_list "$@"
        _import_function || return
    } ||
    for _MODULE
    do
        _import $_MODULE
    done
}

import ()
{
    _CTX_STATEMENT=import${*:+ $*}
    _CTX_COMMAND=import
    _CTX_SPECS=
    _CTX_TIGHT=false
    _check_import_syntax "$@"
    _parse_import_buffer
}

from ()
{
    _CTX_STATEMENT=from${*:+ $*}
    _CTX_COMMAND=from
    _CTX_SPECS=
    _CTX_TIGHT=false
    _CTX_PATH_FROM=${1:-}

    case $# in
        [!0]*)
            shift
        ;;
    esac

    case $_CTX_PATH_FROM in
        '')
            _MODULE_NAME=$SPACE
            false
        ;;
        .)
            case ${1:-} in
                import)
                    shift
                    _CTX_COMMAND='from . import'
                    _MODULE_NAME=
                    _check_import_syntax "$@" &&
                    _parse_import_buffer || return
                ;;
                *)
                    _MODULE_NAME='. '
                    false
                ;;
            esac
        ;;
        *)
            _MODULE_NAME=
            case $_CTX_PATH_FROM in
                *[!.]*)
                    case $_CTX_PATH_FROM in
                        .*)
                            is_valid_identifier "${_CTX_PATH_FROM#?}"
                        ;;
                        *)
                            is_valid_identifier "$_CTX_PATH_FROM"
                        ;;
                    esac || return
                ;;
            esac

            case ${1:-} in
                import)
                    shift
                    _CTX_COMMAND="from $_CTX_PATH_FROM import"
                    _check_import_syntax "$@" &&
                    _resolve_module_path "$_CTX_PATH_FROM" && {
                        set -- "$_SUFFIX_MODULE_PATH"
                        _parse_import_buffer && _pop_module_path "$1"
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
    case $TARGET in
        \~)     TARGET=${HOME%/} ;;
        \~/*)   TARGET=${HOME%/}/${TARGET#?} ;;
         ./*)   case $PWD in
                    / ) TARGET=${TARGET#?} ;;
                    * ) TARGET=$PWD${TARGET#?} ;;
                esac ;;
        [!/]*)  case $PWD in
                    / ) TARGET=/$TARGET ;;
                    * ) TARGET=$PWD/$TARGET ;;
                esac ;;
    esac

    # resolve path /home/bob/../alisa/.//.ssh/ to /home/alisa/.ssh
    ARG=${TARGET:-}
    TARGET=
    while
        case ${ARG:-} in
            '')
                false
            ;;
        esac
    do
        DIR=${ARG%%/*}
        case ${DIR:-} in
             .) : ;;
            '') DIR=${ARG%%[!/]*} ;;
            ..) TARGET=${TARGET%/*} ;;
             *) TARGET=${TARGET%/}/$DIR ;;
        esac
        ARG=${ARG#"$DIR"}
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

# File manipulation utilities
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
