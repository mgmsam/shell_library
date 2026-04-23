#!/bin/sh

# argparse.sh. Portable command-line argument parser for POSIX shell.
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

AP_UPPERS='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
AP_LOWERS='abcdefghijklmnopqrstuvwxyz'
AP_DIGITS='0123456789'
AP_ALNUM=$AP_LOWERS$AP_UPPERS$AP_DIGITS
AP_ALPHA=$AP_LOWERS$AP_UPPERS
AP_POSIX_IFS=$IFS
AP_SPACE=' '
AP_LF='
'

_to_lower ()
{
    _AP_BUFFER=$1
    _AP_STRING=
    while
        case $((${#_AP_BUFFER} > 0)) in
            0)
                false
            ;;
        esac
    do
        _AP_CHAR=${_AP_BUFFER%"${_AP_BUFFER#?}"}
        _AP_BUFFER=${_AP_BUFFER#?}
        case $_AP_CHAR in
            ["$AP_UPPERS"])
                _AP_NUM=${AP_UPPERS%%"$_AP_CHAR"*}
                _AP_NUM=$((${#_AP_NUM} + 1))
                _AP_COUNT=
                while
                    case $((${#_AP_COUNT} < _AP_NUM)) in
                        0)
                            false
                        ;;
                    esac
                do
                    _AP_COUNT="$_AP_COUNT?"
                done
                _AP_CHAR=${AP_LOWERS%"${AP_LOWERS#$_AP_COUNT}"}
                _AP_CHAR=${_AP_CHAR#"${_AP_CHAR%?}"}
            ;;
        esac
        _AP_STRING=$_AP_STRING$_AP_CHAR
    done
}

_to_upper ()
{
    _AP_BUFFER=$1
    _AP_STRING=
    while
        case $((${#_AP_BUFFER} > 0)) in
            0)
                false
            ;;
        esac
    do
        _AP_CHAR=${_AP_BUFFER%"${_AP_BUFFER#?}"}
        _AP_BUFFER=${_AP_BUFFER#?}
        case $_AP_CHAR in
            ["$AP_LOWERS"])
                _AP_NUM=${AP_LOWERS%%"$_AP_CHAR"*}
                _AP_NUM=$((${#_AP_NUM} + 1))
                _AP_COUNT=
                while
                    case $((${#_AP_COUNT} < _AP_NUM)) in
                        0)
                            false
                        ;;
                    esac
                do
                    _AP_COUNT="$_AP_COUNT?"
                done
                _AP_CHAR=${AP_UPPERS%"${AP_UPPERS#$_AP_COUNT}"}
                _AP_CHAR=${_AP_CHAR#"${_AP_CHAR%?}"}
            ;;
        esac
        _AP_STRING=$_AP_STRING$_AP_CHAR
    done
}

_str_replace ()
{
########################################################################
    # replace sub string in string
    # $1 - pattern
    # $2 - replace
########################################################################
    _AP_REPEAT=false
    while true
    do
        case "$1" in
            --)
                shift
                break
            ;;
            -l)
                _AP_REPEAT=true
                shift
            ;;
            *)
                break
            ;;
        esac
    done
    _AP_STRING="$1"
    while
        case "$_AP_STRING" in
            *$2*)
            ;;
            *)
                return
            ;;
        esac
    do
        _AP_BUFFER=
        while
            case "${_AP_STRING:+${2:-}}" in
                "")
                    false
                ;;
            esac
        do
            _AP_LEFT=${_AP_STRING%%"$2"*}
            case "$_AP_LEFT" in
                "$_AP_STRING")
                    break
                ;;
            esac
            _AP_BUFFER=$_AP_BUFFER$_AP_LEFT${3:-}
            _AP_STRING=${_AP_STRING#*"$2"}
        done
        _AP_STRING=$_AP_BUFFER$_AP_STRING _AP_BUFFER=
        $_AP_REPEAT || break
    done
}

_unique_chars ()
{
########################################################################
    # remove dublicate characters in the string
########################################################################
    _AP_STRING="$1"
    _AP_BUFFER=
    while
        case "$_AP_STRING" in
            "")
                false
            ;;
        esac
    do
        _AP_CHAR=${_AP_STRING%"${_AP_STRING#?}"}
        _AP_STRING=${_AP_STRING#?}
        case "$_AP_BUFFER" in
            *"$_AP_CHAR"*)
            ;;
            *)
                _AP_BUFFER=$_AP_BUFFER$_AP_CHAR
            ;;
        esac
    done
    _AP_STRING=$_AP_BUFFER
}

_get_terminal_size ()
{
    case "${COLUMNS:+${LINES:+$COLUMNS$LINES}}" in
        "" | *[!"$AP_DIGITS"]*)
            type tput >/dev/null 2>&1 && {
                LINES=$(tput lines) && COLUMNS=$(tput cols)
            } || {
                type stty >/dev/null 2>&1 && {
                    set -- $(stty size 2>/dev/null) && {
                        LINES=${1:-24}
                        COLUMNS=${2:-80}
                    }
                }
            } || LINES=24 COLUMNS=80
        ;;
    esac
}

_set_parens ()
{
    case "$1" in
        [\(\)])
            _AP_L_PAREN='('
            _AP_R_PAREN=')'
        ;;
        [\]\[])
            _AP_L_PAREN='['
            _AP_R_PAREN=']'
        ;;
        [\{\}])
            _AP_L_PAREN='{'
            _AP_R_PAREN='}'
        ;;
        [\<\>])
            _AP_L_PAREN='<'
            _AP_R_PAREN='>'
        ;;
    esac
}

_validate_terminated ()
{
    _AP_STRING=$1
    while
        case "$_AP_STRING" in
            *[\'\"]*) true  ;;
                   *) false ;;
        esac
    do
        _AP_LEFT=${_AP_STRING%%[\'\"]*}
        _AP_QUOTE=${_AP_STRING#"$_AP_LEFT"}
        _AP_QUOTE=${_AP_QUOTE%"${_AP_QUOTE#?}"}
        _AP_BUFFER=${_AP_STRING#*"$_AP_QUOTE"}
        case "$_AP_BUFFER" in
            *$_AP_QUOTE*)
                _AP_STRING=$_AP_LEFT${_AP_BUFFER#*"$_AP_QUOTE"}
            ;;
            *)
                echo "SyntaxError: unterminated string literal (detected at line 1)"
                return 2
        esac
    done

    while
        case "$_AP_STRING" in
            *[][\(\){}\<\>]*) true  ;;
                           *) false ;;
        esac
    do
        _AP_LEFT=${_AP_STRING%%[][(){\}\<\>]*}
        _AP_PAREN=${_AP_STRING#"$_AP_LEFT"}
        _AP_PAREN=${_AP_PAREN%"${_AP_PAREN#?}"}
        _set_parens "$_AP_PAREN"
        case "$_AP_PAREN" in
            *[]\)}\>]*)
                echo "SyntaxError: closing parenthesis '$_AP_R_PAREN' does not match opening parenthesis '$_AP_L_PAREN'"
                return 2
            ;;
            *)
                _AP_BUFFER=${_AP_STRING#*"$_AP_PARENT"}
                case "$_AP_BUFFER" in
                    *$_AP_R_PAREN*)
                        _AP_STRING=${_AP_BUFFER#*"$_AP_R_PAREN"}
                    ;;
                    *)
                        echo "SyntaxError: opening parenthesis '$_AP_L_PAREN' does not match closing parenthesis '$_AP_R_PAREN'"
                        return 2
                esac
            ;;
        esac
    done
}

_trim_quotes ()
{
    _AP_STRING=$1
    case "$_AP_STRING" in
        [\"\']*)
            _AP_STRING=${_AP_STRING#?}
            _AP_STRING=${_AP_STRING%?}
            return
        ;;
    esac
    false
}

_parse_arg_sequence ()
{
    _AP_OPTION_IS_SET=false
    _AP_KEYWORD_IS_SET=false
    _AP_POSITION_ARG_IS_SET=false
    _AP_POSITION_ARG=

    for _AP_ARG
    do
        _validate_terminated "$_AP_ARG" || return
        _trim_quotes "$_AP_ARG" || :
        _AP_ARG=$_AP_STRING
        case "$_AP_ARG" in
            "")
                echo "ValueError: invalid option string '$_AP_ARG': must start with a character '$AP_PARSER_PREFIX_CHARS'"
                return 2
            ;;
            [$AP_PARSER_PREFIX_CHARS]*)
                $_AP_KEYWORD_IS_SET && {
                    echo "SyntaxError: positional argument follows keyword argument"
                    return 2
                } || {
                    $_AP_POSITION_ARG_IS_SET && {
                        echo "ValueError: invalid option string '$_AP_POSITION_ARG': must start with a character '$AP_PARSER_PREFIX_CHARS'"
                        return 2
                    }
                } || _AP_OPTION_IS_SET=true
            ;;
            *[!=]*=*)
                case "$_AP_ARG" in
                    [_"$AP_ALPHA"]*)
                        _validate_terminated "${_AP_ARG#*=}" || return
                        case "${_AP_ARG#*=}" in
                            "")
                                echo "SyntaxError: expected argument value expression"
                                return 2
                            ;;
                        esac
                        _AP_KEYWORD_IS_SET=true
                    ;;
                    *)
                        echo "SyntaxError: invalid keyword argument name '${_AP_ARG%%=*}'"
                        return 2
                    ;;
                esac
            ;;
            *)
                $_AP_KEYWORD_IS_SET && {
                    echo "SyntaxError: positional argument follows keyword argument"
                    return 2
                } || {
                    $_AP_POSITION_ARG_IS_SET && {
                        echo "ValueError: invalid option string '$_AP_POSITION_ARG': must start with a character '$AP_PARSER_PREFIX_CHARS'"
                        return 2
                    }
                } || _AP_OPTION_IS_SET=true _AP_POSITION_ARG=$_AP_ARG
            ;;
        esac
    done
}

_check_unique_kwargs ()
{
    case "$_AP_SEEN_KEYWORDS" in
        *"$_AP_KEYWORD"*)
            echo "SyntaxError: keyword argument repeated: $_AP_KEYWORD"
            return 2
        ;;
    esac
    _AP_SEEN_KEYWORDS="$_AP_SEEN_KEYWORDS $_AP_KEYWORD"
}

_check_unique_formatter_class ()
{
    case "$_AP_SEEN_FORMATTER_CLASS" in
        *"$_AP_KEYWORD_VALUE"*)
            echo "TypeError: duplicate base class $_AP_KEYWORD_VALUE"
            return 2
        ;;
    esac
    _AP_SEEN_FORMATTER_CLASS="$_AP_SEEN_FORMATTER_CLASS $_AP_KEYWORD_VALUE"
}

_is_none_value ()
{
    case "$_AP_KEYWORD_VALUE" in
        None)
            $_AP_VALUE_IS_STRING
        ;;
    esac
}

_set_bool_var ()
{
    case "$_AP_KEYWORD" in
        add_help)
            AP_PARSER_ADD_HELP=$1
        ;;
        allow_abbrev)
            AP_PARSER_ALLOW_ABBREV=$1
        ;;
        exit_on_error)
            AP_PARSER_EXIT_ON_ERROR=$1
        ;;
    esac
}

_set_positional_kwargs ()
{
    _AP_AP_PARSER_FUNC=$1
    shift
    for _AP_ARG
    do
        case "$_AP_ARG" in
            *=*)
                _AP_KEYWORD=${_AP_ARG%%=*}
                _AP_KEYWORD_VALUE=${_AP_ARG#*=}
                _set_${_AP_AP_PARSER_FUNC}_kwargs || return
            ;;
            *)
                _trim_quotes "$_AP_ARG" && {
                    _AP_KEYWORD_VALUE=$_AP_STRING
                    _AP_VALUE_IS_STRING=true
                } || :
                _is_none_value || _AP_KEYWORD_VALUE=
                _set_${_AP_AP_PARSER_FUNC}_positional_args || return
            ;;
        esac
    done
}

_set_parser_kwargs ()
{
    case "$_AP_KEYWORD" in
        formatter_class)
            _check_unique_kwargs || return
            IFS=' ,'
            set -- $_AP_KEYWORD_VALUE
            IFS=$AP_POSIX_IFS
            AP_PARSER_FORMATTER_CLASS=
            for _AP_KEYWORD_VALUE
            do
                case "$_AP_KEYWORD_VALUE" in
                    argparse.HelpFormatter)
                        AP_PARSER_FORMATTER_CLASS_DEFAULT=true
                    ;;
                    argparse.RawTextHelpFormatter)
                        AP_PARSER_FORMATTER_CLASS_RAWTEXT=true
                    ;;
                    argparse.RawDescriptionHelpFormatter)
                        AP_PARSER_FORMATTER_CLASS_RAWDESCRIPTION=true
                    ;;
                    argparse.ArgumentDefaultsHelpFormatter)
                        AP_PARSER_FORMATTER_CLASS_ARGUMENTDEFAULTS=true
                    ;;
                    argparse.MetavarTypeHelpFormatter)
                        AP_PARSER_FORMATTER_CLASS_METAVARTYPE=true
                    ;;
                    None)
                        echo "ValueError: length of metavar tuple does not match nargs"
                        return 2
                    ;;
                    *)
                        echo "AttributeError: module 'argparse' has no attribute '$_AP_KEYWORD_VALUE'"
                        return 2
                    ;;
                esac
                _check_unique_formatter_class || return
                AP_PARSER_FORMATTER_CLASS="${AP_PARSER_FORMATTER_CLASS:+$AP_PARSER_FORMATTER_CLASS, }$_AP_KEYWORD_VALUE"
            done
        ;;
        prog | usage | description | epilog | parents | prefix_chars | \
        fromfile_prefix_chars | argument_default | conflict_handler | \
        add_help | allow_abbrev | exit_on_error | case_style | dest_prefix | func_prefix)
            _check_unique_kwargs || return
            _trim_quotes "$_AP_KEYWORD_VALUE" && {
                _AP_KEYWORD_VALUE=$_AP_STRING
                _AP_VALUE_IS_STRING=true
            } || :
            case "$_AP_KEYWORD_VALUE" in
                *\`*)
                    echo "SyntaxError: invalid syntax"
                    return 2
                ;;
            esac
            case "$_AP_KEYWORD" in
                prog)
                    _is_none_value &&
                    AP_PARSER_PROG=$_AP_KEYWORD_VALUE || AP_PARSER_PROG=
                ;;
                usage)
                    _is_none_value &&
                    AP_PARSER_USAGE=$_AP_KEYWORD_VALUE || AP_PARSER_USAGE=
                ;;
                description)
                    _is_none_value &&
                    AP_PARSER_DESCRIPTION=$_AP_KEYWORD_VALUE || AP_PARSER_DESCRIPTION=
                ;;
                epilog)
                    _is_none_value &&
                    AP_PARSER_EPILOG=$_AP_KEYWORD_VALUE || AP_PARSER_EPILOG=
                ;;
                parents)
                    # TODO: implement
                ;;
                prefix_chars)
                    _unique_chars "$_AP_KEYWORD_VALUE"
                    _AP_KEYWORD_VALUE=$_AP_STRING
                    case "$_AP_KEYWORD_VALUE" in
                        "$AP_PARSER_PREFIX_CHARS")
                        ;;
                        "")
                            echo "ValueError: prefix_chars must be a non-empty string"
                            return 2
                        ;;
                        *)
                            AP_PARSER_PREFIX_CHARS=$_AP_KEYWORD_VALUE
                            AP_PARSER_POSIX_PREFIX_CHARS=false
                        ;;
                    esac
                ;;
                fromfile_prefix_chars)
                    # TODO: implement
                ;;
                argument_default)
                    _is_none_value &&
                    AP_PARSER_ARGUMENT_DEFAULT=$_AP_KEYWORD_VALUE || AP_PARSER_ARGUMENT_DEFAULT=
                ;;
                conflict_handler)
                    case "$_AP_KEYWORD_VALUE" in
                        error | [Ff]alse | 0)
                        ;;
                        resolve | [Tt]rue | 1)
                            AP_PARSER_CONFLICT_HANDLER=true
                        ;;
                        *)
                            echo "ValueError: invalid conflict_resolution value: '$_AP_KEYWORD_VALUE'"
                            return 2
                        ;;
                    esac
                ;;
                add_help | allow_abbrev | exit_on_error)
                    $_AP_VALUE_IS_STRING && {
                        case "$_AP_KEYWORD_VALUE" in
                            ?*)
                                _set_bool_var true
                            ;;
                            "")
                                _set_bool_var false
                            ;;
                        esac
                    } || {
                        case "$_AP_KEYWORD_VALUE" in
                            0 | False)
                                _set_bool_var false
                            ;;
                            1 | True)
                                _set_bool_var true
                            ;;
                            *[!"$AP_DIGITS"]*)
                                echo "NameError: name '$_AP_KEYWORD_VALUE' is not defined."
                                return 2
                            ;;
                            0*[!0]*)
                                echo "SyntaxError: leading zeros in decimal integer literals are not permitted; use an 0o prefix for octal integers"
                                return 2
                            ;;
                            *)
                                _set_bool_var true
                            ;;
                        esac
                    }
                ;;
                case_style)
                    case "$_AP_KEYWORD_VALUE" in
                        upper | lower)
                            AP_PARSER_CASE_STYLE=$_AP_KEYWORD_VALUE
                        ;;
                        *)
                            echo "NameError: name '$_AP_KEYWORD_VALUE' is not defined."
                            return 2
                        ;;
                    esac
                ;;
                dest_prefix)
                    _is_none_value &&
                    AP_PARSER_DEFAULT_DEST_PREFIX=$_AP_KEYWORD_VALUE || AP_PARSER_DEFAULT_DEST_PREFIX=
                ;;
                func_prefix)
                    _is_none_value &&
                    AP_PARSER_FUNC_PREFIX=$_AP_KEYWORD_VALUE || AP_PARSER_FUNC_PREFIX=
                ;;
            esac
        ;;
        *)
            echo "TypeError: ArgumentParser got an unexpected keyword argument '$_AP_KEYWORD'"
            return 2
        ;;
    esac
}

_set_parser_positional_args ()
{
    if case "$AP_PARSER_PROG" in ?*) false ;; esac
    then
        AP_PARSER_PROG=$_AP_KEYWORD_VALUE
    elif case "$AP_PARSER_USAGE" in ?*) false ;; esac
    then
        AP_PARSER_USAGE=$_AP_KEYWORD_VALUE
    elif case "$AP_PARSER_DESCRIPTION" in ?*) false ;; esac
    then
        AP_PARSER_DESCRIPTION=$_AP_KEYWORD_VALUE
    elif case "$AP_PARSER_EPILOG" in ?*) false ;; esac
    then
        AP_PARSER_EPILOG=$_AP_KEYWORD_VALUE
    elif case "$AP_PARSER_PARENTS" in ?*) false ;; esac
    then
        # TODO: implement
        AP_PARSER_PARENTS=
    else
        echo "ValueError: length of metavar tuple does not match nargs"
        return 2
    fi
}

ArgumentParser ()
{
    AP_PARSER_PROG=${LOG_PREFIX:-}
    AP_PARSER_USAGE=
    AP_PARSER_DESCRIPTION=
    AP_PARSER_EPILOG=
    AP_PARSER_PARENTS=
    AP_PARSER_FORMATTER_CLASS=
    AP_PARSER_FORMATTER_CLASS_DEFAULT=true
    AP_PARSER_FORMATTER_CLASS_RAWTEXT=false
    AP_PARSER_FORMATTER_CLASS_RAWDESCRIPTION=false
    AP_PARSER_FORMATTER_CLASS_ARGUMENTDEFAULTS=false
    AP_PARSER_FORMATTER_CLASS_METAVARTYPE=false
    AP_PARSER_PREFIX_CHARS=-
    AP_PARSER_FROMFILE_PREFIX_CHARS=
    AP_PARSER_ARGUMENT_DEFAULT=
    AP_PARSER_CONFLICT_HANDLER=false
    AP_PARSER_ADD_HELP=true
    AP_PARSER_ALLOW_ABBREV=true
    AP_PARSER_EXIT_ON_ERROR=true

    AP_PARSER_POSIX_PREFIX_CHARS=true
    AP_PARSER_CASE_STYLE='lower'
    AP_PARSER_DEFAULT_DEST_PREFIX=
    AP_PARSER_FUNC_PREFIX=

    _AP_INDEX=0
    _AP_INDEXES=
    _AP_REQUIRED_INDEXES=

    _AP_SEEN_FORMATTER_CLASS=
    _AP_SEEN_KEYWORDS=
    _AP_KEYWORD=
    _AP_KEYWORD_VALUE=
    _AP_VALUE_IS_STRING=false

    _parse_arg_sequence "$@" &&
    _set_positional_kwargs parser "$@" || return

    AP_PARSER_PARENTS=${AP_PARSER_PARENTS:-}
    AP_PARSER_ADD_HELP=${AP_PARSER_ADD_HELP:-}
    AP_PARSER_ALLOW_ABBREV=${AP_PARSER_ALLOW_ABBREV:-}
    AP_PARSER_EXIT_ON_ERROR=${AP_PARSER_EXIT_ON_ERROR:-}

    case "$AP_PARSER_FUNC_PREFIX" in
        ?*)
            eval "${AP_PARSER_FUNC_PREFIX}_add_argument () { add_argument \"\$@\"; }"
            eval "${AP_PARSER_FUNC_PREFIX}_parse_args () { parse_args \"\$@\"; }"
            eval "${AP_PARSER_FUNC_PREFIX}_print_parser_state () { print_parser_state; }"
            eval "${AP_PARSER_FUNC_PREFIX}_print_action_state () { print_action_state; }"
        ;;
    esac
}

print_parser_state ()
{
    echo "prog: ${AP_PARSER_PROG:-None}
usage: ${AP_PARSER_USAGE:-None}
description: ${AP_PARSER_DESCRIPTION:-None}
epilog: ${AP_PARSER_EPILOG:-None}
parents: ${AP_PARSER_PARENTS:-None}
formatter_class: ${AP_PARSER_FORMATTER_CLASS:-None}
prefix_chars: ${AP_PARSER_PREFIX_CHARS:-None}
fromfile_prefix_chars: ${AP_PARSER_FROMFILE_PREFIX_CHARS:-None}
argument_default: ${AP_PARSER_ARGUMENT_DEFAULT:-None}
conflict_handler: ${AP_PARSER_CONFLICT_HANDLER:-None}
add_help: ${AP_PARSER_ADD_HELP:-None}
allow_abbrev: ${AP_PARSER_ALLOW_ABBREV:-None}
exit_on_error: ${AP_PARSER_EXIT_ON_ERROR:-None}
case_style: ${AP_PARSER_CASE_STYLE:-None}
dest_prefix: ${AP_PARSER_DEFAULT_DEST_PREFIX:-None}"
}

_split_chars ()
{
    _AP_STRING=${1:-}
    _AP_DELIMITER=${2:-,}
    _AP_CHAR=
    _AP_BUFFER=
    while
        case "${#_AP_STRING}" in
            0)
                false
            ;;
        esac
    do
        _AP_CHAR=${_AP_STRING%"${_AP_STRING#?}"}
        _AP_BUFFER="${_AP_BUFFER:+$_AP_BUFFER$_AP_DELIMITER}'$_AP_CHAR'"
        _AP_STRING=${_AP_STRING#?}
    done
    _AP_STRING=$_AP_BUFFER
}

_set_action_kwargs ()
{
    case "$_AP_KEYWORD" in
        action | nargs | const | default | type | choices | required | \
        help | metavar | version | dest | dest_prefix)
            _check_unique_kwargs || return
            _trim_quotes "$_AP_KEYWORD_VALUE" && {
                _AP_KEYWORD_VALUE=$_AP_STRING
                _AP_VALUE_IS_STRING=true
            } || :
            case "$_AP_KEYWORD" in
                action)
                    _is_none_value &&
                    AP_ACTION=${_AP_KEYWORD_VALUE:-store} || AP_ACTION=store
                    case "$AP_ACTION" in
                        store | store_const | store_true | store_false | \
                        append | append_const | count | help | version | extend)
                        ;;
                        *)
                            echo "ValueError: unknown action \"$AP_ACTION\""
                            return 2
                        ;;
                    esac
                ;;
                dest)
                    case "$AP_ACTION_POSITION_ARG" in
                        ?*)
                            echo "ValueError: dest supplied twice for positional argument"
                            return 2
                        ;;
                    esac
                    _is_none_value &&
                    AP_ACTION_DEST=$_AP_KEYWORD_VALUE || AP_ACTION_DEST=
                ;;
                nargs)
                    _is_none_value &&
                    AP_ACTION_NARGS="$_AP_KEYWORD_VALUE" || AP_ACTION_NARGS=
                    case "$AP_ACTION_NARGS" in
                        "" | [?*+])
                        ;;
                        *[!"$AP_DIGITS"]*)
                            echo "NameError: name '$AP_ACTION_NARGS' is not defined"
                            return 2
                        ;;
                    esac
                ;;
                const)
                    _is_none_value &&
                    AP_ACTION_CONST=$_AP_KEYWORD_VALUE || AP_ACTION_CONST=
                ;;
                default)
                    _is_none_value &&
                    AP_ACTION_DEFAULT=$_AP_KEYWORD_VALUE || AP_ACTION_DEFAULT=
                ;;
                type)
                    _is_none_value &&
                    AP_ACTION_TYPE=$_AP_KEYWORD_VALUE || AP_ACTION_TYPE=
                    case "$AP_ACTION_TYPE" in
                        "" | int | float | str | bool)
                            # TODO: implement
                        ;;
                        complex | Path | json.loads | \
                        "argparse.FileType('r')" | \
                        "argparse.FileType('w')" | \
                        "argparse.FileType('a')" | \
                        "lambda s: s.upper()" | "lambda s: s.lower()")
                            # TODO: implement
                        ;;
                        "lambda s: s.split('"*"')")
                            # TODO: implement
                        ;;
                        *)
                            echo "NameError: name '$AP_ACTION_TYPE' is not defined"
                            return 2
                        ;;
                    esac
                ;;
                choices)
                    echo "AP_ACTION_CHOICES ($_AP_KEYWORD_VALUE) $_AP_VALUE_IS_STRING"
                    $_AP_VALUE_IS_STRING && {
                        _split_chars "$AP_ACTION_CHOICES" ' '
                        AP_ACTION_CHOICES="$_AP_STRING"
                    } || {
                        _AP_KEYWORD_VALUE=${_AP_KEYWORD_VALUE#[}
                        _AP_KEYWORD_VALUE=${_AP_KEYWORD_VALUE%]}
                        IFS=','
                        eval set -- $_AP_STRING
                        IFS=$AP_POSIX_IFS
                        AP_ACTION_CHOICES=
                        for _AP_STRING
                        do
                            _str_replace -- "$_AP_STRING" "'" "'\''"
                            AP_ACTION_CHOICES="${AP_ACTION_CHOICES:+$AP_ACTION_CHOICES }'$_AP_STRING'"
                        done
                    }
                ;;
                required)
                    _is_none_value &&
                    AP_ACTION_REQUIRED=$_AP_KEYWORD_VALUE || AP_ACTION_REQUIRED=
                    case "$AP_ACTION_REQUIRED" in
                        "" | 0 | False)
                            AP_ACTION_REQUIRED=false
                        ;;
                        1 | True)
                            AP_ACTION_REQUIRED=true
                        ;;
                        *)
                            echo "NameError: name '$AP_ACTION_REQUIRED' is not defined"
                            return 2
                        ;;
                    esac
                    $_AP_IS_OPTION || {
                        echo "TypeError: 'required' is an invalid argument for positionals"
                        return 2
                    }
                ;;
                help)
                    _is_none_value &&
                    AP_ACTION_HELP=$_AP_KEYWORD_VALUE || AP_ACTION_HELP=
                ;;
                metavar)
                    _is_none_value &&
                    AP_ACTION_METAVAR=$_AP_KEYWORD_VALUE || AP_ACTION_METAVAR=
                ;;
                version)
                    _is_none_value &&
                    AP_ACTION_VERSION=$_AP_KEYWORD_VALUE || AP_ACTION_VERSION=
                    AP_ACTION_VERSION_IS_SET=true
                ;;
                dest_prefix)
                    _is_none_value &&
                    AP_ACTION_DEST_PREFIX=$_AP_KEYWORD_VALUE || AP_ACTION_DEST_PREFIX=
                ;;
            esac
        ;;
        *)
            echo "TypeError: add_argument got an unexpected keyword argument '$_AP_KEYWORD'"
            return 2
        ;;
    esac
}

_set_action_positional_args ()
{
    case "$_AP_ARG" in
        ["$AP_PARSER_PREFIX_CHARS"]["$AP_PARSER_PREFIX_CHARS"]?*)
            case "$AP_ACTION_LONG_OPTION" in
                "")
                    AP_ACTION_LONG_OPTION=${_AP_ARG#"${_AP_ARG%%[!"$AP_PARSER_PREFIX_CHARS"]*}"}
                    _str_replace -- "$AP_ACTION_LONG_OPTION" '-' '_'
                    AP_ACTION_LONG_OPTION="$_AP_STRING"
                ;;
            esac
            AP_ACTION_OPTION_STRINGS="$AP_ACTION_OPTION_STRINGS $_AP_ARG "
        ;;
        ["$AP_PARSER_PREFIX_CHARS"]?*)
            case "$AP_ACTION_SHORT_OPTION" in
                "")
                    AP_ACTION_SHORT_OPTION=${_AP_ARG#?}
                ;;
            esac
            AP_ACTION_OPTION_STRINGS="$AP_ACTION_OPTION_STRINGS $_AP_ARG "
        ;;
        *)
            AP_ACTION_POSITION_ARG=$_AP_ARG
            _AP_IS_OPTION=false
        ;;
    esac
}

add_argument ()
{
    AP_ACTION_OPTION_STRINGS=
    AP_ACTION_DEST=
    AP_ACTION_NARGS=None
    AP_ACTION_CONST=
    AP_ACTION_DEFAULT=
    AP_ACTION_TYPE=
    AP_ACTION_CHOICES=
    AP_ACTION_REQUIRED=false
    AP_ACTION_HELP=
    AP_ACTION_VERSION=
    AP_ACTION_VERSION_IS_SET=false
    AP_ACTION_METAVAR=
    AP_ACTION_ADD_METAVAR=true

    AP_ACTION=store

    AP_ACTION_DEST_PREFIX=$AP_PARSER_DEFAULT_DEST_PREFIX
    AP_ACTION_LONG_OPTION=
    AP_ACTION_SHORT_OPTION=
    AP_ACTION_POSITION_ARG=

    _AP_IS_OPTION=true

    _AP_SEEN_KEYWORDS=
    _AP_KEYWORD=
    _AP_KEYWORD_VALUE=
    _AP_VALUE_IS_STRING=false

    _parse_arg_sequence "$@" &&
    _set_positional_kwargs action "$@" || return

    AP_ACTION_DEST=${AP_ACTION_DEST:-${AP_ACTION_LONG_OPTION:-${AP_ACTION_SHORT_OPTION:-${AP_ACTION_POSITION_ARG:-}}}}
    case "$AP_ACTION_DEST" in
        "")
            echo "TypeError: missing 1 required positional argument: 'dest'"
            return 2
        ;;
        ["$AP_DIGITS"]*)
            echo "SyntaxError: invalid decimal literal"
            return 2
        ;;
        *[!_"$AP_ALNUM"]*)
            echo "AttributeError: 'Namespace' object has no attribute '$AP_ACTION_DEST'"
            return 2
        ;;
        *)
            _str_replace -- "$AP_ACTION_DEST" '-' '_'
            _to_$AP_PARSER_CASE_STYLE "$_AP_STRING"
            AP_ACTION_DEST=${AP_ACTION_DEST_PREFIX:+${AP_ACTION_DEST_PREFIX}_}$_AP_STRING
        ;;
    esac

    case "$AP_ACTION" in
        store | append | extend)
            case "$AP_ACTION_CONST" in
                "")
                    case "$AP_ACTION_NARGS" in
                        None | "")
                            AP_ACTION_NARGS=None
                            AP_ACTION_NARGS_COUNT=1
                            $_AP_IS_OPTION || AP_ACTION_REQUIRED=true
                        ;;
                        [?*])
                            AP_ACTION_NARGS_COUNT="$AP_ACTION_NARGS"
                        ;;
                        *)
                            AP_ACTION_NARGS_COUNT="$AP_ACTION_NARGS"
                            $_AP_IS_OPTION || AP_ACTION_REQUIRED=true
                        ;;
                    esac
                ;;
                *)
                    case "$AP_ACTION_NARGS" in
                        '?')
                            AP_ACTION_NARGS_COUNT=1
                        ;;
                        *)
                            echo "ValueError: nargs must be '?' to supply const"
                            return 2
                        ;;
                    esac
                ;;
            esac
        ;;
        *)
            case "$AP_ACTION_NARGS" in
                None | "")
                    AP_ACTION_NARGS=None
                    AP_ACTION_NARGS_COUNT=0
                ;;
                *)
                    echo "TypeError: action=$AP_ACTION got an unexpected keyword argument 'nargs'"
                    return 2
                ;;
            esac

            case "$AP_ACTION_TYPE" in
                ?*)
                    echo "TypeError: action=$AP_ACTION got an unexpected keyword argument 'type'"
                    return 2
                ;;
            esac

            case "$AP_ACTION_CHOICES" in
                ?*)
                    echo "TypeError: action=$AP_ACTION got an unexpected keyword argument 'choices'"
                    return 2
                ;;
            esac

            $_AP_IS_OPTION || AP_ACTION_REQUIRED=true
            case "$AP_ACTION" in
                append_const)
                ;;
                store_const)
                ;;
                *)
                    case "$AP_ACTION_CONST" in
                        None | "")
                            AP_ACTION_CONST=
                        ;;
                        *)
                            echo "TypeError: action=$AP_ACTION got an unexpected keyword argument 'const'"
                            return 2
                        ;;
                    esac

                    case "$AP_ACTION_METAVAR" in
                        ?*)
                            echo "TypeError: action=$AP_ACTION got an unexpected keyword argument 'metavar'"
                            return 2
                        ;;
                    esac

                    AP_ACTION_ADD_METAVAR=false

                    case "$AP_ACTION" in
                        count)
                        ;;
                        help)
                            $_AP_IS_OPTION || ! $AP_ACTION_REQUIRED
                        ;;
                        store_false)
                            AP_ACTION_DEFAULT=${AP_ACTION_DEFAULT:-true}
                        ;;
                        store_true)
                            AP_ACTION_DEFAULT=${AP_ACTION_DEFAULT:-false}
                        ;;
                        version)
                            $_AP_IS_OPTION || ! $AP_ACTION_REQUIRED
                            AP_ACTION_HELP="${AP_ACTION_HELP:-"show program's version number and exit"}"
                            AP_ACTION_DEFAULT=
                        ;;
                    esac || {
                        echo "TypeError: action=$AP_ACTION got an unexpected keyword argument 'required'"
                        return 2
                    }
                ;;
            esac
        ;;
    esac

    _AP_INDEX=$((_AP_INDEX + 1))
    _AP_INDEXES="$_AP_INDEXES $_AP_INDEX"
    $AP_ACTION_REQUIRED &&
        _AP_REQUIRED_INDEXES="$_AP_REQUIRED_INDEXES $_AP_INDEX " || :

    eval AP_ACTION_OPTION_STRINGS_$_AP_INDEX=\$AP_ACTION_OPTION_STRINGS \
         AP_ACTION_SHORT_OPTION_$_AP_INDEX=\$AP_ACTION_SHORT_OPTION \
         AP_ACTION_LONG_OPTION_$_AP_INDEX=\$AP_ACTION_LONG_OPTION \
         AP_ACTION_POSITION_ARG_$_AP_INDEX=\$AP_ACTION_POSITION_ARG \
         AP_ACTION_DEST_$_AP_INDEX=\$AP_ACTION_DEST \
         AP_ACTION_NARGS_$_AP_INDEX=\$AP_ACTION_NARGS \
         AP_ACTION_NARGS_COUNT_$_AP_INDEX=\$AP_ACTION_NARGS_COUNT \
         AP_ACTION_CONST_$_AP_INDEX=\$AP_ACTION_CONST \
         AP_ACTION_DEFAULT_$_AP_INDEX=\$AP_ACTION_DEFAULT \
         AP_ACTION_TYPE_$_AP_INDEX=\$AP_ACTION_TYPE \
         AP_ACTION_CHOICES_$_AP_INDEX=\$AP_ACTION_CHOICES \
         AP_ACTION_REQUIRED_$_AP_INDEX=\$AP_ACTION_REQUIRED \
         AP_ACTION_HELP_$_AP_INDEX=\$AP_ACTION_HELP \
         AP_ACTION_VERSION_$_AP_INDEX=\$AP_ACTION_VERSION \
         AP_ACTION_VERSION_IS_SET_$_AP_INDEX=\$AP_ACTION_VERSION_IS_SET \
         AP_ACTION_METAVAR_$_AP_INDEX=\$AP_ACTION_METAVAR \
         AP_ACTION_ADD_METAVAR_$_AP_INDEX=\$AP_ACTION_ADD_METAVAR \
         AP_ACTION_$_AP_INDEX=\$AP_ACTION
}

_format_choices_metavar ()
{
    eval set -- "$AP_ACTION_CHOICES"
    _str_replace -- "$*" ' ' ","
    AP_ACTION_METAVAR="{$_AP_STRING}"
}

_get_positional_strings ()
{
    $AP_PARSER_FORMATTER_CLASS_METAVARTYPE && {
        case "$AP_ACTION_TYPE" in
            "")
                echo "AttributeError: 'NoneType' object has no attribute '__name__'"
                return 2
            ;;
        esac && AP_ACTION_METAVAR=$AP_ACTION_TYPE
    } || {
        case "${AP_ACTION_METAVAR:-}" in
            "")
                case "${AP_ACTION_CHOICES:-}" in
                    "")
                        AP_ACTION_METAVAR=$AP_ACTION_POSITION_ARG
                    ;;
                    *)
                        _format_choices_metavar
                    ;;
                esac
            ;;
            *)
                AP_ACTION_METAVAR=$AP_ACTION_METAVAR
            ;;
        esac
    }

    case "$AP_ACTION_NARGS" in
        None)
            _AP_USAGE_STR="$AP_ACTION_METAVAR"
        ;;
        '?')
            _AP_USAGE_STR="[$AP_ACTION_METAVAR]"
        ;;
        '*')
            _AP_USAGE_STR="[$AP_ACTION_METAVAR ...]"
        ;;
        '+')
            _AP_USAGE_STR="$AP_ACTION_METAVAR [$AP_ACTION_METAVAR ...]"
        ;;
        *)
            _AP_BUFFER=
            _AP_COUNT=$AP_ACTION_NARGS
            while
                case "$_AP_COUNT" in
                    0)
                        false
                    ;;
                esac
            do
                _AP_BUFFER="$_AP_BUFFER $AP_ACTION_METAVAR"
                _AP_COUNT=$((_AP_COUNT - 1))
            done
            _AP_BUFFER="${_AP_BUFFER#"${_AP_BUFFER%%[!"$AP_SPACE"]*}"}"
            _AP_USAGE_STR=$_AP_BUFFER
        ;;
    esac
    _AP_USAGE_POSITION_STR="$_AP_USAGE_POSITION_STR '$_AP_USAGE_STR'"
}

_get_option_strings ()
{
    $AP_ACTION_ADD_METAVAR && {
        $AP_PARSER_FORMATTER_CLASS_METAVARTYPE &&
        case "$AP_ACTION_TYPE" in
            "")
                echo "AttributeError: 'NoneType' object has no attribute '__name__'"
                return 2
            ;;
        esac && AP_ACTION_METAVAR=$AP_ACTION_TYPE || :
    } &&
    case "$AP_ACTION_METAVAR" in
        "")
            case "${AP_ACTION_CHOICES:-}" in
                "")
                    _to_upper "${AP_ACTION_LONG_OPTION:-$AP_ACTION_SHORT_OPTION}"
                    AP_ACTION_METAVAR=$_AP_STRING
                ;;
                *)
                    _format_choices_metavar
                ;;
            esac
        ;;
    esac &&
    case "$AP_ACTION_NARGS" in
        None | "")
        ;;
        '?')
            AP_ACTION_METAVAR="[$AP_ACTION_METAVAR]"
        ;;
        '*')
            AP_ACTION_METAVAR="[$AP_ACTION_METAVAR ...]"
        ;;
        '+')
            AP_ACTION_METAVAR="$AP_ACTION_METAVAR [$AP_ACTION_METAVAR ...]"
        ;;
        *)
            _AP_BUFFER=
            _AP_COUNT=$AP_ACTION_NARGS
            while
                case "$_AP_COUNT" in
                    0)
                        false
                    ;;
                esac
            do
                _AP_BUFFER="$_AP_BUFFER $AP_ACTION_METAVAR"
                _AP_COUNT=$((_AP_COUNT - 1))
            done
            _AP_BUFFER="${_AP_BUFFER#"${_AP_BUFFER%%[!"$AP_SPACE"]*}"}"
            AP_ACTION_METAVAR=$_AP_BUFFER
        ;;
    esac && _AP_USAGE_STR="$1 $AP_ACTION_METAVAR" || _AP_USAGE_STR="$1"

    $AP_ACTION_REQUIRED || _AP_USAGE_STR="[$_AP_USAGE_STR]"
    _AP_USAGE_OPTION_STR="$_AP_USAGE_OPTION_STR '$_AP_USAGE_STR'"
}

_set_max_lenght_indent ()
{
    _AP_ACTION_LEN=$1
    case $((AP_MAX_ACTION_LEN >= _AP_ACTION_LEN )) in
        0)
            AP_MAX_ACTION_LEN=$_AP_ACTION_LEN
        ;;
    esac
}

_save_metavar_help ()
{
    _set_max_lenght_indent ${#_AP_METAVAR}
    eval _AP_METAVAR_$_AP_INDEX='$_AP_METAVAR' \
         _AP_DEFAULT_$_AP_INDEX='$AP_ACTION_DEFAULT' \
            _AP_HELP_$_AP_INDEX='$AP_ACTION_HELP'
    # see _format_Default
    # eval _AP_METAVAR_$_AP_INDEX="\\''$_AP_METAVAR'\\'" \
    #      _AP_DEFAULT_$_AP_INDEX='$AP_ACTION_DEFAULT' \
    #         _AP_HELP_$_AP_INDEX='$AP_ACTION_HELP'
}

_save_positional_help_string ()
{
    _AP_METAVAR="$AP_ACTION_METAVAR"
    _save_metavar_help
    _AP_HELP_POSITIONAL_INDEXES="$_AP_HELP_POSITIONAL_INDEXES $_AP_INDEX"
}

_save_option_help_string ()
{
    _AP_METAVAR=
    $AP_ACTION_ADD_METAVAR && {
        for _AP_I
        do
            _AP_METAVAR="${_AP_METAVAR:+$_AP_METAVAR, }$_AP_I $AP_ACTION_METAVAR"
        done
    } || {
        for _AP_I
        do
            _AP_METAVAR="${_AP_METAVAR:+$_AP_METAVAR, }$_AP_I"
        done
    }
    _save_metavar_help
    _AP_HELP_OPTIONS_INDEXES="$_AP_HELP_OPTIONS_INDEXES $_AP_INDEX"
}

_get_usage_string ()
{
    AP_ACTION_USAGE="'usage:${AP_PARSER_PROG:+ $AP_PARSER_PROG:}'"
    _AP_USAGE_OPTION_STR=
    _AP_USAGE_POSITION_STR=
    for _AP_INDEX in $_AP_INDEXES
    do
        eval AP_ACTION_OPTION_STRINGS=\$AP_ACTION_OPTION_STRINGS_$_AP_INDEX \
             AP_ACTION_SHORT_OPTION=\$AP_ACTION_SHORT_OPTION_$_AP_INDEX \
             AP_ACTION_LONG_OPTION=\$AP_ACTION_LONG_OPTION_$_AP_INDEX \
             AP_ACTION_POSITION_ARG=\$AP_ACTION_POSITION_ARG_$_AP_INDEX \
             AP_ACTION_DEFAULT=\$AP_ACTION_DEFAULT_$_AP_INDEX \
             AP_ACTION_TYPE=\$AP_ACTION_TYPE_$_AP_INDEX \
             AP_ACTION_NARGS=\$AP_ACTION_NARGS_$_AP_INDEX \
             AP_ACTION_CHOICES=\$AP_ACTION_CHOICES_$_AP_INDEX \
             AP_ACTION_REQUIRED=\$AP_ACTION_REQUIRED_$_AP_INDEX \
             AP_ACTION_HELP=\$AP_ACTION_HELP_$_AP_INDEX \
             AP_ACTION_METAVAR=\$AP_ACTION_METAVAR_$_AP_INDEX \
             AP_ACTION_ADD_METAVAR=\$AP_ACTION_ADD_METAVAR_$_AP_INDEX

        set -- $AP_ACTION_OPTION_STRINGS
        case "${1:-}" in
            "")
                _get_positional_strings &&
                case "$_AP_PRINT_INFO" in
                    print_help)
                        _save_positional_help_string
                    ;;
                esac
            ;;
            *)
                _get_option_strings "$1" &&
                case "$_AP_PRINT_INFO" in
                    print_help)
                        _save_option_help_string "$@"
                    ;;
                esac
            ;;
        esac || return
    done
    AP_ACTION_USAGE="$AP_ACTION_USAGE$_AP_USAGE_OPTION_STR$_AP_USAGE_POSITION_STR"
}

_get_indent_string ()
{
    _AP_STRING=${1:-}
    case "$_AP_STRING" in
        0 | "")
            _AP_STRING=
            _AP_STRING_LEN=0
            return
        ;;
        *[!"$AP_DIGITS"]*)
            _AP_STRING=${#_AP_STRING}
        ;;
    esac
    _AP_STRING_LEN=$_AP_STRING
    _AP_COUNT=0
    _AP_STRING=
    while
        case $((_AP_COUNT == _AP_STRING_LEN)) in
            1)
                false
            ;;
        esac
    do
        _AP_COUNT=$((_AP_COUNT + 1))
        _AP_STRING="$_AP_STRING "
    done
}

_textwrap ()
{
    for _AP_I
    do
        case $((_AP_REMAIND >= ${#_AP_I})) in
            1)
                _AP_STRING="$_AP_STRING $_AP_I"
                _AP_REMAIND=$((_AP_REMAIND - ${#_AP_I} - 1))
            ;;
            0)
                _AP_STRING="$_AP_STRING$AP_LF$_AP_INDENT$_AP_I"
                _AP_REMAIND=$((_AP_COLUMNS - _AP_INDENT_LEN - ${#_AP_I} - 1))
            ;;
        esac
    done
}

_format_usage ()
{
    _get_terminal_size && _AP_COLUMNS=$((COLUMNS - 2))
    _get_usage_string || return
    eval set -- "$AP_ACTION_USAGE"

    _AP_REMAIND=$((_AP_COLUMNS - ${#1} - 1))
    case $((_AP_REMAIND >= ${#2})) in
        1)
            _get_indent_string $((${#1} + 1))
        ;;
        0)
            _get_indent_string 7
        ;;
    esac
    _AP_INDENT="$_AP_STRING"
    _AP_INDENT_LEN="$_AP_STRING_LEN"
    _AP_STRING=$1
    shift
    _textwrap "$@"
    AP_ACTION_USAGE="$_AP_STRING"
}

print_usage ()
{
    _format_usage || return
    echo "$AP_ACTION_USAGE"
}

_error ()
{
    print_usage || return
    echo "${AP_PARSER_PROG:+$AP_PARSER_PROG: }${1:-}"
}

_format_action_indent ()
{
    case $((_AP_COLUMNS >= 46)) in
        1)  _AP_INDENT_LEN=24 ;;
        *)  case $((_AP_COLUMNS >= 26)) in
                1)  _AP_INDENT_LEN=$((_AP_COLUMNS - 22)) ;;
                *)  _AP_INDENT_LEN=4 ;;
            esac ;;
    esac

    AP_MAX_ACTION_LEN=$((AP_MAX_ACTION_LEN + 4))
    case $((AP_MAX_ACTION_LEN >= _AP_INDENT_LEN)) in
        0)  _AP_INDENT_LEN=$AP_MAX_ACTION_LEN ;;
    esac

    _get_indent_string "$_AP_INDENT_LEN"
    _AP_INDENT="$_AP_STRING"
    _AP_INDENT_LEN="$_AP_STRING_LEN"
}

_format_description ()
{
    case "$AP_PARSER_DESCRIPTION" in
        ?*)
            $AP_PARSER_FORMATTER_CLASS_RAWDESCRIPTION ||
            $AP_PARSER_FORMATTER_CLASS_RAWTEXT || {
                set -- $AP_PARSER_DESCRIPTION
                        AP_PARSER_DESCRIPTION="$*"
            }
            AP_ACTION_HELP="$AP_ACTION_USAGE$AP_LF$AP_LF$AP_PARSER_DESCRIPTION"
        ;;
        *)
            AP_ACTION_HELP="$AP_ACTION_USAGE"
        ;;
    esac
}

_get_metavar_help ()
{
    eval _AP_METAVAR=\$_AP_METAVAR_$_AP_INDEX \
         _AP_DEFAULT=\$_AP_DEFAULT_$_AP_INDEX \
            _AP_HELP=\$_AP_HELP_$_AP_INDEX
}

_format_Default ()
{
    $AP_PARSER_FORMATTER_CLASS_RAWTEXT && set -- ${_AP_HELP:+"$_AP_HELP"} || {
        set -- $_AP_HELP
        # see _save_metavar_help
        # _str_replace -- "$_AP_HELP" "'" "'\''"
        # eval set -- "'$_AP_STRING'"
    }

    case $# in
        0)
            AP_ACTION_HELP="$AP_ACTION_HELP$AP_LF  $_AP_METAVAR"
            return
        ;;
    esac

    _AP_REMAIND=$((_AP_COLUMNS - _AP_INDENT_LEN))
    _AP_METAVAR_LEN=$((${#_AP_METAVAR} + 4))

    case $((_AP_INDENT_LEN >= _AP_METAVAR_LEN)) in
        1)
            case $((_AP_REMAIND >= ${#1})) in
                1)
                    _get_indent_string $((_AP_INDENT_LEN - _AP_METAVAR_LEN + 1))
                    _AP_STRING="  $_AP_METAVAR$_AP_STRING"
                ;;
                0)
                    _AP_STRING="  $_AP_METAVAR"
                ;;
            esac
        ;;
        0)
            case $((_AP_REMAIND >= ${#1})) in
                1)
                    _get_indent_string $((_AP_INDENT_LEN - 1))
                    _AP_STRING="  $_AP_METAVAR$AP_LF$_AP_STRING"
                ;;
                0)
                    _AP_STRING="  $_AP_METAVAR"
                ;;
            esac
        ;;
    esac

    _textwrap "$@"
    AP_ACTION_HELP="$AP_ACTION_HELP$AP_LF$_AP_STRING"
}

_append_help ()
{
    _get_metavar_help
    $AP_PARSER_FORMATTER_CLASS_ARGUMENTDEFAULTS &&
    case "${_AP_HELP:-}" in
        ?*)
            _AP_HELP="$_AP_HELP (default: ${_AP_DEFAULT:-None})"
        ;;
    esac || :
    _format_Default
}

_format_action_help ()
{
    case "$_AP_HELP_POSITIONAL_INDEXES" in
        ?*)
            AP_ACTION_HELP="$AP_ACTION_HELP$AP_LF$AP_LF$_AP_HELP_POSITIONAL_HEADER"
            for _AP_INDEX in $_AP_HELP_POSITIONAL_INDEXES
            do
                _append_help || return
            done
        ;;
    esac
    case "$_AP_HELP_OPTIONS_INDEXES" in
        ?*)
            AP_ACTION_HELP="$AP_ACTION_HELP$AP_LF$AP_LF$_AP_HELP_OPTIONS_HEADER"
            for _AP_INDEX in $_AP_HELP_OPTIONS_INDEXES
            do
                _append_help || return
            done
        ;;
    esac
}

_format_epilog ()
{
    case "$AP_PARSER_EPILOG" in
        ?*)
            $AP_PARSER_FORMATTER_CLASS_RAWDESCRIPTION ||
            $AP_PARSER_FORMATTER_CLASS_RAWTEXT || {
                set -- $AP_PARSER_EPILOG
                        AP_PARSER_EPILOG="$*"
            }
            AP_ACTION_HELP="$AP_ACTION_HELP$AP_LF$AP_LF$AP_PARSER_EPILOG"
        ;;
    esac
}

_format_help ()
{
    AP_ACTION_HELP=
    _AP_HELP_POSITIONAL_HEADER="positional arguments:"
    _AP_HELP_POSITIONAL_INDEXES=
    _AP_HELP_OPTIONS_HEADER="options:"
    _AP_HELP_OPTIONS_INDEXES=
    _AP_HELP_MAX_LENGHT_INDENT=0
    _format_usage &&
    _format_action_indent &&
    _format_description &&
    _format_action_help &&
    _format_epilog || return
}

print_help ()
{
    _format_help || return
    echo "$AP_ACTION_HELP"
}

print_version ()
{
    eval AP_ACTION_VERSION=\$AP_ACTION_VERSION_$_AP_VERSION_INDEX \
         AP_ACTION_VERSION_IS_SET=\$AP_ACTION_VERSION_IS_SET_$_AP_VERSION_INDEX

    $AP_ACTION_VERSION_IS_SET && {
        $AP_PARSER_FORMATTER_CLASS_RAWDESCRIPTION ||
        $AP_PARSER_FORMATTER_CLASS_RAWTEXT || {
            set -- $AP_ACTION_VERSION
                    AP_ACTION_VERSION="$*"
        }
        echo "$AP_ACTION_VERSION"
    } || {
        echo "AttributeError: 'ArgumentParser' object has no attribute 'version'"
        return 2
    }
}

_add_help ()
{
    _AP_INDEX=0
    _AP_INDEXES="$_AP_INDEX$_AP_INDEXES"
    eval AP_ACTION_OPTION_STRINGS_$_AP_INDEX="' -h --help '" \
         AP_ACTION_DEFAULT_$_AP_INDEX= \
         AP_ACTION_REQUIRED_$_AP_INDEX=false \
         AP_ACTION_HELP_$_AP_INDEX="'show this help message and exit'" \
         AP_ACTION_METAVAR_$_AP_INDEX= \
         AP_ACTION_ADD_METAVAR_$_AP_INDEX=false \
         AP_ACTION_$_AP_INDEX=help
}

_apply_const ()
{
    case "$AP_ACTION_CONST" in
        *[!\."$AP_DIGITS"]*)
            case "$AP_ACTION_TYPE" in
                "" | str)
                    _str_replace -- "$AP_ACTION_CONST" "'" "'\''"
                    eval $AP_ACTION_DEST="'$_AP_STRING'"
                ;;
                *)
                    false
                ;;
            esac
        ;;
        *[!"$AP_DIGITS"]*)
            case "$AP_ACTION_TYPE" in
                float)
                    eval $AP_ACTION_DEST="'$_AP_ARG'"
                ;;
                *)
                    false
                ;;
            esac
        ;;
        *)
            case "$AP_ACTION_TYPE" in
                int)
                    eval $AP_ACTION_DEST="'$_AP_ARG'"
                ;;
                *)
                    false
                ;;
            esac
        ;;
    esac || {
        set -- $AP_ACTION_OPTION_STRINGS
        _str_replace -- "$*" ' ' '/'
        _error "error: argument $_AP_STRING: invalid $AP_ACTION_TYPE value: '$AP_ACTION_CONST'"
        return 2
    }
}

_prev_has_value ()
{
    case "$AP_ACTION_NARGS_COUNT" in
        [0?*] | "")
            true
        ;;
        *)
            case "$AP_ACTION_CONST" in
                ?*)
                    _apply_const || return
                    return
                ;;
            esac

            set -- $AP_ACTION_OPTION_STRINGS
            _str_replace -- "$*" ' ' '/'
            case $AP_ACTION_NARGS in
                None)
                    AP_ACTION_NARGS='one argument'
                ;;
                +)
                    AP_ACTION_NARGS='at least one argument'
                ;;
                1)
                    AP_ACTION_NARGS='1 argument'
                ;;
                *)
                    AP_ACTION_NARGS="$AP_ACTION_NARGS arguments"
                ;;
            esac
            _error "error: argument $_AP_STRING: expected $AP_ACTION_NARGS"
            return 2
        ;;
    esac
}

_set_action_state ()
{
    eval AP_ACTION_OPTION_STRINGS=\$AP_ACTION_OPTION_STRINGS_$_AP_INDEX \
         AP_ACTION_DEST=\$AP_ACTION_DEST_$_AP_INDEX \
         AP_ACTION_NARGS=\$AP_ACTION_NARGS_$_AP_INDEX \
         AP_ACTION_NARGS_COUNT=\$AP_ACTION_NARGS_COUNT_$_AP_INDEX \
         AP_ACTION_CONST=\$AP_ACTION_CONST_$_AP_INDEX \
         AP_ACTION_DEFAULT=\$AP_ACTION_DEFAULT_$_AP_INDEX \
         AP_ACTION_TYPE=\$AP_ACTION_TYPE_$_AP_INDEX \
         AP_ACTION_CHOICES=\$AP_ACTION_CHOICES_$_AP_INDEX \
         AP_ACTION_REQUIRED=\$AP_ACTION_REQUIRED_$_AP_INDEX \
         AP_ACTION_HELP=\$AP_ACTION_HELP_$_AP_INDEX \
         AP_ACTION_VERSION=\$AP_ACTION_VERSION_$_AP_INDEX \
         AP_ACTION_VERSION_IS_SET=\$AP_ACTION_VERSION_IS_SET_$_AP_INDEX \
         AP_ACTION_METAVAR=\$AP_ACTION_METAVAR_$_AP_INDEX \
         AP_ACTION=\$AP_ACTION_$_AP_INDEX
}

_check_choice ()
{
    case "$AP_ACTION_CHOICES" in
        ?*)
            eval set -- "$AP_ACTION_CHOICES"
            for AP_ACTION_CHOICE
            do
                case "$AP_ACTION_CHOICE" in
                    "$_AP_ARG")
                        return
                    ;;
                esac
            done
            set -- $AP_ACTION_OPTION_STRINGS
            _str_replace -- "$*" ' ' '/'
            _error "error: argument $_AP_STRING: invalid choice: '$_AP_ARG' (choose from $AP_ACTION_CHOICES)"
            return 2
        ;;
    esac
}

_set_dest_value ()
{
    case "$AP_ACTION_TYPE" in
        "" | str)
            _check_choice || return
            _str_replace -- "$_AP_ARG" "'" "'\''"
            eval $AP_ACTION_DEST="\"\${$AP_ACTION_DEST:+\$$AP_ACTION_DEST, }'$_AP_STRING'\""
        ;;
        int)
            case "$_AP_ARG" in
                *[!"$AP_DIGITS"]*)
                    false
                ;;
                *)
                    _check_choice || return
                    eval $AP_ACTION_DEST="\"\${$AP_ACTION_DEST:+\$$AP_ACTION_DEST, }$_AP_ARG\""
            esac
        ;;
        float)
            case "$_AP_ARG" in
                *[!\."$AP_DIGITS"]*)
                    false
                ;;
                *)
                    _check_choice || return
                    eval $AP_ACTION_DEST="\"\${$AP_ACTION_DEST:+\$$AP_ACTION_DEST, }$_AP_ARG\""
            esac
        ;;
        bool)
            case "$_AP_ARG" in
                "")
                    _AP_ARG=false
                ;;
                *)
                    _AP_ARG=true
            esac
            _check_choice || return
            eval $AP_ACTION_DEST="\"\${$AP_ACTION_DEST:+\$$AP_ACTION_DEST, }$_AP_ARG\""
        ;;
    esac || {
        set -- $AP_ACTION_OPTION_STRINGS
        _str_replace -- "$*" ' ' '/'
        _error "error: argument $_AP_STRING: invalid $AP_ACTION_TYPE value: '$_AP_ARG'"
        return 2
    }

    case "$AP_ACTION_NARGS_COUNT" in
        '?')
            AP_ACTION_NARGS_COUNT=0
            eval AP_ACTION_NARGS_COUNT_$_AP_INDEX=0
        ;;
        [*+])
        ;;
        *)
            AP_ACTION_NARGS_COUNT=$((AP_ACTION_NARGS_COUNT - 1))
            eval AP_ACTION_NARGS_COUNT_$_AP_INDEX=\$AP_ACTION_NARGS_COUNT
        ;;
    esac
}

_apply_action ()
{
    case "$AP_ACTION" in
        append_const)
            _str_replace -- "$AP_ACTION_CONST" "'" "'\''"
            eval $AP_ACTION_DEST="\"\${$AP_ACTION_DEST:+\$$AP_ACTION_DEST, }'$_AP_STRING'\""
        ;;
        count)
            eval $AP_ACTION_DEST=$(($AP_ACTION_DEST + 1))
        ;;
        help)
            _AP_PRINT_INFO="${_AP_PRINT_INFO:-print_help}"
        ;;
        store | append | extend)
            $_AP_ARG_IS_OPTION || _set_dest_value || return
        ;;
        store_const)
            _str_replace -- "$AP_ACTION_CONST" "'" "'\''"
            eval $AP_ACTION_DEST="\"'$_AP_STRING'\""
        ;;
        store_false)
            eval $AP_ACTION_DEST=false
        ;;
        store_true)
            eval $AP_ACTION_DEST=true
        ;;
        version)
            _AP_PRINT_INFO="${_AP_PRINT_INFO:-print_version}"
            _AP_VERSION_INDEX=${_AP_VERSION_INDEX:-$_AP_INDEX}
        ;;
    esac
}

_parse_option ()
{
    for _AP_INDEX in $_AP_INDEXES
    do
        _set_action_state
        case "$AP_ACTION_OPTION_STRINGS" in
            "")
            ;;
            *" $_AP_ARG "*)
                return
            ;;
        esac
    done
    case ${#_AP_ARG} in
        2)
            _error "invalid option -- '${_AP_ARG#?}'"
        ;;
        *)
            _error "unrecognized option '$_AP_ARG'"
        ;;
    esac
    return 2
}

_parse_arg ()
{
    case "$AP_ACTION_NARGS_COUNT" in
        0 | "")
            for _AP_INDEX in $_AP_INDEXES
            do
                _set_action_state
                case "$AP_ACTION_OPTION_STRINGS" in
                    ?*)
                        continue
                    ;;
                esac
                case "$AP_ACTION_NARGS_COUNT" in
                    [!0]*)
                        return
                    ;;
                esac
            done
            false
        ;;
    esac || {
        _error "unrecognized argument '$_AP_ARG'"
        return 2
    }
}

_set_default_value ()
{
    for _AP_INDEX in $_AP_INDEXES
    do
        case "$ACTIONS_RECEIVED_INDEXES" in
            *" $_AP_INDEX "*)
            ;;
            *)
                eval AP_ACTION_OPTION_STRINGS=\$AP_ACTION_OPTION_STRINGS_$_AP_INDEX \
                     AP_ACTION_DEST=\$AP_ACTION_DEST_$_AP_INDEX \
                     AP_ACTION_NARGS_COUNT=\$AP_ACTION_NARGS_COUNT_$_AP_INDEX \
                     AP_ACTION_TYPE=\$AP_ACTION_TYPE_$_AP_INDEX \
                     _AP_ARG=\$AP_ACTION_DEFAULT_$_AP_INDEX

                eval _AP_DEST_VALUE=\$$AP_ACTION_DEST
                case "$_AP_DEST_VALUE" in
                    "")
                        case "$_AP_ARG" in
                            "")
                                eval $AP_ACTION_DEST=
                            ;;
                            *)
                                _set_dest_value
                            ;;
                        esac
                    ;;
                esac
            ;;
        esac
    done
}

_check_required_args ()
{
    _AP_MISSING_INDEXES=
    for _AP_INDEX in $_AP_REQUIRED_INDEXES
    do
        case "$ACTIONS_RECEIVED_INDEXES" in
            *" $_AP_INDEX "*)
            ;;
            *)
                eval AP_ACTION_OPTION_STRINGS=\$AP_ACTION_OPTION_STRINGS_$_AP_INDEX
                case "$AP_ACTION_OPTION_STRINGS" in
                    "")
                        eval AP_ACTION_DEST=\$AP_ACTION_DEST_$_AP_INDEX
                        _AP_MISSING_INDEXES="${_AP_MISSING_INDEXES:+$_AP_MISSING_INDEXES, }$AP_ACTION_DEST"
                    ;;
                    *)
                        set -- $AP_ACTION_OPTION_STRINGS
                        _str_replace -- "$*" ' ' '/'
                        _AP_MISSING_INDEXES="${_AP_MISSING_INDEXES:+$_AP_MISSING_INDEXES, }$_AP_STRING"
                    ;;
                esac

            ;;
        esac
    done
    case "$_AP_MISSING_INDEXES" in
        ?*)
            _error "error: the following arguments are required: $_AP_MISSING_INDEXES"
            return 2
        ;;
    esac
}

parse_args ()
{
    ACTIONS_RECEIVED_INDEXES=
    AP_ACTION_NARGS=
    AP_ACTION_NARGS_COUNT=
    _AP_PARSING_OPTIONS=true
    _AP_VERSION_INDEX=
    _AP_PRINT_INFO=
    $AP_PARSER_ADD_HELP && _add_help || :
    while
        case $# in
            0)
                false
            ;;
        esac
    do
        _AP_ARG=$1
        _AP_ARG_IS_OPTION=false
        $_AP_PARSING_OPTIONS &&
        case "$_AP_ARG" in
            '--')
                _AP_PARSING_OPTIONS=false
                shift
                continue
            ;;
            ["$AP_PARSER_PREFIX_CHARS"]*)
                _prev_has_value &&
                _parse_option || return
                _AP_ARG_IS_OPTION=true
            ;;
            *)
                false
            ;;
        esac || _parse_arg || return
        _apply_action
        ACTIONS_RECEIVED_INDEXES="$ACTIONS_RECEIVED_INDEXES $_AP_INDEX "
        shift
    done
    _prev_has_value &&
    _set_default_value &&
    case "$_AP_PRINT_INFO" in
        "")
            _check_required_args
        ;;
        *)
            $_AP_PRINT_INFO
        ;;
    esac
}

_say_action_state ()
{
    AP_ACTION_CHOICES_STRING=${AP_ACTION_CHOICES:+[$AP_ACTION_CHOICES]}
    eval AP_ACTION_DEST_VALUE=\$$AP_ACTION_DEST
         AP_ACTION_DEST_VALUE=${AP_ACTION_DEST_VALUE:+[$AP_ACTION_DEST_VALUE]}

    echo "Action state (index $_AP_INDEX):
option_strings: ${AP_ACTION_OPTION_STRINGS:-None}
dest: $AP_ACTION_DEST: ${AP_ACTION_DEST_VALUE:-None}
nargs: $AP_ACTION_NARGS
nargs_count: $AP_ACTION_NARGS_COUNT
const: ${AP_ACTION_CONST:-None}
default: ${AP_ACTION_DEFAULT:-None}
type: ${AP_ACTION_TYPE:-None}
choices: ${AP_ACTION_CHOICES_STRING:-None}
required: $AP_ACTION_REQUIRED
help: ${AP_ACTION_HELP:-None}
metavar: ${AP_ACTION_METAVAR:-None}
action: $AP_ACTION
version: ${AP_ACTION_VERSION:-None}
version is set: ${AP_ACTION_VERSION_IS_SET:-None}
"
}

print_action_state ()
{
    case "${1:-}" in
        "")
            for _AP_INDEX in $_AP_INDEXES
            do
                _set_action_state
                _say_action_state
            done
        ;;
        *[!"$AP_DIGITS"]*)
            for _AP_INDEX in $_AP_INDEXES
            do
                eval AP_ACTION_DEST=\$AP_ACTION_DEST_$_AP_INDEX
                case "$AP_ACTION_DEST" in
                    "$1")
                        _set_action_state
                        _say_action_state
                    ;;
                esac
            done
        ;;
        *)
            for _AP_INDEX in $_AP_INDEXES
            do
                case "$_AP_INDEX" in
                    "$1")
                        _set_action_state
                        _say_action_state
                    ;;
                esac
            done
        ;;
    esac
}
