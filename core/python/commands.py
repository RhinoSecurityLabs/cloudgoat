import os
import re
import shutil
import subprocess

from core.python import help_text
from core.python.python_terraform import IsNotFlagged
from core.python.utils import PatchedTerraform as Terraform
from core.python.utils import (
    check_own_ip_address,
    create_dir_if_nonexistent,
    create_or_update_yaml_file,
    dirs_at_location,
    display_terraform_step_error,
    extract_cgid_from_dir_name,
    find_scenario_dir,
    find_scenario_instance_dir,
    generate_cgid,
    ip_address_or_range_is_valid,
    load_and_validate_whitelist,
    load_data_from_yaml_file,
    normalize_scenario_name,
)


class CloudGoat:
    def __init__(self, base_dir):
        self.base_dir = base_dir
        self.config_path = os.path.join(self.base_dir, "config.yml")
        self.scenarios_dir = os.path.join(base_dir, "scenarios")
        self.scenario_names = dirs_at_location(self.scenarios_dir, names_only=True)
        self.whitelist_path = os.path.join(base_dir, "whitelist.txt")

        self.aws_region = "us-east-1"
        self.cloudgoat_commands = ["config", "create", "destroy", "list", "help"]
        self.non_scenario_instance_dirs = [
            ".git",
            "__pycache__",
            "core",
            "scenarios",
            "trash",
        ]

    def parse_and_execute_command(self, parsed_args):
        command = parsed_args.command
        profile = parsed_args.profile

        # Display help text. Putting this first makes validation simpler.
        if command[0] == "help" or (len(command) >= 2 and command[-1] == "help"):
            return self.display_cloudgoat_help(command)

        # Validation
        if len(command) == 1:
            if command[0] == "config":
                print(
                    f'The {command[0]} currently must be used with "whitelist",'
                    f' "profile", or "help".'
                )
                return
            elif command[0] == "create":
                print(
                    f"The {command[0]} command must be used with either a scenario name"
                    f' or "help".'
                    f"\nAll scenarios:\n    " + "\n    ".join(self.scenario_names)
                )
                return
            elif command[0] == "destroy":
                print(
                    f"The {command[0]} command must be used with a scenario name,"
                    f' "all", or "help".'
                    f"\nAll scenarios:\n    " + "\n    ".join(self.scenario_names)
                )
                return
            elif command[0] == "list":
                print(
                    f"The {command[0]} command must be used with a scenario name,"
                    f' "all", "deployed", "undeployed", or "help".'
                    f"\nAll scenarios:\n    " + "\n    ".join(self.scenario_names)
                )
                return

        if command[0] in ("create", "destroy", "list"):
            if command[1].lower() in self.cloudgoat_commands:
                print(f"CloudGoat scenarios cannot be named after CloudGoat commands.")
                return
            if command[1] in self.non_scenario_instance_dirs:
                print(
                    f'The name "{command[1]}" is reserved for CloudGoat and may not be'
                    f" used with the {command[0]} command."
                )
                return

        if command[0] in ("create", "destroy"):
            if not profile:
                if os.path.exists(self.config_path):
                    profile = load_data_from_yaml_file(
                        self.config_path, "default-profile"
                    )
                if not profile:
                    print(
                        f"The {command[0]} command requires the use of the --profile"
                        f" flag, or a default profile defined in the config.yml file"
                        f' (try "config profile").'
                    )
                    return
                else:
                    print(f'Using default profile "{profile}" from config.yml...')

        # Execution
        if command[0] == "config":
            if command[1] == "whitelist" or command[1] == "whitelist.txt":
                return self.configure_or_check_whitelist(
                    auto=parsed_args.auto, print_values=True
                )
            elif command[1] == "profile":
                return self.configure_or_check_default_profile()
            elif command[1] == "argcomplete":
                return self.configure_argcomplete()

        elif command[0] == "create":
            return self.create_scenario(command[1], profile)

        elif command[0] == "destroy":
            if command[1] == "all":
                return self.destroy_all_scenarios(profile)
            else:
                return self.destroy_scenario(command[1], profile)

        elif command[0] == "list":
            if command[1] == "all":
                return self.list_all_scenarios()
            elif command[1] == "deployed":
                return self.list_deployed_scenario_instances()
            elif command[1] == "undeployed":
                return self.list_undeployed_scenarios()
            else:
                return self.list_scenario_instance(command[1])

        print(f'Unrecognized command. Try "cloudgoat.py help"')
        return

    def display_cloudgoat_help(self, command):
        if not command or len(command) == 1:
            return print(help_text.CLOUDGOAT)

        # Makes "help foo" equivalent to "foo help".
        command.remove("help")

        if command[0] == "config":
            if len(command) > 1 and command[1] == "argcomplete":
                return print(help_text.CONFIG_ARGCOMPLETE)
            else:
                return print(help_text.CONFIG)
        elif command[0] == "create":
            return print(help_text.CREATE)
        elif command[0] == "destroy":
            return print(help_text.DESTROY)
        elif command[0] == "list":
            return print(help_text.LIST)
        elif command[0] == "help":
            if all([word == "help" for word in command]):
                joined_help_texts = " ".join(["help text for" for word in command])
                return print(f"Displays {joined_help_texts} CloudGoat.")
        else:
            scenario_name = normalize_scenario_name(command[0])
            scenario_dir_path = find_scenario_dir(self.scenarios_dir, scenario_name)
            if scenario_dir_path:
                scenario_help_text = load_data_from_yaml_file(
                    os.path.join(scenario_dir_path, "manifest.yml"), "help"
                ).strip()
                return print(
                    f"[cloudgoat scenario: {scenario_name}]\n{scenario_help_text}"
                )

        return print(
            f'Unrecognized command or scenario name. Try "cloudgoat.py help" or'
            f' "cloudgoat.py list all"'
        )

    def configure_argcomplete(self):
        print(help_text.CONFIG_ARGCOMPLETE)

    def configure_or_check_default_profile(self):
        if not os.path.exists(self.config_path):
            create_config_file_now = input(
                f"No configuration file was found at {self.config_path}"
                f"\nWould you like to create this file with a default profile name now?"
                f" [y/n]: "
            )
            default_profile = None
        else:
            print(f"A configuration file exists at {self.config_path}")
            default_profile = load_data_from_yaml_file(
                self.config_path, "default-profile"
            )
            if default_profile:
                print(f'It specifies a default profile name of "{default_profile}".')
            else:
                print(f"It does not contain a default profile name.")
            create_config_file_now = input(
                f"Would you like to specify a new default profile name for the"
                f" configuration file now? [y/n]: "
            )

        if not create_config_file_now.strip().lower().startswith("y"):
            return

        while True:
            default_profile = input(
                f"Enter the name of your default AWS profile: "
            ).strip()

            if default_profile:
                create_or_update_yaml_file(
                    self.config_path, {"default-profile": default_profile}
                )
                print(f'A default profile name of "{default_profile}" has been saved.')
                break
            else:
                print(f"Enter your default profile's name, or hit ctrl-c to exit.")
                continue

        return

    def configure_or_check_whitelist(self, auto=False, print_values=False):
        if auto:
            if os.path.exists(self.whitelist_path):
                confirm_auto_configure = input(
                    f"A whitelist.txt file was found at {self.whitelist_path}"
                    f"\nCloudGoat can automatically make a network request, using curl,"
                    f" to ifconfig.co to find your IP address, and then overwrite the"
                    f" contents of the whitelist file with the result."
                    f"\nWould you like to continue? [y/n]: "
                )
            else:
                confirm_auto_configure = input(
                    f"No whitelist.txt file was found at {self.whitelist_path}"
                    f"\nCloudGoat can automatically make a network request, using curl,"
                    f" to ifconfig.co to find your IP address, and then create the"
                    f" whitelist file with the result."
                    f"\nWould you like to continue? [y/n]: "
                )

            if confirm_auto_configure.strip().lower().startswith("y"):
                ip_address = check_own_ip_address()

                if not ip_address:
                    print(
                        f"\n[cloudgoat] Unknown error: Unable to retrieve IP address.\n"
                    )
                    return None

                if not re.findall(r".*\/(\d+)", ip_address):
                    ip_address = ip_address.split("/")[0] + "/32"

                if ip_address_or_range_is_valid(ip_address):
                    with open(self.whitelist_path, "w") as whitelist_file:
                        whitelist_file.write(ip_address)

                    print(f"\nwhitelist.txt created with IP address {ip_address}")

                    return load_and_validate_whitelist(self.whitelist_path)

                else:
                    print(
                        f"\n[cloudgoat] Unknown error: Did not receive a valid IP"
                        f" address. Received this instead:\n{ip_address}\n"
                    )
                    return None

            else:
                print(f"Automatic whitelist.txt configuration cancelled.")
                return None

        elif not os.path.exists(self.whitelist_path):
            create_whitelist_now = input(
                f"No IP address whitelist was found at {self.whitelist_path}"
                f"\nCloudGoat requires a whitelist.txt file to exist before the"
                f' "create" command can be used.'
                f"\nWould you like to make one now? [y/n]: "
            )

            if not create_whitelist_now.strip().lower().startswith("y"):
                return None

            while True:
                ip_address = input(
                    f"\nEnter a valid IP address, optionally with CIDR notation: "
                ).strip()

                if not re.findall(r".*\/(\d+)", ip_address):
                    ip_address = ip_address.split("/")[0] + "/32"

                if ip_address_or_range_is_valid(ip_address):
                    with open(self.whitelist_path, "w") as whitelist_file:
                        whitelist_file.write(ip_address)

                    print(f"\nwhitelist.txt created with IP address {ip_address}")

                    return load_and_validate_whitelist(self.whitelist_path)

                else:
                    print(f"\nInvalid IP address.")
                    continue

        else:
            print(f"Loading whitelist.txt...")
            whitelist = load_and_validate_whitelist(self.whitelist_path)
            if whitelist:
                print(
                    f"A whitelist.txt file was found that contains at least one valid"
                    f" IP address or range."
                )
                if print_values:
                    print(f"Whitelisted IP addresses:\n    " + "\n    ".join(whitelist))
            return whitelist

    def create_scenario(self, scenario_name_or_path, profile):
        scenario_name = normalize_scenario_name(scenario_name_or_path)
        scenario_dir = os.path.join(self.scenarios_dir, scenario_name)

        if not scenario_dir or not scenario_name or not os.path.exists(scenario_dir):
            if not scenario_name:
                return print(
                    f"No recognized scenario name was entered. Did you mean one of"
                    f" these?\n    " + f"\n    ".join(self.scenario_names)
                )
            else:
                return print(
                    f"No scenario named {scenario_name} exists in the scenarios"
                    f" directory. Did you mean one of these?"
                    f"\n    " + f"\n    ".join(self.scenario_names)
                )

        if not os.path.exists(self.whitelist_path):
            cg_whitelist = self.configure_or_check_whitelist(auto=True)
        else:
            cg_whitelist = self.configure_or_check_whitelist()

        if not cg_whitelist:
            print(
                f"A valid whitelist.txt file must exist in the {self.base_dir}"
                f' directory before "create" may be used.'
            )
            return

        # Create a scenario-instance folder in the project root directory.
        # This command should fail with an explanatory error message if a
        # scenario-instance of the same root name (i.e. without the CGID) already
        # exists.
        extant_dir = find_scenario_instance_dir(self.base_dir, scenario_name)
        if extant_dir is not None:
            destroy_and_recreate = input(
                f"You already have an instance of {scenario_name} deployed."
                f" Do you want to destroy and recreate it (y) or cancel (n)? [y/n]: "
            )

            if destroy_and_recreate.strip().lower() == "y":
                self.destroy_scenario(scenario_name, profile, confirmed=True)
            else:
                instance_name = os.path.basename(extant_dir)
                print(f"\nCancelled destruction and recreation of {instance_name}.\n")
                return

        cgid = generate_cgid()
        scenario_instance_dir_path = os.path.join(
            self.base_dir, f"{scenario_name}_{cgid}"
        )

        # Copy all the terraform files from the "/scenarios/scenario-name" folder
        # to the scenario-instance folder.
        source_dir_contents = os.path.join(scenario_dir, ".")
        shutil.copytree(source_dir_contents, scenario_instance_dir_path)

        if os.path.exists(os.path.join(scenario_instance_dir_path, "start.sh")):
            print(f"\nNow running {scenario_name}'s start.sh...")
            start_script_process = subprocess.Popen(
                ["sh", "start.sh"], cwd=scenario_instance_dir_path
            )
            start_script_process.wait()
        else:
            pass

        terraform = Terraform(
            working_dir=os.path.join(scenario_instance_dir_path, "terraform")
        )

        init_retcode, init_stdout, init_stderr = terraform.init(
            capture_output=False, no_color=IsNotFlagged
        )
        if init_retcode != 0:
            display_terraform_step_error(
                "terraform init", init_retcode, init_stdout, init_stderr
            )
            return
        else:
            print(f"\n[cloudgoat] terraform init completed with no error code.")

        plan_retcode, plan_stdout, plan_stderr = terraform.plan(
            capture_output=False,
            var={
                "cgid": cgid,
                "cg_whitelist": cg_whitelist,
                "profile": profile,
                "region": self.aws_region,
            },
            no_color=IsNotFlagged,
        )
        # For some reason, `python-terraform`'s `terraform init` returns "2" even
        # when it appears to succeed. For that reason, it will temporarily permit
        # retcode 2.
        if plan_retcode not in (0, 2):
            display_terraform_step_error(
                "terraform plan", plan_retcode, plan_stdout, plan_stderr
            )
            return
        else:
            print(f"\n[cloudgoat] terraform plan completed with no error code.")

        apply_retcode, apply_stdout, apply_stderr = terraform.apply(
            capture_output=False,
            var={
                "cgid": cgid,
                "cg_whitelist": cg_whitelist,
                "profile": profile,
                "region": self.aws_region,
            },
            skip_plan=True,
            no_color=IsNotFlagged,
        )
        if apply_retcode != 0:
            display_terraform_step_error(
                "terraform apply", apply_retcode, apply_stdout, apply_stderr
            )
            return
        else:
            print(f"\n[cloudgoat] terraform apply completed with no error code.")

        # python-terraform uses the '-json' flag by default.
        # The documentation for `output` suggests using output_cmd to receive the
        # library's standard threeple return value.
        # Can't use capture_output here because we need to write stdout to a file.
        output_retcode, output_stdout, output_stderr = terraform.output_cmd()

        if output_retcode != 0:
            display_terraform_step_error(
                "terraform output", output_retcode, output_stdout, output_stderr
            )
            return
        else:
            print(f"\n[cloudgoat] terraform output completed with no error code.")

        # Within this output will be values that begin with "cloudgoat_output".
        # Each line of console output which contains this tag will be written into
        # a text file named "start.txt" in the scenario-instance folder.
        start_file_path = os.path.join(scenario_instance_dir_path, "start.txt")
        with open(start_file_path, "w") as start_file:
            for line in output_stdout.split("\n"):
                if line.count("cloudgoat_output") != 0:
                    start_file.write(line + "\n")

        print(f"\n[cloudgoat] Output file written to:\n\n    {start_file_path}\n")

    def destroy_all_scenarios(self, profile):
        # Information gathering.
        extant_scenario_instance_names_and_paths = list()
        for scenario_name in self.scenario_names:
            scenario_instance_dir_path = find_scenario_instance_dir(
                self.base_dir, scenario_name
            )

            if scenario_instance_dir_path is None:
                continue
            else:
                extant_scenario_instance_names_and_paths.append(
                    (scenario_name, scenario_instance_dir_path)
                )
                print(f"Scenario instance for {scenario_name} found.")

        if not extant_scenario_instance_names_and_paths:
            print(f"\n  No scenario instance directories exist.\n")
            return
        else:
            print(
                f"\n  {len(extant_scenario_instance_names_and_paths)} scenario"
                f" instance directories found."
            )

        # Iteration.
        success_count, failure_count, skipped_count = 0, 0, 0

        for scenario_name, instance_path in extant_scenario_instance_names_and_paths:
            print(f"\n--------------------------------\n")

            # Confirmation.
            delete_permission = input(f'Destroy "{scenario_name}"? [y/n]: ')

            if not delete_permission.strip()[0].lower() == "y":
                skipped_count += 1
                print(f"\nSkipped destruction of {scenario_name}.\n")
                continue

            # Terraform execution.
            terraform_directory = os.path.join(instance_path, "terraform")

            if os.path.exists(os.path.join(terraform_directory, "terraform.tfstate")):
                terraform = Terraform(working_dir=terraform_directory)

                cgid = extract_cgid_from_dir_name(os.path.basename(instance_path))

                destroy_retcode, destroy_stdout, destroy_stderr = terraform.destroy(
                    capture_output=False,
                    var={
                        "cgid": cgid,
                        "cg_whitelist": list(),
                        "profile": profile,
                        "region": self.aws_region,
                    },
                    no_color=IsNotFlagged,
                )
                if destroy_retcode != 0:
                    display_terraform_step_error(
                        "terraform destroy",
                        destroy_retcode,
                        destroy_stdout,
                        destroy_stderr,
                    )
                    failure_count += 1
                    # Subsequent destroys should not be skipped when one fails.
                    continue
                else:
                    print(
                        f"\n[cloudgoat] terraform destroy completed with no error code."
                    )
            else:
                print(
                    f"\nNo terraform.tfstate file was found in the scenario instance's"
                    f' terraform directory, so "terraform destroy" will not be run.'
                )

            # Scenario instance directory trashing.
            trash_dir = create_dir_if_nonexistent(self.base_dir, "trash")

            trashed_instance_path = os.path.join(
                trash_dir, os.path.basename(instance_path)
            )

            shutil.move(instance_path, trashed_instance_path)

            success_count += 1

            print(
                f"\nSuccessfully destroyed {scenario_name}."
                f"\nScenario instance files have been moved to {trashed_instance_path}"
            )

        # Iteration summary.
        print(
            f"\nDestruction complete."
            f"\n    {success_count} scenarios successfully destroyed"
            f"\n    {failure_count} destroys failed"
            f"\n    {skipped_count} skipped\n"
        )

        return

    def destroy_scenario(self, scenario_name_or_path, profile, confirmed=False):
        # Information gathering.
        scenario_name = normalize_scenario_name(scenario_name_or_path)
        scenario_instance_dir_path = find_scenario_instance_dir(
            self.base_dir, scenario_name
        )

        if scenario_instance_dir_path is None:
            print(
                f'[cloudgoat] Error: No scenario instance for "{scenario_name}" found.'
                f" Try: cloudgoat.py list deployed"
            )
            return

        instance_name = os.path.basename(scenario_instance_dir_path)

        # Confirmation.
        if not confirmed:
            delete_permission = input(f'Destroy "{instance_name}"? [y/n]: ').strip()
            if not delete_permission or not delete_permission[0].lower() == "y":
                print(f"\nCancelled destruction of {instance_name}.\n")
                return

        # Terraform execution.
        terraform_directory = os.path.join(scenario_instance_dir_path, "terraform")

        if os.path.exists(os.path.join(terraform_directory, "terraform.tfstate")):
            terraform = Terraform(working_dir=terraform_directory)

            cgid = extract_cgid_from_dir_name(
                os.path.basename(scenario_instance_dir_path)
            )

            destroy_retcode, destroy_stdout, destroy_stderr = terraform.destroy(
                capture_output=False,
                var={
                    "cgid": cgid,
                    "cg_whitelist": list(),
                    "profile": profile,
                    "region": self.aws_region,
                },
                no_color=IsNotFlagged,
            )
            if destroy_retcode != 0:
                display_terraform_step_error(
                    "terraform destroy", destroy_retcode, destroy_stdout, destroy_stderr
                )
                return
            else:
                print("\n[cloudgoat] terraform destroy completed with no error code.")
        else:
            print(
                f"\nNo terraform.tfstate file was found in the scenario instance's"
                f' terraform directory, so "terraform destroy" will not be run.'
            )

        # Scenario instance directory trashing.
        trash_dir = create_dir_if_nonexistent(self.base_dir, "trash")

        trashed_instance_path = os.path.join(
            trash_dir, os.path.basename(scenario_instance_dir_path)
        )

        shutil.move(scenario_instance_dir_path, trashed_instance_path)

        print(
            f"\nSuccessfully destroyed {instance_name}."
            f"\nScenario instance files have been moved to {trashed_instance_path}"
        )

        return

    def list_all_scenarios(self):
        undeployed_scenarios = list()
        deployed_scenario_instance_paths = list()

        for scenario_name in self.scenario_names:
            scenario_instance_dir_path = find_scenario_instance_dir(
                self.base_dir, scenario_name
            )
            if scenario_instance_dir_path:
                deployed_scenario_instance_paths.append(scenario_instance_dir_path)

            else:
                undeployed_scenarios.append(scenario_name)

        print(
            f"\n  Deployed scenario instances: {len(deployed_scenario_instance_paths)}"
        )

        for scenario_instance_dir_path in deployed_scenario_instance_paths:
            directory_name = os.path.basename(scenario_instance_dir_path)
            scenario_name, cgid = directory_name.split("_cgid")
            print(
                f"\n    {scenario_name}"
                f"\n        CGID: {'cgid' + cgid}"
                f"\n        Path: {scenario_instance_dir_path}"
            )

        print(f"\n  Undeployed scenarios: {len(undeployed_scenarios)}")

        # Visual spacing.
        if undeployed_scenarios:
            print(f"")

        for scenario_name in undeployed_scenarios:
            print(f"    {scenario_name}")

        print(f"")

    def list_deployed_scenario_instances(self):
        deployed_scenario_instances = list()
        for scenario_name in self.scenario_names:
            scenario_instance_dir_path = find_scenario_instance_dir(
                self.base_dir, scenario_name
            )

            if scenario_instance_dir_path is None:
                continue
            else:
                deployed_scenario_instances.append(scenario_instance_dir_path)

        if not deployed_scenario_instances:
            print(
                f'\n  No scenario instance directories exist. Try "list undeployed" or'
                f' "list all"\n'
            )
            return
        else:
            print(
                f"\n  Deployed scenario instances: {len(deployed_scenario_instances)}"
            )

        for scenario_instance_dir_path in deployed_scenario_instances:
            directory_name = os.path.basename(scenario_instance_dir_path)
            scenario_name, cgid = directory_name.split("_cgid")

            print(
                f"\n    {scenario_name}"
                f"\n        CGID: {'cgid' + cgid}"
                f"\n        Path: {scenario_instance_dir_path}"
            )

        print("")

    def list_undeployed_scenarios(self):
        undeployed_scenarios = list()
        for scenario_name in self.scenario_names:
            if not find_scenario_instance_dir(self.base_dir, scenario_name):
                undeployed_scenarios.append(scenario_name)

        if undeployed_scenarios:
            return print(
                f"\n  Undeployed scenarios: {len(undeployed_scenarios)}\n\n    "
                + f"\n    ".join(undeployed_scenarios)
                + f"\n"
            )
        else:
            return print(
                f'\n  All scenarios have been deployed. Try "list deployed" or "list'
                f' all"\n'
            )

    def list_scenario_instance(self, scenario_name_or_path):
        scenario_name = normalize_scenario_name(scenario_name_or_path)
        scenario_instance_dir_path = find_scenario_instance_dir(
            self.base_dir, scenario_name
        )

        if scenario_instance_dir_path is None:
            print(
                f'[cloudgoat] Error: No scenario instance for "{scenario_name}" found.'
                f" Try: cloudgoat.py list deployed"
            )
            return

        terraform = Terraform(
            working_dir=os.path.join(scenario_instance_dir_path, "terraform")
        )

        show_retcode, show_stdout, show_stderr = terraform.show(
            capture_output=False, no_color=IsNotFlagged
        )
        if show_retcode != 0:
            display_terraform_step_error(
                "terraform show", show_retcode, show_stdout, show_stderr
            )
            return
        else:
            print(f"\n[cloudgoat] terraform show completed with no error code.")

        return
