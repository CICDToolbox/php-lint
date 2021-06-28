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

INSTALL_COMMAND="composer require overtrue/phplint --dev"
EXIT_VALUE=0

# -------------------------------------------------------------------------------- #
# Install                                                                          #
# -------------------------------------------------------------------------------- #
# Install the required tooling.                                                    #
# -------------------------------------------------------------------------------- #

function install_prerequisites
{
    if errors=$( ${INSTALL_COMMAND} 2>&1 ); then
        success
    else
        fail "${errors}"
    fi
}

# -------------------------------------------------------------------------------- #
# Success                                                                          #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file was successful.             #
# -------------------------------------------------------------------------------- #

function success()
{
    printf ' [  %s%sOK%s  ] Excuting "%s"\n' "${bold}" "${success}" "${normal}" "${INSTALL_COMMAND}"
}

# -------------------------------------------------------------------------------- #
# Fail                                                                             #
# -------------------------------------------------------------------------------- #
# Show the user that the processing of a specific file failed and adjust the       #
# EXIT_VALUE to record this.                                                       #
# -------------------------------------------------------------------------------- #

function fail()
{
    local errors="${2:-}"

    printf ' [ %s%sFAIL%s ] Excuting "%s"\n' "${bold}" "${error}" "${normal}" "${INSTALL_COMMAND}"

    if [[ -n "${errors}" ]]; then
        echo "${errors}"
    fi

    EXIT_VALUE=1
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
}

# -------------------------------------------------------------------------------- #
# Main()                                                                           #
# -------------------------------------------------------------------------------- #
# This is the actual 'script' and the functions/sub routines are called in order.  #
# -------------------------------------------------------------------------------- #

setup
install_prerequisites

exit $EXIT_VALUE

# -------------------------------------------------------------------------------- #
# End of Script                                                                    #
# -------------------------------------------------------------------------------- #
# This is the end - nothing more to see here.                                      #
# -------------------------------------------------------------------------------- #
