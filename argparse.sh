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

ARG_EXPECTED_OPTIONS=
ARG_INDEX=0
ARG_NAMES=

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

arg_get_parenthes ()
{
    case "$1" in
        [\(\)])
            ARG_OPENING_PARENTS='('
            ARG_CLOSING_PARENTS=')'
        ;;
        [\{\}])
            ARG_OPENING_PARENTS='{'
            ARG_CLOSING_PARENTS='}'
        ;;
        [\]\[])
            ARG_OPENING_PARENTS='['
            ARG_CLOSING_PARENTS=']'
        ;;
    esac
}

arg_check_unterminated_literals ()
{
    case "$1" in
        \"*[!\"] | \'*[!\'] | [!\']*\' | [!\"]*\")
            echo "SyntaxError: unterminated string literal (detected at line 1)"
            return 2
        ;;
        [!\{]*\} | [!\(]*\) | [!\[]*\])
            arg_get_parenthes "${1#${1%?}}"
            echo "SyntaxError: closing parenthesis '$ARG_CLOSING_PARENTS' does not match opening parenthesis '$ARG_OPENING_PARENTS'"
            return 2
        ;;
        \{*[!\}]* | \(*[!\)]* | \[*[!\]]*)
            arg_get_parenthes "${1#${1%?}}"
            echo "SyntaxError: opening parenthesis '$ARG_OPENING_PARENTS' does not match closing parenthesis '$ARG_CLOSING_PARENTS'"
            return 2
        ;;
    esac
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
        arg_check_unterminated_literals "$ARG" || return
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
                        arg_check_unterminated_literals "${ARG#*=}"
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

value_is_string ()
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
                arg_set_${ARG_PARSER}_kwargs
            ;;
            *)
                arg_unquate "$ARG" && {
                    ARG_VALUE_IS_STRING=true
                    ARG_VALUE=$ARG_STRING
                } || :
                value_is_string || ARG_VALUE=
                arg_set_${ARG_PARSER}_positional_args
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
                    value_is_string &&
                    ARG_PROG=$ARG_VALUE || ARG_PROG=
                ;;
                usage)
                    value_is_string &&
                    ARG_USAGE=$ARG_VALUE || ARG_USAGE=
                ;;
                description)
                    value_is_string &&
                    ARG_DESCRIPTION=$ARG_VALUE || ARG_DESCRIPTION=
                ;;
                epilog)
                    value_is_string &&
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
                    value_is_string &&
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
                            1 | True)
                                set_bool_function true
                            ;;
                            0 | False)
                                set_bool_function false
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

    arg_validate_argument_sequence "$@" &&
    arg_set_positional_kwargs parser "$@" || return

    ARG_PARENTS=${ARG_PARENTS:-}
    ARG_FORMATTER_CLASS=${ARG_FORMATTER_CLASS:-argparse.HelpFormatter}
    ARG_ADD_HELP=${ARG_ADD_HELP:-}
    ARG_ALLOW_ABBREV=${ARG_ALLOW_ABBREV:-}
    ARG_EXIT_ON_ERROR=${ARG_EXIT_ON_ERROR:-}
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
                    value_is_string &&
                    ARG_PROG=$ARG_VALUE || ARG_PROG=
                ;;
                nargs)
                    value_is_string &&
                    ARG_USAGE=$ARG_VALUE || ARG_USAGE=
                ;;
                const)
                    value_is_string &&
                    ARG_DESCRIPTION=$ARG_VALUE || ARG_DESCRIPTION=
                ;;
                default)
                    value_is_string &&
                    ARG_EPILOG=$ARG_VALUE || ARG_EPILOG=
                ;;
                type)
                    # TODO: implement
                ;;
                choices)
                    # TODO: implement
                ;;
                required)
                    # TODO: implement
                ;;
                help)
                    # TODO: implement
                ;;
                metavar)
                    # TODO: implement
                ;;
                dest)
                    case "$ARG_POSITION" in
                        ?*)
                            echo "ValueError: dest supplied twice for positional argument"
                            return 2
                        ;;
                    esac
                    value_is_string &&
                    ARG_DEST=$ARG_VALUE || ARG_EPILOG=
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
            ARG_EXPECTED_OPTIONS="$ARG_EXPECTED_OPTIONS $ARG"
        ;;
        [$ARG_PREFIX_CHARS]?*)
            case "$ARG_SHORT_OPTION" in
                "")
                    ARG_SHORT_OPTION=${ARG#?}
                ;;
            esac
            ARG_EXPECTED_OPTIONS="$ARG_EXPECTED_OPTIONS $ARG"
        ;;
        *)
            ARG_POSITION_INDEX=$((ARG_POSITION_INDEX + 1))
        ;;
    esac
    ARG_NAME="$ARG_NAME $ARG"
}

add_argument ()
{
    ARG_ACTION=store
    ARG_NARGS=
    ARG_CONST=
    ARG_DEFAULT=
    ARG_TYPE=
    ARG_CHOICES=
    ARG_REQUIRED=false
    ARG_HELP=
    ARG_METAVAR=
    ARG_DEST=

    ARG_SEEN_KEYWORDS=
    ARG_KEYWORD=
    ARG_VALUE=

    ARG_INDEX=$((ARG_INDEX + 1))

    arg_validate_argument_sequence "$@" &&
    arg_set_positional_kwargs action "$@" || return
    ARG_DEST=${ARG_DEST:-${ARG_LONG_OPTION:-${ARG_SHORT_OPTION:-${ARG_POSITION:-}}}}

    case "$ARG_DEST" in
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

    ARG_NAMES="$ARG_NAMES ARG_${ARG_INDEX}_NAME"
    eval ARG_${ARG_INDEX}_NAME=\$ARG_NAME
    eval ARG_${ARG_INDEX}_ACTION=\$ARG_DEST
    eval ARG_${ARG_INDEX}_NARGS=\$ARG_NARGS
    eval ARG_${ARG_INDEX}_CONST=\$ARG_CONST
    eval ARG_${ARG_INDEX}_DEFAULT=\$ARG_DEFAULT
    eval ARG_${ARG_INDEX}_TYPE=\$ARG_TYPE
    eval ARG_${ARG_INDEX}_CHOICES=\$ARG_CHOICES
    eval ARG_${ARG_INDEX}_REQUIRED=\$ARG_REQUIRED
    eval ARG_${ARG_INDEX}_HELP=\$ARG_HELP
    eval ARG_${ARG_INDEX}_METAVAR=\$ARG_METAVAR
    eval ARG_${ARG_INDEX}_DEST=\$ARG_DEST
}

arg_find ()
{
    ARG_INDEX=0
    for ARG_NAME in $ARG_NAMES
    do
        ARG_INDEX=$((ARG_INDEX + 1))
        eval ARG_VALUE=$ARG_NAME
        case "$ARG_VALUE" in
            *" $ARG "*)
                return
            ;;
        esac
    done
    case $ARG in
        [$ARG_PREFIX_CHARS]*)
            case ${#ARG} in
                2)
                    echo "invalid option -- '${ARG#?}'"
                ;;
                *)
                    echo "unrecognized option '$ARG'"
                ;;
            esac
        ;;
        *)
            echo "unrecognized arguments: '$ARG'"
        ;;
    esac
    return 2
}

arg_get_settings ()
{
    eval ARG_DEST=\$ARG_${ARG_INDEX}_ACTION
    eval ARG_NARGS=\$ARG_${ARG_INDEX}_NARGS
    eval ARG_CONST=\$ARG_${ARG_INDEX}_CONST
    eval ARG_DEFAULT=\$ARG_${ARG_INDEX}_DEFAULT
    eval ARG_TYPE=\$ARG_${ARG_INDEX}_TYPE
    eval ARG_CHOICES=\$ARG_${ARG_INDEX}_CHOICES
    eval ARG_REQUIRED=\$ARG_${ARG_INDEX}_REQUIRED
    eval ARG_HELP=\$ARG_${ARG_INDEX}_HELP
    eval ARG_METAVAR=\$ARG_${ARG_INDEX}_METAVAR
    eval ARG_DEST=\$ARG_${ARG_INDEX}_DEST
}

parse_args ()
{
    while case $# in 0) false ;; esac
    do
        ARG=$1
        arg_find || return
        arg_get_settings
        shift
    done
}
