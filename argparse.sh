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

ARG_SPECS_COUNT=0

add_argument ()
{
    ARG_LONG="$1"
    ARG_SHORT="${2:-}"
    ARG_TYPE="${3:-}"
    ARG_REQUIRED="${4:-}"
    ARG_HELP="${5:-}"

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
        ARG="$1"
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
    ARG_NAME="$1"
    ARG_DEFAULT_VALUE="${2:-}"
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
