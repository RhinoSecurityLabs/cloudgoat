import os
import re
import shutil
import subprocess
import json

from cloudgoat.core.python import help_text
from cloudgoat.core.python.python_terraform import IsNotFlagged
from cloudgoat.core.python.utils import PatchedTerraform as Terraform
from cloudgoat.core.python.utils import (
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
        self.cloud_platforms = dirs_at_location(self.scenarios_dir, names_only=True)
        self.scenario_names = []
        for platform in self.cloud_platforms:
            platform_scenarios_dir = os.path.join(self.scenarios_dir, platform)
            self.scenario_names += dirs_at_location(platform_scenarios_dir, names_only=True)
        self.whitelist_path = os.path.join(base_dir, "whitelist.txt")
        self.cg_whitelist = None

        self.aws_region = "us-east-1"
        self.cloudgoat_commands = ["config", "create", "destroy", "list", "help"]
        self.non_scenario_instance_dirs = [
            ".git",
            "__pycache__",
            "core",
            "scenarios",
            "trash",
        ]
        self.terraform = None
        self.azure_subscription_id = None

    def parse_and_execute_command(self, parsed_args):
        self.parsed_args = parsed_args
        command = parsed_args.command
        self.profile = parsed_args.profile

        # Handle help commands
        if not command or command[0] in {"help", "-h", "--help"} or (len(command) >= 2 and command[-1] == "help"):
            return self.display_cloudgoat_help(command)

        # Define allowed subcommands for validation
        command_help_texts = {
            "config": 'The "config" command must be used with "whitelist", "aws", "azure", or "help".',
            "create": f'The "create" command must be used with a scenario name or "help".\nAll scenarios:\n    ' + "\n    ".join(self.scenario_names),
            "destroy": f'The "destroy" command must be used with a scenario name, "all", or "help".\nAll scenarios:\n    ' + "\n    ".join(self.scenario_names),
            "list": f'The "list" command can be used with a scenario name, "all", "deployed", "undeployed", "aws", "azure", or "help".\nAll scenarios:\n    ' + "\n    ".join(self.scenario_names),
        }

        # Validate single-word commands
        if len(command) == 1 and command[0] in command_help_texts:
            print(command_help_texts[command[0]])
            return

        # Prevent invalid scenario names
        if command[0] in {"create", "destroy", "list"}:
            self.scenario_name = command[1].lower()
            if self.scenario_name in self.cloudgoat_commands or self.scenario_name in self.non_scenario_instance_dirs:
                print(f'Invalid scenario name "{self.scenario_name}". It conflicts with a CloudGoat command or reserved name.')
                return

        # Ensure AWS profile is set for create/destroy commands
        if command[0] in {"create", "destroy"} and self.scenario_name != "all":
            
            self.cg_whitelist = self.configure_or_check_whitelist(auto=not os.path.exists(self.whitelist_path))
            self.instance_path = self._get_instance_path(scenario_name_or_path=self.scenario_name)
            self.scenario_cloud_platform = self._get_cloud_platform()
            
            if self.scenario_cloud_platform == 'aws' and not self.profile:
                self.profile = self._get_profile_or_default()
                if not self.profile:
                    print(f'For AWS scenarios this command requires the --profile flag or a default profile in config.yml (try "config aws").')
                    return
                print(f'Using default profile "{self.profile}" from config.yml...')

            if self.scenario_cloud_platform == 'azure' and not self.azure_subscription_id:
                self.azure_subscription_id = self._get_subscription_or_default()
                if not self.azure_subscription_id:
                    print(f'For Azure scenarios this command requires a subscription_id in config.yml (try "config azure").')
                    return
                print(f'Using default subscription ID "{self.azure_subscription_id}" from config.yml...')

        # Execute commands
        if command[0] == "config":
            return self._execute_config_command(command)

        if command[0] == "create":
            return self.create_scenario()

        if command[0] == "destroy":
            return self.destroy_all_scenarios() if command[1] == "all" else self.destroy_scenario(command[1])

        if command[0] == "list":
            return self._execute_list_command(command)

        print('Unrecognized command. Try "cloudgoat.py help".')

    def _get_cloud_platform(self):
        self.terraform = Terraform(working_dir=os.path.join(self.instance_path, "terraform"))
        providers = self.terraform.providers()
        cloud = None
        if "aws" in providers:
            cloud = "aws"
        if "azure" in providers:
            cloud = "azure"
        
        return cloud

    def _get_instance_path(self, scenario_name_or_path):
        scenario_name = normalize_scenario_name(scenario_name_or_path)
        scenario_dir = find_scenario_dir(self.scenarios_dir, scenario_name)

        if not scenario_name or not os.path.exists(scenario_dir):
            print(
                f"No recognized scenario name was entered. Did you mean one of these?\n    "
                + "\n    ".join(self.scenario_names)
            )
            return
        
        instance_path = find_scenario_instance_dir(self.base_dir, scenario_name)
        if instance_path:
            print(
                f"\n{'*' * 97}\nFound previously deployed {scenario_name} scenario.\n\n"
                f"\n{'*' * 97}\n"
            )
        else:
            cgid = generate_cgid()
            instance_path = os.path.join(self.base_dir, f"{scenario_name}_{cgid}")
            shutil.copytree(os.path.join(scenario_dir, "."), instance_path)

        return instance_path

    def _get_subscription_or_default(self):
        """Returns the user-specified Azure subscription_id or the default from config.yml."""
        if os.path.exists(self.config_path):
            return load_data_from_yaml_file(self.config_path, "default-subscription-id")
        return None

    def _get_profile_or_default(self):
        """Returns the user-specified AWS profile or the default from config.yml."""
        if os.path.exists(self.config_path):
            return load_data_from_yaml_file(self.config_path, "default-profile")
        return None

    def _execute_config_command(self, command):
        """Executes config-related commands."""
        subcommand = command[1]
        if subcommand in {"whitelist", "whitelist.txt"}:
            return self.configure_or_check_whitelist(auto=self.parsed_args.auto, print_values=True)
        if subcommand == "aws":
            return self.configure_or_check_platform(cloud_platform='aws')
        if subcommand == "azure":
            return self.configure_or_check_platform(cloud_platform='azure')
        if subcommand == "argcomplete":
            return self.configure_argcomplete()

    def _execute_list_command(self, command):
        """Executes list-related commands."""
        subcommand = command[1]
        list_commands = {
            "all": self.list_all_scenarios,
            "deployed": self.list_deployed_scenario_instances,
            "undeployed": self.list_undeployed_scenarios,
            "aws": self.list_aws_scenarios,
            "azure": self.list_azure_scenarios
        }
        return list_commands.get(subcommand, lambda: self.list_scenario_instance(subcommand))()

    def list_aws_scenarios(self):
        return self.list_all_scenarios(platform_filter='aws')
    
    def list_azure_scenarios(self):
        return self.list_all_scenarios(platform_filter='azure')

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

    def configure_or_check_platform(self, cloud_platform="aws"):
        setting_key = "default-profile" if cloud_platform == "aws" else "default-subscription-id"

        # Check if configuration file exists
        if not os.path.exists(self.config_path):
            create_config_file_now = input(
                f"No configuration file was found at {self.config_path}.\n"
                f"Would you like to create this file with a default {cloud_platform} setting now? [y/n]: "
            )
            default_setting = None
        else:
            print(f"A configuration file exists at {self.config_path}")
            default_setting = load_data_from_yaml_file(self.config_path, setting_key)

            if default_setting:
                print("Found existing configuration, continuing will overwrite.")

            create_config_file_now = input(
                f"Would you like to specify a new default {cloud_platform} setting now? [y/n]: "
            )

        # If user does not want to create/update the config, exit
        if not create_config_file_now.strip().lower().startswith("y"):
            return

        while True:
            if cloud_platform == "aws":
                default_setting = input("Enter the name of your default AWS profile: ").strip()
            elif cloud_platform == "azure":
                default_setting = input("Enter your Azure Subscription ID: ").strip()
            else:
                print("Unsupported cloud platform.")
                return

            if default_setting:
                create_or_update_yaml_file(self.config_path, {setting_key: default_setting})
                print(f'A default {cloud_platform} setting of "{default_setting}" has been saved.')
                
                # CLI Configuration reminder
                if cloud_platform == 'azure':
                    print('Remember to run "az login" before deploying an Azure scenario.')
                
                break
            else:
                print(f"Enter a valid {cloud_platform} setting, or hit Ctrl+C to exit.")
                continue


        return

    def configure_or_check_whitelist(self, auto=False, print_values=False):
        if auto:
            message = (
                f"CloudGoat can automatically make a network request, using "
                f"https://ifconfig.co to find your IP address, and then overwrite the"
                f" contents of the whitelist file with the result."
                f"\nWould you like to continue? [y/n]: "
            )

            if os.path.exists(self.whitelist_path):
                confirm_auto_configure = input(
                    f"A whitelist.txt file was found at {self.whitelist_path}\n\n{message}"
                )
            else:
                confirm_auto_configure = input(
                    f"No whitelist.txt file was found at {self.whitelist_path}\n\n{message}"
                )

            if confirm_auto_configure.strip().lower().startswith("y"):
                ip_address = check_own_ip_address()

                if ip_address is None:
                    print(f"\n[cloudgoat] Unknown error: Unable to retrieve IP address.\n")
                    return None

                ip_address = f"{ip_address}/32"

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

    def _get_tf_vars(self, cgid=None):
        if not cgid:
            cgid = extract_cgid_from_dir_name(self.instance_path)

        tf_vars = {"cgid": cgid, "cg_whitelist": self.cg_whitelist}
        if self.scenario_cloud_platform == 'aws':
            tf_vars.update({"profile": self.profile, "region": self.aws_region})
        if self.scenario_cloud_platform == 'azure':
            tf_vars.update({"subscription_id": self.azure_subscription_id})
        if self.scenario_name == "detection_evasion":
            tf_vars["user_email"] = self.get_user_email()

        return tf_vars

    def create_scenario(self):

        if not self.cg_whitelist:
            print(f"A valid whitelist.txt file must exist in {self.base_dir} before 'create' may be used.")
            return

        start_script = os.path.join(self.instance_path, "start.sh")
        if os.path.exists(start_script):
            print(f"\nNow running {self.scenario_name}'s start.sh...")
            subprocess.run(["sh", "start.sh"], cwd=self.instance_path, check=True)

        if self.terraform.init(capture_output=False, no_color=IsNotFlagged)[0] != 0:
            display_terraform_step_error("terraform init", *self.terraform.init())
            return
        print("\n[cloudgoat] terraform init completed with no error code.")

        tf_vars = self._get_tf_vars()

        if self.terraform.plan(capture_output=False, var=tf_vars, no_color=IsNotFlagged)[0] not in (0, 2):
            display_terraform_step_error("terraform plan", *self.terraform.plan())
            return
        print("\n[cloudgoat] terraform plan completed with no error code.")

        if self.terraform.apply(capture_output=False, var=tf_vars, skip_plan=True, no_color=IsNotFlagged)[0] != 0:
            display_terraform_step_error("terraform apply", *self.terraform.apply())
            return
        print("\n[cloudgoat] terraform apply completed with no error code.")

        output_retcode, output_stdout, output_stderr = self.terraform.output_cmd("--json")
        if output_retcode != 0:
            display_terraform_step_error("terraform output", output_retcode, output_stdout, output_stderr)
            return
        print("\n[cloudgoat] terraform output completed with no error code.")

        start_file_path = os.path.join(self.instance_path, "start.txt")
        with open(start_file_path, "w") as start_file:
            output = json.loads(output_stdout)
            for k, v in output.items():
                line = f"{k} = {v['value']}"
                print(line)
                start_file.write(line + '\n')

        print(f"\n[cloudgoat] Output file written to:\n\n    {start_file_path}\n")

    def get_user_email(self):
        user_email = load_data_from_yaml_file(
                self.config_path, "user_email"
            )
        if not user_email:
            user_email = input("Please enter the email that you would like to have alerts sent to during this scenario:   ")
            create_or_update_yaml_file(
                self.config_path, {"user_email": user_email}
            )
            print(f'A default user_email of "{user_email}" has been saved in config.yml')
        return user_email

    def destroy_all_scenarios(self):
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

        delete_all_selection = input('Would you like to delete all without further input? [y/N]: ').lower() == 'y'

        # Iteration.
        success_count, failure_count, skipped_count = 0, 0, 0
        for scenario_name, instance_path in extant_scenario_instance_names_and_paths:
            print(f"\n--------------------------------\n")
            self.instance_path = instance_path
            self.scenario_cloud_platform = self._get_cloud_platform()
            if self.scenario_cloud_platform == 'aws':
                self.profile = self._get_profile_or_default()
            if self.scenario_cloud_platform == 'azure':
                self.azure_subscription_id = self._get_subscription_or_default()
            
            destroy_result = self.destroy_scenario(scenario_name_or_path=instance_path, confirmed=delete_all_selection)

            if destroy_result == 'destroyed':
                success_count += 1
            if destroy_result == 'failed':
                failure_count += 1
            if destroy_result == 'skipped':
                skipped_count += 1


        # Iteration summary.
        print(
            f"\nDestruction complete."
            f"\n    {success_count} scenarios successfully destroyed"
            f"\n    {failure_count} destroys failed"
            f"\n    {skipped_count} skipped\n"
        )

        return

    def destroy_scenario(self, scenario_name_or_path, confirmed=False):
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
            return "failed"

        instance_name = os.path.basename(scenario_instance_dir_path)

        # Confirmation.
        if not confirmed:
            delete_permission = input(f'Destroy "{instance_name}"? [y/n]: ').strip()
            if not delete_permission or not delete_permission[0].lower() == "y":
                print(f"\nCancelled destruction of {instance_name}.\n")
                return "skipped"

        # Terraform execution.
        terraform_directory = os.path.join(scenario_instance_dir_path, "terraform")

        if os.path.exists(os.path.join(terraform_directory, "terraform.tfstate")):
            cgid = extract_cgid_from_dir_name(
                os.path.basename(scenario_instance_dir_path)
            )

            tf_vars = self._get_tf_vars(cgid=cgid)

            destroy_retcode, destroy_stdout, destroy_stderr = self.terraform.destroy(
                capture_output=False,
                var=tf_vars,
                no_color=IsNotFlagged,
            )

            if destroy_retcode != 0:
                display_terraform_step_error(
                    "terraform destroy", destroy_retcode, destroy_stdout, destroy_stderr
                )
                return "failed"
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

        return "destroyed"

    def list_all_scenarios(self, platform_filter=None):
        undeployed_scenarios = list()
        deployed_scenario_instance_paths = list()

        for scenario_name in self.scenario_names:
            scenario_path = find_scenario_dir(self.scenarios_dir, scenario_name)
            if platform_filter and platform_filter not in scenario_path:
                continue

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
