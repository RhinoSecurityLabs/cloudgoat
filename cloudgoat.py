#!/usr/bin/env python3
# PYTHON_ARGCOMPLETE_OK
import argparse
import os
import re
import subprocess
import sys


def command_completer(prefix, parsed_args, **kwargs):
    BASE_COMMANDS = ["config", "create", "destroy", "list", "help"]

    if not parsed_args.command:
        return BASE_COMMANDS

    base_dir = os.path.dirname(os.path.abspath(__file__))
    scenarios_dir = os.path.join(base_dir, "scenarios")

    scenario_dir_names = list()

    for filesystem_object in os.scandir(scenarios_dir):
        if filesystem_object.is_dir():
            scenario_dir_names.append(os.path.basename(filesystem_object.path))

    if len(parsed_args.command) == 1:
        if parsed_args.command[0] == "config":
            return ["argcomplete", "profile", "whitelist"]

        elif parsed_args.command[0] == "create":
            return scenario_dir_names

        elif parsed_args.command[0] == "destroy":
            return scenario_dir_names + ["all"]

        elif parsed_args.command[0] == "list":
            return scenario_dir_names + ["all", "deployed", "undeployed"]

        elif parsed_args.command[0] == "help":
            return scenario_dir_names + BASE_COMMANDS

    elif len(parsed_args.command) == 2:
        if parsed_args.command[0] == "config" and parsed_args.command[1] == "whitelist":
            return ["--auto"]

        elif parsed_args.command[0] in ("create", "destroy"):
            return ["--profile"]

    return [None]


def parse_args():
    parser = argparse.ArgumentParser(add_help=False, usage="cloudgoat.py help")

    parser.add_argument(
        "command", nargs="+", action="store"
    ).completer = command_completer
    parser.add_argument(
        "-a", "--auto", required=False, action="store_true", help=argparse.SUPPRESS
    )
    parser.add_argument(
        "-p", "--profile", required=False, action="store", help=argparse.SUPPRESS
    )

    try:
        import argcomplete

        argcomplete.autocomplete(parser)
    except ImportError:
        pass

    return parser.parse_args()


if __name__ == "__main__":
    # This should come before version checking because argcomplete suppresses
    # all non-completion output and exits early.
    args = parse_args()

    if sys.version_info[0] < 3 or (
        sys.version_info[0] >= 3 and sys.version_info[1] < 6
    ):
        print("CloudGoat requires Python 3.6+ to run.")
        sys.exit(1)

    try:
        terraform_version_process = subprocess.Popen(
            ["terraform", "--version"], stdout=subprocess.PIPE
        )
    except FileNotFoundError:
        print("Terraform not found. Please install Terraform before using CloudGoat.")
        sys.exit(1)

    terraform_version_process.wait()

    version_number = re.findall(
        r"^Terraform\ v(\d+\.\d+)\.\d+\s",
        terraform_version_process.stdout.read().decode("utf-8"),
    )

    if not version_number:
        print("Terraform not found. Please install Terraform before using CloudGoat.")
        sys.exit(1)

    major_version, minor_version = version_number[0].split(".")
    if int(major_version) == 0 and int(minor_version) < 11:
        print(
            "Your version of Terraform is v{}. CloudGoat requires Terraform v0.12 or"
            " higher to run.".format(version_number[0])
        )

    try:
        from core.python.commands import CloudGoat

        base_dir = os.path.dirname(os.path.abspath(__file__))
        cloudgoat = CloudGoat(base_dir)
        cloudgoat.parse_and_execute_command(args)
    except KeyboardInterrupt:
        print("\nBye!")
