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
ARG_SPECS_COUNT=0

arg_lower ()
{
    ARG_STRING=
    while
        case $((${#ARG} > 0)) in
            0)
                false
            ;;
        esac
    do
        CHAR=${ARG%${ARG#?}}
        ARG=${ARG#?}
        case $CHAR in
            [$ARG_UPPERS])
                NUM=${ARG_UPPERS%%$CHAR*}
                NUM=$((${#NUM} + 1))
                COUNT=
                while
                    case $((${#COUNT} < $NUM)) in
                        0)
                            false
                        ;;
                    esac
                do
                    COUNT=$COUNT?
                done
                CHAR=${ARG_LOWERS%${ARG_LOWERS#$COUNT}}
                CHAR=${CHAR#${CHAR%?}}
            ;;
        esac
        ARG_STRING=${ARG_STRING:-}$CHAR
    done
    ARG=arg_$ARG_STRING
}

arg_upper ()
{
    ARG_STRING=
    while
        case $((${#ARG} > 0)) in
            0)
                false
            ;;
        esac
    do
        CHAR=${ARG%${ARG#?}}
        ARG=${ARG#?}
        case $CHAR in
            [$ARG_LOWERS])
                NUM=${ARG_LOWERS%%$CHAR*}
                NUM=$((${#NUM} + 1))
                COUNT=
                while
                    case $((${#COUNT} < $NUM)) in
                        0)
                            false
                        ;;
                    esac
                do
                    COUNT=$COUNT?
                done
                CHAR=${ARG_UPPERS%${ARG_UPPERS#$COUNT}}
                CHAR=${CHAR#${CHAR%?}}
            ;;
        esac
        ARG_STRING=${ARG_STRING:-}$CHAR
    done
    ARG=ARG_$ARG_STRING
}

arg_replace ()
{
########################################################################
    # replace sub string in string
    # $1 - pattern
    # $2 - replace
########################################################################
    while
        case "$ARG" in
            *$1*)
            ;;
            *)
                return
            ;;
        esac
    do
        ARG_STRING=
        while
            case "${ARG:+${1:-}}" in
                "")
                    false
                ;;
            esac
        do
            LEFT=${ARG%%$1*}
            case "$LEFT" in
                "$ARG")
                    break
                ;;
            esac
            ARG_STRING=$ARG_STRING$LEFT${2:-}
            ARG=${ARG#*$1}
        done
        ARG=$ARG_STRING$ARG
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
            exit 2
        ;;
        [!\{]*\} | [!\(]*\) | [!\[]*\])
            arg_get_parenthes "${1#${1%?}}"
            echo "SyntaxError: closing parenthesis '$ARG_CLOSING_PARENTS' does not match opening parenthesis '$ARG_OPENING_PARENTS'"
            exit 2
        ;;
        \{*[!\}]* | \(*[!\)]* | \[*[!\]]*)
            arg_get_parenthes "${1#${1%?}}"
            echo "SyntaxError: opening parenthesis '$ARG_OPENING_PARENTS' does not match closing parenthesis '$ARG_CLOSING_PARENTS'"
            exit 2
        ;;
    esac
}

arg_unquate ()
{
    case "$ARG" in
        [\"\']*)
            ARG=${ARG#?}
            ARG=${ARG%?}
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
        arg_check_unterminated_literals "$ARG"
        arg_unquate
        case "$ARG" in
            "")
                echo "ValueError: invalid option string '$ARG': must start with a character '$ARG_PREFIX_CHARS'"
                exit 2
            ;;
            [$ARG_PREFIX_CHARS]*)
                if $ARG_KEYWORD_IS_SET
                then
                    echo "SyntaxError: positional argument follows keyword argument"
                    exit 2
                elif $ARG_POSITION_ARG_IS_SET
                then
                    echo "ValueError: invalid option string '$ARG_POSITION_ARG': must start with a character '$ARG_PREFIX_CHARS'"
                    exit 2
                else
                    ARG_OPTION_IS_SET=true
                fi
            ;;
            *[!=]*=*)
                case "$ARG" in
                    [_$ARG_ALPHA]*)
                        arg_check_unterminated_literals "${ARG#*=}"
                        ARG_KEYWORD_IS_SET=true
                    ;;
                    *)
                        echo "SyntaxError: invalid keyword argument name '${ARG%%=*}'"
                        exit 2
                    ;;
                esac
            ;;
            *)
                if $ARG_KEYWORD_IS_SET
                then
                    echo "SyntaxError: positional argument follows keyword argument"
                    exit 2
                elif $ARG_POSITION_ARG_IS_SET
                then
                    echo "ValueError: invalid option string '$ARG': must start with a character '$ARG_PREFIX_CHARS'"
                    exit 2
                else
                    ARG_POSITION_ARG_IS_SET=true
                    ARG_POSITION_ARG=$ARG
                fi
            ;;
        esac
    done
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
    ARG_POSITION_ARG=true
    ARG_VALUE_IS_STRING=false
    ARG_CASE_STYLE='arg_lower'

    arg_validate_argument_sequence "$@"
    return 0

    for ARG
    do
        case "$ARG" in
            *=*)
                ARG_KEYWORD=${ARG%%=*}
                ARG_VALUE=${ARG#*=}
                case "$ARG_KEYWORD" in
                    prog | usage | description | epilog | parents | \
                    formatter_class | prefix_chars | fromfile_prefix_chars | \
                    argument_default | conflict_handler | \
                    add_help | allow_abbrev | exit_on_error)
                        ARG_POSITION_ARG=false
                        case "$ARG_VALUE" in
                            \"*[!\"] | \'*[!\'] | [!\']*\' | [!\"]*\")
                                echo "SyntaxError: unterminated string literal (detected at line 1)"
                                exit 2
                            ;;
                            *\`*)
                                echo "SyntaxError: invalid syntax"
                                exit 2
                            ;;
                            "")
                                echo "SyntaxError: expected argument value expression"
                                exit
                            ;;
                            \"*\" | \'*\')
                                ARG_VALUE_IS_STRING=true
                                ARG_VALUE=${ARG_VALUE#?}
                                ARG_VALUE=${ARG_VALUE%?}
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
                                        exit 2
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
                                            echo "NameError: name '$ARG_VALUE' is not defined. Did you mean: 'False'?"
                                            exit 2
                                        ;;
                                        0*[!0]*)
                                            echo "SyntaxError: leading zeros in decimal integer literals are not permitted; use an 0o prefix for octal integers"
                                            exit 2
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
                                        ARG_CASE_STYLE=arg_$ARG_VALUE
                                    ;;
                                    *)
                                        echo "NameError: name '$ARG_VALUE' is not defined."
                                        exit
                                    ;;
                                esac
                            ;;
                        esac
                    ;;
                    *)
                        false
                    ;;
                esac
            ;;
            *)
                ARG_VALUE=$ARG
                case "$ARG_VALUE" in
                    \"*[!\"] | \'*[!\'] | [!\']*\' | [!\"]*\")
                        echo "SyntaxError: unterminated string literal (detected at line 1)"
                        exit 2
                    ;;
                    \"*\" | \'*\')
                        ARG_VALUE_IS_STRING=true
                        ARG_VALUE=${ARG_VALUE#?}
                        ARG_VALUE=${ARG_VALUE%?}
                    ;;
                esac
                value_is_string || ARG_VALUE=
                false
            ;;
        esac || {
            $ARG_POSITION_ARG && {
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
                    exit 2
                fi
            } || {
                echo "SyntaxError: positional argument follows keyword argument"
                exit 2
            }
        }
    done
    ARG_PARENTS=${ARG_PARENTS:-}
    ARG_FORMATTER_CLASS=${ARG_FORMATTER_CLASS:-argparse.HelpFormatter}
    ARG_ADD_HELP=${ARG_ADD_HELP:-}
    ARG_ALLOW_ABBREV=${ARG_ALLOW_ABBREV:-}
    ARG_EXIT_ON_ERROR=${ARG_EXIT_ON_ERROR:-}
}

arg_get_positional_kwargs ()
{
    :
}

arg_get_optional_kwargs ()
{
    ARG_SHORT_OPTIONS=
    ARG_LONG_OPTIONS=
    ARG_COUT=0
    for ARG
    do
        ARG_COUT=$((ARG_COUT + 1))
        case "$ARG" in
            [$ARG_PREFIX_CHARS][!$ARG_PREFIX_CHARS]*)
                ARG_SHORT_OPTIONS=$ARG_SHORT_OPTIONS,$ARG_COUT
            ;;
            [$ARG_PREFIX_CHARS][$ARG_PREFIX_CHARS]?*)
                ARG_LONG_OPTIONS=$ARG_LONG_OPTIONS,$ARG_COUT
            ;;
            "")
                echo "ValueError: invalid option string '$ARG': must start with a character '$ARG_PREFIX_CHARS'"
                exit 2
            ;;
        esac
    done
    ARG_SHORT_OPTIONS=${ARG_SHORT_OPTIONS#,}
    ARG_LONG_OPTIONS=${ARG_LONG_OPTIONS#,}

    case $ARG_DEST in
        "")
            ARG_DEST=${ARG_LONG_OPTIONS%%,*}
            ARG_DEST=${ARG_DEST:-${ARG_SHORT_OPTIONS%%,*}}
        ;;
    esac
}

add_argument ()
{
    ARG_POSITION_ARG=true

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

    ARG_VALUE=

    # add_argument "-c" "--config" "dest=var"
    # add_argument "-c" "--config" "dest='var'"
    # add_argument "-c" "--config" "dest=''"
    # add_argument "-c" "--config" "dest="

    # add_argument "file" "default="
    # add_argument "file" "default=''"
    # add_argument "file" "'default="config.cfg"'"

    # add_argument "" "'default="config.cfg"'"

    arg_get_optional_kwargs "$@"

########################################################################

    for ARG
    do
        case "$ARG" in
            "")
                echo "дай сообщение"
                exit 2
            ;;
            [$ARG_PREFIX_CHARS]?*)
                case "$ARG_PREFIX_CHARS" in
                    "$ARG_POSIX_PREFIX_CHARS")
                        case "$ARG" in
                        esac
                    ;;
                    *)
                    ;;
                esac
                $ARG_KEYWORD && {
                    echo "дай сообщение"
                    exit 2
                } || {
                    ARG=${ARG#${ARG%%[!$ARG_PREFIX_CHARS]*}}
                    arg_replace "[!_$ARG_ALNUM]" '_'
                    arg_replace '__' '_'
                    $ARG_CASE_STYLE
                    eval $ARG=
                    ARG_LONG_DEST=${ARG_LONG_DEST:-$ARG}
                }
            ;;
            *[!=]*=\"*\" | *[!=]*=\'*\')
                ARG_VALUE=${ARG#*=?}
                ARG_VALUE=${ARG_VALUE%?}
                ARG=${ARG%${ARG#*=}}=${ARG_VALUE:-None}
            ;;
            *[!=]*=)
                ARG_VALUE=None
            ;;
            *[!=]*=*)
                ARG_VALUE=${ARG#*=}
            ;;
        esac
        case "$ARG" in
            [$ARG_PREFIX_CHARS][$ARG_PREFIX_CHARS][_$ARG_ALNUM]*)
                ARG=${ARG#??}
                arg_replace '-' '_'
                $ARG_CASE_STYLE
                eval $ARG=
                ARG_LONG_DEST=${ARG_LONG_DEST:-$ARG}
            ;;
            [$ARG_PREFIX_CHARS][$ARG_ALNUM])
                ARG=${ARG#?}
                $ARG_CASE_STYLE
                eval $ARG=
                ARG_SHORT_DEST=${ARG_SHORT_DEST:-$ARG}
            ;;
            *)
                case "${ARG_LONG_DEST:-$ARG_SHORT_DEST}" in
                    "")
                        echo "дай сообщение"
                        exit 2
                    ;;
                esac
                case "${ARG%%=*}" in
                    dest)
                        case "$ARG_VALUE" in
                            *[!_$ARG_ALNUM]* | [!_$ARG_ALPHA]*)
                                false
                            ;;
                            None)
                                ARG_DEST=${ARG_LONG_DEST:-$ARG_SHORT_DEST}
                            ;;
                            *)
                                ARG_DEST=$ARG_VALUE
                            ;;
                        esac
                    ;;
                esac
            ;;
        esac
    done
    ARG_DEST=${ARG_DEST:-${ARG_LONG_DEST:-$ARG_SHORT_DEST}}


    ARG_LONG=$1
    ARG_SHORT=${2:-}
    ARG_TYPE=${3:-}
    ARG_REQUIRED=${4:-}
    ARG_HELP=${5:-}

    ARG_SPECS_COUNT=$((ARG_SPECS_COUNT + 1))

    eval "ARG_SPEC_${ARG_SPECS_COUNT}_LONG='$ARG_LONG'"
    eval "ARG_SPEC_${ARG_SPECS_COUNT}_SHORT='$ARG_SHORT'"
    eval "ARG_SPEC_${ARG_SPECS_COUNT}_TYPE='$ARG_TYPE'"
    eval "ARG_SPEC_${ARG_SPECS_COUNT}_REQUIRED='$ARG_REQUIRED'"
    eval "ARG_SPEC_${ARG_SPECS_COUNT}_HELP='$ARG_HELP'"
    eval "ARG_SPEC_${ARG_SPECS_COUNT}_VALUE="
    eval "ARG_SPEC_${ARG_SPECS_COUNT}_SET=false"
}

arg_cmp_count ()
{
    case $((i <= ARG_SPECS_COUNT)) in
        0)
            false
        ;;
    esac
}

parse_args ()
{
    ARG_VALUES=""
    while case $# in 0) false ;; esac
    do
        ARG=$1
        ARG_MATCHED=false
        i=1
        while arg_cmp_count
        do
            eval     "ARG_LONG=\$ARG_SPEC_${i}_LONG"
            eval    "ARG_SHORT=\$ARG_SPEC_${i}_SHORT"
            eval     "ARG_TYPE=\$ARG_SPEC_${i}_TYPE"
            eval "ARG_REQUIRED=\$ARG_SPEC_${i}_REQUIRED"

            case "$ARG_SHORT" in
                ?*)
                    case "-$ARG_SHORT" in
                        "$ARG")
                            ARG_MATCHED=true
                            shift
                            ARG_VALUE=${1:-}
                            eval "ARG_SPEC_${i}_VALUE=\${ARG_VALUE:-}"
                            eval "ARG_SPEC_${i}_SET=true"
                            shift
                            break
                        ;;
                    esac
                ;;
            esac

            case "$ARG" in
                "--$ARG_LONG" | "--$ARG_LONG="*)
                    ARG_MATCHED=true
                    case "$ARG" in
                        *=*)
                            ARG_VALUE=${ARG#*=}
                        ;;
                        *)
                            shift
                            ARG_VALUE=${1:-}
                        ;;
                    esac
                    eval "ARG_SPEC_${i}_VALUE=\${ARG_VALUE:-}"
                    eval "ARG_SPEC_${i}_SET=true"
                    shift
                    break
                ;;
            esac

            i=$((i + 1))
        done

        $ARG_MATCHED || {
            echo "Unknown option: $ARG" >&2
            return 1
        }
    done

    i=1
    while arg_cmp_count
    do
        eval     "ARG_LONG=\$ARG_SPEC_${i}_LONG"
        eval    "ARG_SHORT=\$ARG_SPEC_${i}_SHORT"
        eval "ARG_REQUIRED=\$ARG_SPEC_${i}_REQUIRED"
        eval      "ARG_SET=\$ARG_SPEC_${i}_SET"

        if $ARG_REQUIRED
        then
            $ARG_SET || {
                case "$ARG_LONG" in
                    ?*)
                        echo "Error: --$ARG_LONG is required" >&2
                    ;;
                    *)
                        echo "Error: -$ARG_SHORT is required" >&2
                esac
                return 1
            }
        fi
        i=$((i + 1))
    done
    return 0
}

arg_get ()
{
    ARG_NAME=$1
    ARG_DEFAULT_VALUE=${2:-}
    i=1
    while arg_cmp_count
    do
        eval     "ARG_LONG=\$ARG_SPEC_${i}_LONG"
        eval    "ARG_SHORT=\$ARG_SPEC_${i}_SHORT"
        eval    "ARG_VALUE=\$ARG_SPEC_${i}_VALUE"
        eval      "ARG_SET=\$ARG_SPEC_${i}_SET"

        case "$ARG_NAME" in
            "$ARG_LONG" | "$ARG_SHORT")
                $ARG_SET || break
                echo "$ARG_VALUE"
                return 0
            ;;
        esac
        i=$((i + 1))
    done
    echo "$ARG_DEFAULT_VALUE"
}
