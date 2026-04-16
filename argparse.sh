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

ARG_UPPERS='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
ARG_LOWERS='abcdefghijklmnopqrstuvwxyz'
ARG_DIGIT='0123456789'
ARG_ALNUM=$ARG_LOWERS$ARG_UPPERS$ARG_DIGIT
ARG_ALPHA=$ARG_LOWERS$ARG_UPPERS
ARG_SPACE=" "

arg_lower ()
{
    ARG_TEMP=$1
    ARG_STRING=
    while
        case $((${#ARG_TEMP} > 0)) in
            0)
                false
            ;;
        esac
    do
        ARG_CHAR=${ARG_TEMP%${ARG_TEMP#?}}
        ARG_TEMP=${ARG_TEMP#?}
        case $ARG_CHAR in
            [$ARG_UPPERS])
                ARG_NUM=${ARG_UPPERS%%$ARG_CHAR*}
                ARG_NUM=$((${#ARG_NUM} + 1))
                ARG_COUNT=
                while
                    case $((${#ARG_COUNT} < $ARG_NUM)) in
                        0)
                            false
                        ;;
                    esac
                do
                    ARG_COUNT=$ARG_COUNT?
                done
                ARG_CHAR=${ARG_LOWERS%${ARG_LOWERS#$ARG_COUNT}}
                ARG_CHAR=${ARG_CHAR#${ARG_CHAR%?}}
            ;;
        esac
        ARG_STRING=${ARG_STRING:-}$ARG_CHAR
    done
    ARG_STRING=arg_$ARG_STRING
}

arg_upper ()
{
    ARG_TEMP=$1
    ARG_STRING=
    while
        case $((${#ARG_TEMP} > 0)) in
            0)
                false
            ;;
        esac
    do
        ARG_CHAR=${ARG_TEMP%${ARG_TEMP#?}}
        ARG_TEMP=${ARG_TEMP#?}
        case $ARG_CHAR in
            [$ARG_LOWERS])
                ARG_NUM=${ARG_LOWERS%%$ARG_CHAR*}
                ARG_NUM=$((${#ARG_NUM} + 1))
                ARG_COUNT=
                while
                    case $((${#ARG_COUNT} < $ARG_NUM)) in
                        0)
                            false
                        ;;
                    esac
                do
                    ARG_COUNT=$ARG_COUNT?
                done
                ARG_CHAR=${ARG_UPPERS%${ARG_UPPERS#$ARG_COUNT}}
                ARG_CHAR=${ARG_CHAR#${ARG_CHAR%?}}
            ;;
        esac
        ARG_STRING=${ARG_STRING:-}$ARG_CHAR
    done
    ARG_STRING=ARG_$ARG_STRING
}

arg_replace ()
{
########################################################################
    # replace sub string in string
    # $1 - pattern
    # $2 - replace
########################################################################
    ARG_LOOP_REPLACE=false
    while true
    do
        case "$1" in
            --)
                shift
                break
            ;;
            -l)
                ARG_LOOP_REPLACE=true
                shift
            ;;
            *)
                break
            ;;
        esac
    done
    ARG_STRING="$1"
    while
        case "$ARG_STRING" in
            *$2*)
            ;;
            *)
                return
            ;;
        esac
    do
        ARG_TEMP=
        while
            case "${ARG_STRING:+${2:-}}" in
                "")
                    false
                ;;
            esac
        do
            ARG_LEFT=${ARG_STRING%%$2*}
            case "$ARG_LEFT" in
                "$ARG_STRING")
                    break
                ;;
            esac
            ARG_TEMP=$ARG_TEMP$ARG_LEFT${3:-}
            ARG_STRING=${ARG_STRING#*$2}
        done
        ARG_STRING=$ARG_TEMP$ARG_STRING
        $ARG_LOOP_REPLACE || break
    done
}

arg_unique_chars ()
{
########################################################################
    # remove dublicate characters in the string
########################################################################
    ARG_STRING=
    ARG_SEEN=
    while
        case "${ARG_VALUE:-}" in
            "")
                false
            ;;
        esac
    do
        ARG_CHAR=${ARG_VALUE%${ARG_VALUE#?}}
        ARG_VALUE=${ARG_VALUE#?}
        case "$ARG_SEEN" in
            *"$ARG_CHAR"*)
            ;;
            *)
                ARG_SEEN=$ARG_SEEN$ARG_CHAR
                ARG_STRING=$ARG_STRING$ARG_CHAR
            ;;
        esac
    done
    ARG_VALUE=$ARG_STRING
}

arg_set_parens ()
{
    case "$1" in
        [\(\)])
            ARG_OPEN_PAREN='('
            ARG_CLOSE_PAREN=')'
        ;;
        [\]\[])
            ARG_OPEN_PAREN='['
            ARG_CLOSE_PAREN=']'
        ;;
        [\{\}])
            ARG_OPEN_PAREN='{'
            ARG_CLOSE_PAREN='}'
        ;;
        [\<\>])
            ARG_OPEN_PAREN='<'
            ARG_CLOSE_PAREN='>'
        ;;
    esac
}

arg_is_terminated ()
{
    ARG_STRING=$1
    while
        case "$ARG_STRING" in
            *[\'\"]*) true  ;;
                   *) false ;;
        esac
    do
        ARG_STRING_LEFT=${ARG_STRING%%[\'\"]*}
        ARG_QUOTE=${ARG_STRING#$ARG_STRING_LEFT}
        ARG_QUOTE=${ARG_QUOTE%${ARG_QUOTE#?}}
        ARG_TEMP=${ARG_STRING#*$ARG_QUOTE}
        case "$ARG_TEMP" in
            *$ARG_QUOTE*)
                ARG_STRING=$ARG_STRING_LEFT${ARG_TEMP#*$ARG_QUOTE}
            ;;
            *)
                echo "SyntaxError: unterminated string literal (detected at line 1)"
                return 2
        esac
    done
    while
        case "$ARG_STRING" in
            *[][\(\){}\<\>]*)
                true
            ;;
            *)
                false
            ;;
        esac
    do
        ARG_STRING_LEFT=${ARG_STRING%%[][(){\}\<\>]*}
        ARG_PAREN=${ARG_STRING#$ARG_STRING_LEFT}
        ARG_PAREN=${ARG_PAREN%${ARG_PAREN#?}}
        arg_set_parens "$ARG_PAREN"
        case "$ARG_PAREN" in
            *[]\)}\>]*)
                echo "SyntaxError: closing parenthesis '$ARG_CLOSE_PAREN' does not match opening parenthesis '$ARG_OPEN_PAREN'"
                return 2
            ;;
            *)
                ARG_TEMP=${ARG_STRING#*$ARG_PARENT}
                case "$ARG_TEMP" in
                    *$ARG_CLOSE_PAREN*)
                        ARG_STRING=${ARG_TEMP#*$ARG_CLOSE_PAREN}
                    ;;
                    *)
                        echo "SyntaxError: opening parenthesis '$ARG_OPEN_PAREN' does not match closing parenthesis '$ARG_CLOSE_PAREN'"
                        return 2
                esac
            ;;
        esac
    done
}

arg_unquate ()
{
    case "$1" in
        [\"\']*)
            ARG_STRING=${1#?}
            ARG_STRING=${ARG_STRING%?}
        ;;
        *)
            ARG_STRING=$1
            false
        ;;
    esac
}

arg_validate_argument_sequence ()
{
    ARG_OPTION_IS_SET=false
    ARG_KEYWORD_IS_SET=false
    ARG_POSITION_ARG_IS_SET=false
    ARG_POSITION_ARG=

    for ARG
    do
        arg_is_terminated "$ARG" || return
        arg_unquate "$ARG" || :
        ARG=$ARG_STRING
        case "$ARG" in
            "")
                echo "ValueError: invalid option string '$ARG': must start with a character '$ARG_PREFIX_CHARS'"
                return 2
            ;;
            [$ARG_PREFIX_CHARS]*)
                if $ARG_KEYWORD_IS_SET
                then
                    echo "SyntaxError: positional argument follows keyword argument"
                    return 2
                elif $ARG_POSITION_ARG_IS_SET
                then
                    echo "ValueError: invalid option string '$ARG_POSITION_ARG': must start with a character '$ARG_PREFIX_CHARS'"
                    return 2
                else
                    ARG_OPTION_IS_SET=true
                fi
            ;;
            *[!=]*=*)
                case "$ARG" in
                    [_$ARG_ALPHA]*)
                        arg_is_terminated "${ARG#*=}"
                        case "${ARG#*=}" in
                            "")
                                echo "SyntaxError: expected argument value expression"
                                return 2
                            ;;
                        esac
                        ARG_KEYWORD_IS_SET=true
                    ;;
                    *)
                        echo "SyntaxError: invalid keyword argument name '${ARG%%=*}'"
                        return 2
                    ;;
                esac
            ;;
            *)
                if $ARG_KEYWORD_IS_SET
                then
                    echo "SyntaxError: positional argument follows keyword argument"
                    return 2
                elif $ARG_POSITION_ARG_IS_SET
                then
                    echo "ValueError: invalid option string '$ARG_POSITION_ARG': must start with a character '$ARG_PREFIX_CHARS'"
                    return 2
                else
                    ARG_POSITION_ARG_IS_SET=true
                    ARG_POSITION_ARG=$ARG
                fi
            ;;
        esac
    done
}

arg_validate_unique_kwargs ()
{
    case "$ARG_SEEN_KEYWORDS" in
        *"$ARG_KEYWORD"*)
            echo "SyntaxError: keyword argument repeated: $ARG_KEYWORD"
            return 2
        ;;
    esac
    ARG_SEEN_KEYWORDS="$ARG_SEEN_KEYWORDS $ARG_KEYWORD"
}

arg_none_is_string ()
{
    case "$ARG_VALUE" in
        None)
            $ARG_VALUE_IS_STRING
        ;;
    esac
}

set_bool_function ()
{
    case "$ARG_KEYWORD" in
        add_help)
            ARG_ADD_HELP=$1
        ;;
        allow_abbrev)
            ARG_ALLOW_ABBREV=$1
        ;;
        exit_on_error)
            ARG_EXIT_ON_ERROR=$1
        ;;
    esac
}

arg_set_positional_kwargs ()
{
    ARG_PARSER=$1
    shift
    for ARG
    do
        case "$ARG" in
            *=*)
                ARG_KEYWORD=${ARG%%=*}
                ARG_VALUE=${ARG#*=}
                arg_set_${ARG_PARSER}_kwargs || return
            ;;
            *)
                arg_unquate "$ARG" && {
                    ARG_VALUE=$ARG_STRING
                    ARG_VALUE_IS_STRING=true
                } || :
                arg_none_is_string || ARG_VALUE=
                arg_set_${ARG_PARSER}_positional_args || return
            ;;
        esac
    done
}

arg_set_parser_kwargs ()
{
    case "$ARG_KEYWORD" in
        prog | usage | description | epilog | parents | \
        formatter_class | prefix_chars | fromfile_prefix_chars | \
        argument_default | conflict_handler | \
        add_help | allow_abbrev | exit_on_error | case_style)
            arg_validate_unique_kwargs || return
            arg_unquate "$ARG_VALUE" && {
                ARG_VALUE=$ARG_STRING
                ARG_VALUE_IS_STRING=true
            } || :
            case "$ARG_VALUE" in
                *\`*)
                    echo "SyntaxError: invalid syntax"
                    return 2
                ;;
            esac
            case "$ARG_KEYWORD" in
                prog)
                    arg_none_is_string &&
                    ARG_PROG=$ARG_VALUE || ARG_PROG=
                ;;
                usage)
                    arg_none_is_string &&
                    ARG_USAGE=$ARG_VALUE || ARG_USAGE=
                ;;
                description)
                    arg_none_is_string &&
                    ARG_DESCRIPTION=$ARG_VALUE || ARG_DESCRIPTION=
                ;;
                epilog)
                    arg_none_is_string &&
                    ARG_EPILOG=$ARG_VALUE || ARG_EPILOG=
                ;;
                parents | formatter_class)
                    # TODO: implement
                ;;
                prefix_chars)
                    arg_unique_chars
                    case "$ARG_VALUE" in
                        "$ARG_PREFIX_CHARS")
                        ;;
                        "")
                            echo "ValueError: prefix_chars must be a non-empty string"
                            return 2
                        ;;
                        *)
                            ARG_PREFIX_CHARS=$ARG_VALUE
                            ARG_POSIX_PREFIX_CHARS=false
                        ;;
                    esac
                ;;
                fromfile_prefix_chars)
                    # TODO: implement
                ;;
                argument_default)
                    arg_none_is_string &&
                    ARG_ARGUMENT_DEFAULT=$ARG_VALUE || ARG_ARGUMENT_DEFAULT=
                ;;
                conflict_handler)
                    case "$ARG_VALUE" in
                        error | [Ff]alse | 0)
                        ;;
                        resolve | [Tt]rue | 1)
                            ARG_CONFLICT_HANDLER=true
                        ;;
                        *)
                            echo "ValueError: invalid conflict_resolution value: '$ARG_VALUE'"
                            return 2
                        ;;
                    esac
                ;;
                add_help | allow_abbrev | exit_on_error)
                    $ARG_VALUE_IS_STRING && {
                        case "$ARG_VALUE" in
                            ?*)
                                set_bool_function true
                            ;;
                            "")
                                set_bool_function false
                            ;;
                        esac
                    } || {
                        case "$ARG_VALUE" in
                            0 | False)
                                set_bool_function false
                            ;;
                            1 | True)
                                set_bool_function true
                            ;;
                            *[!$ARG_DIGIT]*)
                                echo "NameError: name '$ARG_VALUE' is not defined."
                                return 2
                            ;;
                            0*[!0]*)
                                echo "SyntaxError: leading zeros in decimal integer literals are not permitted; use an 0o prefix for octal integers"
                                return 2
                            ;;
                            *)
                                set_bool_function true
                            ;;
                        esac
                    }
                ;;
                case_style)
                    case "$ARG_VALUE" in
                        upper | lower)
                            ARG_CASE_STYLE=$ARG_VALUE
                        ;;
                        *)
                            echo "NameError: name '$ARG_VALUE' is not defined."
                            return 2
                        ;;
                    esac
                ;;
            esac
        ;;
        *)
            echo "TypeError: ArgumentParser got an unexpected keyword argument '$ARG_KEYWORD'"
            return 2
        ;;
    esac
}

arg_set_parser_positional_args ()
{
    if case "$ARG_PROG" in ?*) false ;; esac
    then
        ARG_PROG=$ARG_VALUE
    elif case "$ARG_USAGE" in ?*) false ;; esac
    then
        ARG_USAGE=$ARG_VALUE
    elif case "$ARG_DESCRIPTION" in ?*) false ;; esac
    then
        ARG_DESCRIPTION=$ARG_VALUE
    elif case "$ARG_EPILOG" in ?*) false ;; esac
    then
        ARG_EPILOG=$ARG_VALUE
    elif case "$ARG_PARENTS" in ?*) false ;; esac
    then
        # TODO: implement
        ARG_PARENTS=
    else
        echo "ValueError: length of metavar tuple does not match nargs"
        return 2
    fi
}

ArgumentParser ()
{
    ARG_PROG=${LOG_PREFIX:-}
    ARG_USAGE=
    ARG_DESCRIPTION=
    ARG_EPILOG=
    ARG_PARENTS=
    ARG_FORMATTER_CLASS=
    ARG_PREFIX_CHARS=-
    ARG_FROMFILE_PREFIX_CHARS=
    ARG_ARGUMENT_DEFAULT=
    ARG_CONFLICT_HANDLER=false
    ARG_ADD_HELP=true
    ARG_ALLOW_ABBREV=true
    ARG_EXIT_ON_ERROR=true

    ARG_POSIX_PREFIX_CHARS=true
    ARG_VALUE_IS_STRING=false
    ARG_CASE_STYLE='lower'

    ARG_OPTION_STRINGS=

    ARG_INDEX=0
    ARG_INDEXS=
    ARG_REQUIRED_INDEXES=

    arg_validate_argument_sequence "$@" &&
    arg_set_positional_kwargs parser "$@" || return

    ARG_PARENTS=${ARG_PARENTS:-}
    ARG_FORMATTER_CLASS=${ARG_FORMATTER_CLASS:-argparse.HelpFormatter}
    ARG_ADD_HELP=${ARG_ADD_HELP:-}
    ARG_ALLOW_ABBREV=${ARG_ALLOW_ABBREV:-}
    ARG_EXIT_ON_ERROR=${ARG_EXIT_ON_ERROR:-}
}

arg_print_parser_state ()
{
    echo "prog: $ARG_PROG
usage: $ARG_USAGE
description: $ARG_DESCRIPTION
epilog: $ARG_EPILOG
parents: $ARG_PARENTS
formatter_class: $ARG_FORMATTER_CLASS
prefix_chars: $ARG_PREFIX_CHARS
fromfile_prefix_chars: $ARG_FROMFILE_PREFIX_CHARS
argument_default: $ARG_ARGUMENT_DEFAULT
conflict_handler: $ARG_CONFLICT_HANDLER
add_help: $ARG_ADD_HELP
allow_abbrev: $ARG_ALLOW_ABBREV
exit_on_error: $ARG_EXIT_ON_ERROR
case_style: $ARG_CASE_STYLE"
}

arg_set_action_kwargs ()
{
    case "$ARG_KEYWORD" in
        action | nargs   | const | default | type | choices | required | \
        help   | metavar | dest)
            arg_validate_unique_kwargs || return
            arg_unquate "$ARG_VALUE" && {
                ARG_VALUE=$ARG_STRING
                ARG_VALUE_IS_STRING=true
            } || :
            case "$ARG_KEYWORD" in
                action)
                    arg_none_is_string &&
                    ARG_ACTION=${ARG_VALUE:-store} || ARG_ACTION=store
                    case "$ARG_ACTION" in
                        store | store_const | store_true | store_false | \
                        append | append_const | count | help | version | extend)
                        ;;
                        *)
                            echo "ValueError: unknown action \"$ARG_ACTION\""
                            return 2
                        ;;
                    esac
                ;;
                dest)
                    case "$ARG_POSITION" in
                        ?*)
                            echo "ValueError: dest supplied twice for positional argument"
                            return 2
                        ;;
                    esac
                    arg_none_is_string &&
                    ARG_DEST=$ARG_VALUE || ARG_DEST=
                ;;
                nargs)
                    arg_none_is_string &&
                    ARG_NARGS="$ARG_VALUE" || ARG_NARGS=
                    case "$ARG_NARGS" in
                        "" | [?*+])
                        ;;
                        *[!$ARG_DIGIT]*)
                            echo "NameError: name '$ARG_NARGS' is not defined"
                            return 2
                        ;;
                    esac
                ;;
                const)
                    arg_none_is_string &&
                    ARG_CONST=$ARG_VALUE || ARG_CONST=
                ;;
                default)
                    arg_none_is_string &&
                    ARG_DEFAULT=$ARG_VALUE || ARG_DEFAULT=
                ;;
                type)
                    arg_none_is_string &&
                    ARG_TYPE=$ARG_VALUE || ARG_TYPE=
                    case "$ARG_TYPE" in
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
                            echo "NameError: name '$ARG_TYPE' is not defined"
                            return 2
                        ;;
                    esac
                ;;
                choices)
                    # TODO: implement
                ;;
                required)
                    arg_none_is_string &&
                    ARG_REQUIRED=$ARG_VALUE || ARG_REQUIRED=
                    case "$ARG_REQUIRED" in
                        "" | 0 | False)
                            ARG_REQUIRED=false
                        ;;
                        1 | True)
                            ARG_REQUIRED=true
                            ARG_REQUIRED_INDEXES="$ARG_REQUIRED_INDEXES $ARG_INDEX"
                        ;;
                        *)
                            echo "NameError: name '$ARG_REQUIRED' is not defined"
                            return 2
                        ;;
                    esac
                ;;
                help)
                    # TODO: implement
                ;;
                metavar)
                    arg_none_is_string &&
                    ARG_METAVAR=$ARG_VALUE || ARG_METAVAR=
                ;;
            esac
        ;;
        *)
            echo "TypeError: ArgumentParser got an unexpected keyword argument '$ARG_KEYWORD'"
            return 2
        ;;
    esac
}

arg_set_action_positional_args ()
{
    case "$ARG" in
        [$ARG_PREFIX_CHARS][$ARG_PREFIX_CHARS]?*)
            case "$ARG_LONG_OPTION" in
                "")
                    ARG_LONG_OPTION=${ARG#${ARG%%[!$ARG_PREFIX_CHARS]*}}
                ;;
            esac
            ARG_OPTION_STRINGS="$ARG_OPTION_STRINGS $ARG "
        ;;
        [$ARG_PREFIX_CHARS]?*)
            case "$ARG_SHORT_OPTION" in
                "")
                    ARG_SHORT_OPTION=${ARG#?}
                ;;
            esac
            ARG_OPTION_STRINGS="$ARG_OPTION_STRINGS $ARG "
        ;;
        *)
            ARG_POSITION=$ARG
        ;;
    esac
}

add_argument ()
{
    ARG_OPTION_STRINGS=
    ARG_DEST=
    ARG_NARGS=None
    ARG_CONST=
    ARG_DEFAULT=
    ARG_TYPE=
    ARG_CHOICES=
    ARG_REQUIRED=false
    ARG_HELP=
    ARG_METAVAR=

    ARG_ACTION=store

    ARG_LONG_OPTION=
    ARG_SHORT_OPTION=
    ARG_POSITION=
    ARG_SEEN_KEYWORDS=
    ARG_KEYWORD=
    ARG_VALUE=

    ARG_INDEX=$((ARG_INDEX + 1))
    arg_validate_argument_sequence "$@" &&
    arg_set_positional_kwargs action "$@" || {
        ARG_RETURN_CODE=$?
        ARG_INDEX=$((ARG_INDEX - 1))
        return $ARG_RETURN_CODE
    }

    ARG_DEST=${ARG_DEST:-${ARG_LONG_OPTION:-${ARG_SHORT_OPTION:-${ARG_POSITION:-}}}}
    case "$ARG_DEST" in
        "")
            echo "TypeError: missing 1 required positional argument: 'dest'"
            return 2
        ;;
        [$ARG_DIGIT]*)
            echo "SyntaxError: invalid decimal literal"
            return 2
        ;;
        *[!_$ARG_ALNUM]*)
            echo "AttributeError: 'Namespace' object has no attribute '$ARG_DEST'"
            return 2
        ;;
        *)
            arg_replace "$ARG_DEST" '-' '_'
            arg_$ARG_CASE_STYLE "$ARG_STRING"
            ARG_DEST=$ARG_STRING
        ;;
    esac

    case "$ARG_ACTION" in
        store | append | extend)
            case $ARG_NARGS in
                None | "")
                    ARG_NARGS=None
                    ARG_NARGS_COUNT=1
                ;;
                *)
                    ARG_NARGS_COUNT="$ARG_NARGS"
                ;;
            esac
        ;;
        *)
            case $ARG_NARGS in
                None | "")
                    ARG_NARGS=None
                    ARG_NARGS_COUNT=0
                ;;
                *)
                    echo "TypeError: action=$ARG_ACTION got an unexpected keyword argument 'nargs'"
                    return 2
                ;;
            esac
        ;;
    esac

    ARG_INDEXS="$ARG_INDEXS $ARG_INDEX"

    eval ARG_OPTION_STRINGS_$ARG_INDEX=\$ARG_OPTION_STRINGS \
         ARG_DEST_$ARG_INDEX=\$ARG_DEST \
         ARG_NARGS_$ARG_INDEX=\$ARG_NARGS \
         ARG_NARGS_COUNT_$ARG_INDEX=\$ARG_NARGS_COUNT \
         ARG_CONST_$ARG_INDEX=\$ARG_CONST \
         ARG_DEFAULT_$ARG_INDEX=\$ARG_DEFAULT \
         ARG_TYPE_$ARG_INDEX=\$ARG_TYPE \
         ARG_CHOICES_$ARG_INDEX=\$ARG_CHOICES \
         ARG_REQUIRED_$ARG_INDEX=\$ARG_REQUIRED \
         ARG_HELP_$ARG_INDEX=\$ARG_HELP \
         ARG_METAVAR_$ARG_INDEX=\$ARG_METAVAR \
         ARG_ACTION_$ARG_INDEX=\$ARG_ACTION
}

arg_prev_has_value ()
{
    case "$ARG_NARGS_COUNT" in
        [0?*] | "")
            true
        ;;
        *)
            set -- $ARG_OPTION_STRINGS
            arg_replace "$*" ' ' '/'
            case $ARG_NARGS in
                None)
                    ARG_NARGS='one argument'
                ;;
                +)
                    ARG_NARGS='at least one argument'
                ;;
                1)
                    ARG_NARGS='1 argument'
                ;;
                *)
                    ARG_NARGS="$ARG_NARGS arguments"
                ;;
            esac
            echo "error: argument $ARG_STRING: expected $ARG_NARGS"
            return 2
        ;;
    esac
}

arg_set_action_state ()
{
    eval ARG_OPTION_STRINGS=\$ARG_OPTION_STRINGS_$ARG_INDEX \
         ARG_DEST=\$ARG_DEST_$ARG_INDEX \
         ARG_NARGS=\$ARG_NARGS_$ARG_INDEX \
         ARG_NARGS_COUNT=\$ARG_NARGS_COUNT_$ARG_INDEX \
         ARG_CONST=\$ARG_CONST_$ARG_INDEX \
         ARG_DEFAULT=\$ARG_DEFAULT_$ARG_INDEX \
         ARG_TYPE=\$ARG_TYPE_$ARG_INDEX \
         ARG_CHOICES=\$ARG_CHOICES_$ARG_INDEX \
         ARG_REQUIRED=\$ARG_REQUIRED_$ARG_INDEX \
         ARG_HELP=\$ARG_HELP_$ARG_INDEX \
         ARG_METAVAR=\$ARG_METAVAR_$ARG_INDEX \
         ARG_ACTION=\$ARG_ACTION_$ARG_INDEX
}

arg_is_option_string ()
{
    for ARG_INDEX in $ARG_INDEXS
    do
        case "$ARG_OPTION_STRINGS" in
            "")
            ;;
            *" $ARG_STRING "*)
                return
            ;;
        esac
    done
    case ${#ARG_STRING} in
        2)
            echo "invalid option -- '${ARG_STRING#?}'"
        ;;
        *)
            echo "unrecognized option '$ARG_STRING'"
        ;;
    esac
    return 2
}

arg_is_position ()
{
    case "$ARG_NARGS_COUNT" in
        0 | "")
            for ARG_INDEX in $ARG_INDEXS
            do
                arg_set_action_state
                case "$ARG_OPTION_STRINGS" in
                    ?*)
                        continue
                    ;;
                esac
                case "$ARG_NARGS_COUNT" in
                    [!0]*)
                        break false 2>/dev/null
                    ;;
                esac
            done
        ;;
        *)
            false
        ;;
    esac || {
        arg_replace "$ARG_STRING" "'" "'\''"
        eval $ARG_DEST="\"\${$ARG_DEST:+\$$ARG_DEST }'\$ARG_STRING'\""
        case "$ARG_NARGS_COUNT" in
            \?)
                ARG_NARGS_COUNT=0
                eval ARG_NARGS_COUNT_$ARG_INDEX=0
            ;;
            [*+])
            ;;
            *)
                ARG_NARGS_COUNT=$((ARG_NARGS_COUNT - 1))
                eval ARG_NARGS_COUNT_$ARG_INDEX=\$ARG_NARGS_COUNT
            ;;
        esac
        return
    }
    
    echo "unrecognized argument '$ARG_STRING'"
    return 2
}

arg_check_required_args ()
{
    ARG_MISSING_INDEXES=
    for ARG_INDEX in $ARG_REQUIRED_INDEXES
    do
        case "$ARG_RECEIVED_INDEXES" in
            *" $ARG_INDEX "*)
            ;;
            *)
                eval ARG_OPTION_STRINGS=\$ARG_OPTION_STRINGS_$ARG_INDEX
                case "$ARG_OPTION_STRINGS" in
                    "")
                        eval ARG_DEST=\$ARG_DEST_$ARG_INDEX
                        ARG_MISSING_INDEXES="${ARG_MISSING_INDEXES:+$ARG_MISSING_INDEXES, }$ARG_DEST"
                    ;;
                    *)
                        set -- $ARG_OPTION_STRINGS
                        arg_replace "$*" ' ' '/'
                        ARG_MISSING_INDEXES="${ARG_MISSING_INDEXES:+$ARG_MISSING_INDEXES, }$ARG_STRING"
                    ;;
                esac
                
            ;;
        esac
    done
    case "$ARG_MISSING_INDEXES" in
        ?*)
            echo "error: the following arguments are required: $ARG_MISSING_INDEXES"
            return 2
        ;;
    esac
}

parse_args ()
{
    ARG_PARSING_OPTIONS=true
    ARG_RECEIVED_INDEXES=
    ARG_NARGS=
    ARG_NARGS_COUNT=
    while
        case $# in
            0)
                false
            ;;
        esac
    do
        ARG_STRING=$1
        $ARG_PARSING_OPTIONS && {
            case "$ARG_STRING" in
                '--')
                    ARG_PARSING_OPTIONS=false
                    shift
                    continue
                ;;
                [$ARG_PREFIX_CHARS]*)
                    arg_prev_has_value &&
                    arg_set_action_state &&
                    arg_is_option_string || return
                ;;
                *)
                    arg_is_position || return
                ;;
            esac
        } || arg_is_position || return
        ARG_RECEIVED_INDEXES="$ARG_RECEIVED_INDEXES $ARG_INDEX "
        shift
    done
    arg_prev_has_value &&
    arg_check_required_args || return
}

arg_print_state ()
{
    echo "Action state (index $ARG_INDEX):
option_strings: $ARG_OPTION_STRINGS
dest: $ARG_DEST
nargs: $ARG_NARGS
nargs_count: $ARG_NARGS_COUNT
const: $ARG_CONST
default: $ARG_DEFAULT
type: $ARG_TYPE
choices: $ARG_CHOICES
required: $ARG_REQUIRED
help: $ARG_HELP
metavar: $ARG_METAVAR
action: $ARG_ACTION"
    eval echo "dest: $ARG_DEST: [\$$ARG_DEST]"
}

arg_print_action_state ()
{
    case "$1" in
        "")
            for ARG_INDEX in $ARG_INDEXS
            do
                arg_set_action_state
                arg_print_state
            done
        ;;
        *[!$ARG_DIGIT]*)
            for ARG_INDEX in $ARG_INDEXS
            do
                eval ARG_DEST=\$ARG_DEST_$ARG_INDEX
                case "$ARG_DEST" in
                    "$1")
                        arg_set_action_state
                        arg_print_state
                    ;;
                esac
            done
        ;;
        *)
            for ARG_INDEX in $ARG_INDEXS
            do
                case "$ARG_INDEX" in
                    "$1")
                        arg_set_action_state
                        arg_print_state
                    ;;
                esac
            done
        ;;
    esac
}
