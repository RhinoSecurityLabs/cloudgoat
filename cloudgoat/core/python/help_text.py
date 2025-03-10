CLOUDGOAT = """
CloudGoat - https://github.com/RhinoSecurityLabs/cloudgoat

Command info:

    config profile|whitelist|argcomplete [list]
    create <scenario>
    destroy <scenario>|all
    list <scenario>|all
    help <scenario>|<command>
"""

CONFIG = """
Command info:

    config profile
        Verify whether or not a config.yml file exists in the root
        directory and has a default profile name defined in it, then
        allow the user to specify a new default profile name to use.

    config whitelist [--auto]
        CloudGoat needs to know what IP addresses should be
        whitelisted when potentially-vulnerable resources are
        deployed, and these IPs are tracked as CIDR ranges in a
        whitelist.txt file in CloudGoat's base directory. You may
        create and fill in this file manually, or this command may
        be used to walk through the creation process. If a whitelist
        file already exists and contains valid IP addresses, it will
        display them.

        Using the "--auto" flag will tell CloudGoat to curl ifconfig.co
        to find your IP address and create or overwrite the whitelist
        file with it.

    config argcomplete
        Help for setting up argcomplete, enabling tab completion
        for CloudGoat commands and scenario names in bash 4+. Support
        for OSX and other shells is limited. For more information
        about configuring tab completion in bash with argcomplete,
        see the official documentation at https://github.com/kislyuk/argcomplete
        For those who cannot or do not wish to configure argcomplete,
        CloudGoat supports the use of directory paths as scenario names.
"""

CONFIG_ARGCOMPLETE = """
A guide to activating bash completion of cloudgoat.py commands and
scenario names. Support for OSX and other shells is limited. For
those who cannot or do not wish to configure argcomplete, CloudGoat
also supports the use of directory paths as scenario names.

Reference: https://github.com/kislyuk/argcomplete

    1. Install the argcomplete Python package using CloudGoat's
       requirements.txt file.
            $ pip3 install -r core/python/requirements.txt

    2. In bash, run the global Python argument completion script
       provided by the argcomplete package.
            $ activate-global-python-argcomplete

    3. Source the completion script at the location printed by the
       previous activation command, or restart your shell session.
            $ source </PATH/TO/THE/COMPLETION/SCRIPT>
"""

CREATE = """
Command info:

    create <scenario> [--profile <name>]
        Deploy a CloudGoat scenario. Uses a specific profile if
        provided; otherwise, a default may be loaded from a
        config.yml file, if one has been made.
"""

DESTROY = """
Command info:

    destroy <scenario>|all [--profile <name>]
        Tear down all resources deployed for a CloudGoat scenario.
        Uses a specific profile if provided; otherwise, a default
        may be loaded from a config.yml file, if one has been made.
"""

LIST = """
Command info:

    list <scenario>|all|deployed|undeployed
        Display information about all resources that have been
        deployed for a CloudGoat scenario, or for all deployed
        scenarios.
"""
