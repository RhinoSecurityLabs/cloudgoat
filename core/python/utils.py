import json
import os
import random
import re
import string
import subprocess
import tempfile
import yaml

from core.python.python_terraform import VariableFiles, Terraform


class PatchedVariableFiles(VariableFiles):
    def create(self, variables):
        with tempfile.NamedTemporaryFile(
            "w+t", suffix=".tfvars.json", delete=False
        ) as temp:
            self.files.append(temp)
            temp.write(json.dumps(variables))
            file_name = temp.name

        return file_name


class PatchedTerraform(Terraform):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        self.temp_var_files = PatchedVariableFiles()


def check_own_ip_address():
    curl_process = subprocess.Popen(
        ["curl", "-4", "ifconfig.co"], stdout=subprocess.PIPE, stderr=subprocess.PIPE
    )
    curl_process.wait()
    return curl_process.stdout.read().decode("utf-8").strip()


def create_dir_if_nonexistent(base_path, dir_name):
    dir_path = os.path.join(base_path, dir_name)

    try:
        os.mkdir(dir_path)
    except FileExistsError:
        pass

    return dir_path


def create_or_update_yaml_file(file_path, new_data):
    if not file_path or not new_data:
        return

    merged_data = dict()

    if os.path.exists(file_path):
        with open(file_path, "r") as file:
            data_loaded_from_file = yaml.safe_load(file.read())

        if not data_loaded_from_file:
            data_loaded_from_file = list()

        for loaded_section in data_loaded_from_file:
            for loaded_key, loaded_value in loaded_section.items():
                if loaded_key not in new_data.keys():
                    merged_data[loaded_key] = loaded_value

    merged_data.update(new_data)

    converted_data = list()

    for key, value in merged_data.items():
        converted_data.append({key: value})

    with open(file_path, "w") as file:
        file.write(yaml.safe_dump(converted_data))


def dirs_at_location(base_path, names_only=False):
    dirs = list()
    for filesystem_object in os.scandir(base_path):
        if filesystem_object.is_dir():
            if names_only:
                dirs.append(os.path.basename(filesystem_object.path))
            else:
                dirs.append(filesystem_object.path)
    return dirs


def display_terraform_step_error(step, retcode, stdout, stderr):
    print(
        f"\n[cloudgoat] Error while running `{step}`."
        f"\n    exit code: {retcode}"
        f"\n    stdout: {stdout}"
        f"\n    stderr: {stderr}\n"
    )


def extract_cgid_from_dir_name(dir_name):
    match = re.match(r"(?:.*)\_(cgid(?:[a-z0-9]){10})", dir_name)
    if match:
        return match.group(1)
    return None


def find_scenario_dir(scenarios_dir, dir_name):
    for dir_path in dirs_at_location(scenarios_dir):
        if os.path.basename(dir_path) == dir_name:
            return dir_path
    return None


def find_scenario_instance_dir(base_dir, scenario_name):
    for dir_path in dirs_at_location(base_dir):
        dir_match = re.findall(
            r"(.*)\_cgid(?:[a-z0-9]){10}$", os.path.basename(dir_path)
        )
        if dir_match and dir_match[0] == scenario_name:
            return dir_path
    return None


def generate_cgid():
    return "cgid" + "".join(
        random.choice(string.ascii_lowercase + string.digits) for x in range(10)
    )


def ip_address_or_range_is_valid(text):
    if not text:
        return False

    if text.count("/") == 0:
        return False
    elif text.count("/") == 1:
        octets, subnet = text.split("/")
    else:
        return False

    if octets.startswith(".") or octets.endswith("."):
        return False
    elif not len(octets.split(".")) == 4:
        return False

    for octet in octets.split("."):
        if not octet.isdigit():
            return False
        if len(octet) > 1 and octet.startswith("0"):
            return False
        if not (0 <= int(octet) <= 255):
            return False

    if not subnet.isdigit():
        return False
    elif not (0 <= int(subnet) <= 32):
        return False

    return True


def load_and_validate_whitelist(whitelist_path):
    whitelisted_ips = list()

    with open(whitelist_path, "r") as whitelist_file:
        lines = whitelist_file.read().split("\n")

    # Save the original line numbers alongside the lines.
    lines = zip(range(1, len(lines) + 1), lines)
    # Remove comments.
    lines = filter(lambda line: not line[1].strip().startswith("#"), lines)
    # Remove empty lines.
    lines = filter(lambda line: bool(line[1]), lines)
    # Listify it to avoid consuming the generator during iteration (for `len`).
    lines = list(lines)

    for iteration_number, original_line_tuple in enumerate(lines, 1):
        original_line_number, line = original_line_tuple
        if line.strip() == "":
            continue

        is_valid = ip_address_or_range_is_valid(line.strip())

        if not is_valid:
            print(
                f"\nWhitelist line {original_line_number} is invalid:"
                f"\n    {line[:150]}\n"
                f"\nPlease repair the line and try again. IP addresses may use CIDR"
                f" notation. For example:"
                f"\n    127.0.0.1"
                f"\n    127.0.0.1/32"
            )
            return None

        whitelisted_ips.append(line.strip())

    if not whitelisted_ips:
        print(
            f"No IP addresses or ranges found. Add IP addresses in CIDR notation, or"
            f' delete the whitelist.txt file and try "config whitelist".'
        )
        return None

    return whitelisted_ips


def load_data_from_yaml_file(file_path, key):
    if not file_path or not key:
        return

    with open(file_path, "r") as file:
        yaml_data = yaml.safe_load(file.read())

    if yaml_data:
        for section in yaml_data:
            if key in section.keys():
                return section[key]

    return None


def normalize_scenario_name(scenario_name_or_path):
    if not scenario_name_or_path:
        return scenario_name_or_path

    scenario_instance_name_match = re.findall(
        r".*?(\w+)_cgid(?:[a-z0-9]){10}.*", scenario_name_or_path
    )
    if scenario_instance_name_match:
        return scenario_instance_name_match[0]

    if scenario_name_or_path.count(os.path.sep) == 0:
        return scenario_name_or_path

    fully_split_path = scenario_name_or_path.split(os.path.sep)

    if "scenarios" in fully_split_path:
        index = fully_split_path.index("scenarios")
        relative_path = os.path.sep.join(fully_split_path[index : index + 2])
        return os.path.basename(relative_path.strip(os.path.sep))
    else:
        return os.path.basename(scenario_name_or_path.strip(os.path.sep))
