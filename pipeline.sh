#!/usr/bin/env bash

# -------------------------------------------------------------------------------- #
# Description                                                                      #
# -------------------------------------------------------------------------------- #
# This script will locate and process all relevant files within the given git      #
# repository. Errors will be stored and a final exit status used to show if a      #
# failure occured during the processing.                                           #
# -------------------------------------------------------------------------------- #

# -------------------------------------------------------------------------------- #
# Configure the shell.                                                             #
# -------------------------------------------------------------------------------- #

set -Eeuo pipefail

# -------------------------------------------------------------------------------- #
# Global Variables                                                                 #
# -------------------------------------------------------------------------------- #
# TEST_COMMAND - The command to execute to perform the test.                       #
# FILE_TYPE_SEARCH_PATTERN - The pattern used to match file types.                 #
# FILE_NAME_SEARCH_PATTERN - The pattern used to match file names.                 #
# EXIT_VALUE - Used to store the script exit value - adjusted by the fail().       #
# -------------------------------------------------------------------------------- #

INSTALL_PACKAGE='php'
INSTALL_COMMAND="composer require overtrue/phplint --dev"

TEST_COMMAND='./vendor/bin/phplint'
FILE_TYPE_SEARCH_PATTERN='^PHP script'
FILE_NAME_SEARCH_PATTERN='\.php$'
EXIT_VALUE=0

# -------------------------------------------------------------------------------- #
# Install Prerequisites                                                            #
# -------------------------------------------------------------------------------- #
# Install the required tooling.                                                    #
# -------------------------------------------------------------------------------- #

function install_prerequisites
{
    draw_line
    center_text "${bold}Installing Prerequisites${normal}" $(( ${#bold} + ${#normal} ))
    draw_line

    if errors=$( ${INSTALL_COMMAND} 2>&1 ); then
        success "${INSTALL_COMMAND}"
    else
        fail "${INSTALL_COMMAND}" "${errors}" true
        draw_line
        exit $EXIT_VALUE                            # Bail out as we
    fi
}

# -------------------------------------------------------------------------------- #
# Install                                                                          #
# -------------------------------------------------------------------------------- #
# Install the required tooling.                                                    #
# -------------------------------------------------------------------------------- #

function get_version_information
{
    VERSION=$("${INSTALL_PACKAGE}" -r 'echo substr(phpversion(),0,3);');
    BANNER="Scanning all PHP scripts with ${INSTALL_PACKAGE} (version: ${VERSION})"
}

# -------------------------------------------------------------------------------- #
# Check                                                                            #
# -------------------------------------------------------------------------------- #
# Check a specific file.                                                           #
# -------------------------------------------------------------------------------- #

function check()
{
    local filename="$1"
    local errors

    file_count=$((file_count+1))

    if errors=$( ${TEST_COMMAND} "${filename}" 2>&1 ); then
        success "${filename}"
        ok_count=$((ok_count+1))
    else
        fail "${filename}" "${errors}"
        fail_count=$((fail_count+1))
    fi
}

# -------------------------------------------------------------------------------- #
# Scan Files                                                                       #
# -------------------------------------------------------------------------------- #
# Locate all of the relevant files within the repo and process compatible ones.    #
# -------------------------------------------------------------------------------- #

function scan_files()
{
    while IFS= read -r filename
    do
        if file -b "${filename}" | grep -qE "${FILE_TYPE_SEARCH_PATTERN}"; then
            check "${filename}"
        elif [[ "${filename}" =~ ${FILE_NAME_SEARCH_PATTERN} ]]; then
            check "${filename}"
        fi
    done < <(git ls-files | sort -zVd)
}

# -------------------------------------------------------------------------------- #
# Handle Parameters                                                                #
# -------------------------------------------------------------------------------- #
# Handle any parameters from the pipeline.                                         #
# -------------------------------------------------------------------------------- #

function handle_parameters
{
    if [[ -n "${SHOW_ERRORS-}" ]]; then
        if [[ "${SHOW_ERRORS}" != true ]]; then
            SHOW_ERRORS=false
        fi
    else
        SHOW_ERRORS=false
    fi

    if [[ -n "${REPORT_ONLY-}" ]]; then
        if [[ "${REPORT_ONLY}" != true ]]; then
            REPORT_ONLY=false
        fi
    else
        REPORT_ONLY=false
    fi

    if [[ "${REPORT_ONLY}" == true ]]; then
        center_text "WARNING: REPORT ONLY MODE"
        draw_line
    fi
}

# -------------------------------------------------------------------------------- #
# Success                                                                          #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file was successful.             #
# -------------------------------------------------------------------------------- #

function success()
{
    local message="${1:-}"

    if [[ -n "${message}" ]]; then
        printf ' [  %s%sOK%s  ] Successful: %s\n' "${bold}" "${success}" "${normal}" "${message}"
    fi
}

# -------------------------------------------------------------------------------- #
# Fail                                                                             #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file failed and adjust the       #
# EXIT_VALUE to record this.                                                       #
# -------------------------------------------------------------------------------- #

function fail()
{
    local message="${1:-}"
    local errors="${2:-}"
    local override="${3:-}"

    if [[ -n "${message}" ]]; then
        printf ' [ %s%sFAIL%s ] Failed: %s\n' "${bold}" "${error}" "${normal}" "${message}"
    fi

    if [[ "${SHOW_ERRORS}" == true ]] || [[ "${override}" == true ]] ; then
        if [[ -n "${errors}" ]]; then
            echo "${errors}"
        fi
    fi

    EXIT_VALUE=1
}

# -------------------------------------------------------------------------------- #
# Skip                                                                             #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file was skipped.                #
# -------------------------------------------------------------------------------- #

function skip()
{
    local message="${1:-}"

    file_count=$((file_count+1))
    if [[ -n "${message}" ]]; then
        printf ' [ %s%sSkip%s ] Skipping %s\n' "${bold}" "${skip}" "${normal}" "${message}"
    fi
}

# -------------------------------------------------------------------------------- #
# abs                                                                              #
# -------------------------------------------------------------------------------- #
# Return the absolute value for a given number.                                    #
# -------------------------------------------------------------------------------- #

function abs()
{
    (( $1 < 0 )) && echo "$(( $1 * -1 ))" || echo "$1"
}

# -------------------------------------------------------------------------------- #
# Center Text                                                                      #
# -------------------------------------------------------------------------------- #
# Center the given string on the screen. Part of the report generation.            #
# -------------------------------------------------------------------------------- #

function center_text()
{
    if [[ -n ${2-} ]]; then
        textsize=${2}
        extra=$(abs "$(( textsize - ${#1} ))")
    else
        textsize=${#1}
        extra=0
    fi

    span=$(( ((screen_width + textsize) / 2) + extra ))

    printf '%*s\n' "${span}" "$1"
}

# -------------------------------------------------------------------------------- #
# Draw Line                                                                        #
# -------------------------------------------------------------------------------- #
# Draw a line on the screen. Part of the report generation.                        #
# -------------------------------------------------------------------------------- #

function draw_line
{
    printf '%*s\n' "${screen_width}" '' | tr ' ' -
}

# -------------------------------------------------------------------------------- #
# Header                                                                           #
# -------------------------------------------------------------------------------- #
# Draw the report header on the screen. Part of the report generation.             #
# -------------------------------------------------------------------------------- #

function header
{
    draw_line
    center_text "${bold}${1}${normal}" $(( ${#bold} + ${#normal} ))
    draw_line
}

# -------------------------------------------------------------------------------- #
# Footer                                                                           #
# -------------------------------------------------------------------------------- #
# Draw the report footer on the screen. Part of the report generation.             #
# -------------------------------------------------------------------------------- #

function footer
{
    draw_line
    center_text "Total: ${file_count}, OK: ${ok_count}, Failed: ${fail_count}, Skipped: $skip_count"
    draw_line
}

# -------------------------------------------------------------------------------- #
# Setup                                                                            #
# -------------------------------------------------------------------------------- #
# Handle any custom setup that is required.                                        #
# -------------------------------------------------------------------------------- #

function setup
{
    export TERM=xterm

    screen_width=$(tput cols)
    bold="$(tput bold)"
    normal="$(tput sgr0)"
    error="$(tput setaf 1)"
    success="$(tput setaf 2)"
    skip="$(tput setaf 6)"

    file_count=0
    ok_count=0
    fail_count=0
    skip_count=0
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# This is the actual 'script' and the functions/sub routines are called in order.  #
# -------------------------------------------------------------------------------- #

setup
handle_parameters
install_prerequisites
get_version_information
header "${BANNER}"
scan_files
footer

if [[ "${REPORT_ONLY}" == true ]]; then
    EXIT_VALUE=0
fi

exit $EXIT_VALUE

# -------------------------------------------------------------------------------- #
# End of Script                                                                    #
# -------------------------------------------------------------------------------- #
# This is the end - nothing more to see here.                                      #
# -------------------------------------------------------------------------------- #
