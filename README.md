<p align="center">
  <img src="https://rhinosecuritylabs.com/wp-content/uploads/2018/07/cloudgoat-e1533043938802-1140x400.jpg" width=350/>
</p>

# CloudGoat 2.0 is here!

CloudGoat is Rhino Security Labs' "Vulnerable by Design" AWS deployment tool. It allows you to hone your cloud cybersecurity skills by creating and completing several "capture-the-flag" style scenarios. Each scenario is composed of AWS resources arranged together to create a structured learning experience. Some scenarios are easy, some are hard, and many offer multiple paths to victory. As the attacker, it is your mission to explore the environment, identify vulnerabilities, and exploit your way to the scenario's goal(s).

Below are our main goals for CloudGoat:

* **Focused, Curated, High-Quality Learning Experiences** - Each of CloudGoat’s scenarios should provide the opportunity for experimentation, exploration, and building hands-on cloud security skills.
* **Good Documentation** - We've done our best to ensure that CloudGoat’s scenarios are well-documented and easy to understand and evaluate in terms of difficulty, content, structure, and skills-required.
* **Easy to Install and Use** - We understand that CloudGoat is a means to an end - learning and practicing cloud security penetration testing. Therefore, we aim to keep things simple, straightforward, and reliable.
* **Modularity** - Each scenario is a standalone learning environment with a clear goal (or set of goals), and CloudGoat is able to start up, reset, or shut down each scenario independently.
* **Expandability** - CloudGoat’s core components (python app and scenarios) are designed to permit easy and independent expansion - by us or the community.

Before you proceed, please take note of these warnings!

> **Warning #1:** CloudGoat creates intentionally vulnerable AWS resources into your account. DO NOT deploy CloudGoat in a production environment or alongside any sensitive AWS resources.

> **Warning #2:** CloudGoat can only manage resources it creates. If you create any resources yourself in the course of a scenario, you should remove them manually before running the `destroy` command.

## Requirements

* Linux or MacOS. Windows is not officially supported.
  * Argument tab-completion requires bash 4.2+ (Linux, or OSX with some difficulty).
* Python3.6+ is required.
* Terraform 0.12 [installed and in your $PATH](https://learn.hashicorp.com/terraform/getting-started/install.html).
* The AWS CLI [installed and in your $PATH](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-install.html), and an AWS account with sufficient privileges to create and destroy resources.

## Quick Start

To install CloudGoat, make sure your system meets the requirements above, and then run the following commands:

```
$ git clone git@github.com:RhinoSecurityLabs/cloudgoat.git ./CloudGoat
$ cd CloudGoat
$ pip3 install -r ./core/python/requirements.txt
```
You may also want to run some quick configuration commands - it'll save you some time later:
```
$ ./cloudgoat.py config profile
$ ./cloudgoat.py config whitelist --auto
```
Now, at your command, CloudGoat can `create` an instance of a scenario in the cloud. When the environment is ready, a new folder will be created in the project base directory named after the scenario and with a unique scenario ID appended. Inside this folder will be a file called `start.txt`, which will contain all of the resources you'll need to begin the scenario, though these are also printed to your console when the `create` command completes. Sometimes an SSH keypair named `cloudgoat`/`cloudgoat.pub` will be created as well.

> **Note:** Don't delete or modify the scenario instance folder or the files inside, as this could prevent CloudGoat from being able to manage your scenario's resources.

As you work through the scenario, feel free to refer to the scenario's readme if you need direction. If you get stuck, there are cheat sheets linked at the bottom of each route's walkthrough.

When you are finished with the scenario, delete any resources you created yourself (remember: CloudGoat can only manage resources it creates) and then run the `destroy` command. It's always a good idea to take a quick glance at your AWS web-console afterwards - just in case something didn't get deleted.

You can read the full documentation for CloudGoat's commands [here in the Usage Guide section](#usage-guide).

## Scenarios Available

### iam_privesc_by_rollback (Small / Easy)

`$ ./cloudgoat.py create iam_privesc_by_rollback`

Starting with a highly-limited IAM user, the attacker is able to review previous IAM policy versions and restore one which allows full admin privileges, resulting in a privilege escalation exploit.

[Visit Scenario Page.](scenarios/iam_privesc_by_rollback/README.md)

### iam_privesc_by_attachment (Medium / Moderate)

`$ ./cloudgoat.py create iam_privesc_by_attachment`

Starting with a very limited set of permissions, the attacker is able to leverage the instance-profile-attachment permissions to create a new EC2 instance with significantly greater privileges than their own. With access to this new EC2 instance, the attacker gains full administrative powers within the target account and is able to accomplish the scenario's goal - deleting the cg-super-critical-security-server and paving the way for further nefarious actions.

> **Note:** This scenario may require you to create some AWS resources, and because CloudGoat can only manage resources it creates, you should remove them manually before running `./cloudgoat destroy`.

[Visit Scenario Page.](scenarios/iam_privesc_by_attachment/README.md)

### ec2_ssrf (Medium / Moderate)

`$ ./cloudgoat.py create ec2_ssrf`

Starting as the IAM user Solus, the attacker discovers they have ReadOnly permissions to a Lambda function, where hardcoded secrets lead them to an EC2 instance running a web application that is vulnerable to server-side request forgery (SSRF). After exploiting the vulnerable app and acquiring keys from the EC2 metadata service, the attacker gains access to a private S3 bucket with a set of keys that allow them to invoke the Lambda function and complete the scenario.

[Visit Scenario Page.](scenarios/ec2_ssrf/README.md)

### rce_web_app (Medium / Hard)

`$ ./cloudgoat.py create rce_web_app`

Starting as the IAM user Lara, the attacker explores a Load Balancer and S3 bucket for clues to vulnerabilities, leading to an RCE exploit on a vulnerable web app which exposes confidential files and culminates in access to the scenario’s goal: a highly-secured RDS database instance.

Alternatively, the attacker may start as the IAM user McDuck and enumerate S3 buckets, eventually leading to SSH keys which grant direct access to the EC2 server and the database beyond.

[Visit Scenario Page.](scenarios/rce_web_app/README.md)

### codebuild_secrets (Large / Hard)

`$ ./cloudgoat.py create codebuild_secrets`

Starting as the IAM user Solo, the attacker first enumerates and explores CodeBuild projects, finding unsecured IAM keys for the IAM user Calrissian therein. Then operating as Calrissian, the attacker discovers an RDS database. Unable to access the database's contents directly, the attacker can make clever use of the RDS snapshot functionality to acquire the scenario's goal: a pair of secret strings.

Alternatively, the attacker may explore SSM parameters and find SSH keys to an EC2 instance. Using the metadata service, the attacker can acquire the EC2 instance-profile's keys and push deeper into the target environment, eventually gaining access to the original database and the scenario goal inside (a pair of secret strings) by a more circuitous route.

> **Note:** This scenario may require you to create some AWS resources, and because CloudGoat can only manage resources it creates, you should remove them manually before running `./cloudgoat destroy`.

[Visit Scenario Page.](scenarios/codebuild_secrets/README.md)

## Usage Guide

The basic anatomy of a CloudGoat command is as follows:

> `$ ./cloudgoat.py [ command ] [ sub-command ] [ --arg-name ] [ arg-value ]`

The five main commands in CloudGoat are summarized below:

### create

`create [ scenario-name ]` deploys a scenario to the AWS account of your choosing. You can also run `create` against an existing scenario if you wish - CloudGoat will simply destroy and recreate the scenario named.

> **Tip:** you can use `/scenarios` in the name, which allows for bash's native tab-completion.

Note that the `--profile` is required for safety reasons - we don't want anyone accidentally deploying CloudGoat scenarios to a production environment - and CloudGoat will not use the system's "default" AWS CLI profiles or profiles specified as defaults via environment variables. You can, however, set this via `config profile` to avoid having to provide it every time.

### list

`list` shows some information about `all`, `undeployed`, or `deployed` scenarios, or even a lot of information about a `[ scenario-name ]` that's already deployed.

### destroy

`destroy` shuts down and deletes a `[ scenario-name ]`'s cloud resources, and then moves the scenario instance folder to `./trash` - just in case you need to recover the Terraform state file or other scenario files. You can also specify `all` instead of a scenario name to destroy all active scenarios.

> **Tip:** CloudGoat can only manage resources it creates. If you create any resources yourself in the course of a scenario, you should remove them manually before running the `destroy` command.

### config

`config` allows you to manage various aspects of your CloudGoat installation, specially the IP `whitelist`, your default AWS `profile`, and tab-completion via `argcomplete`. It's worth briefly describing what each of these sub-commands do.

#### whitelist

CloudGoat needs to know what IP addresses should be whitelisted when potentially-vulnerable resources are deployed in the cloud, and these IPs are tracked in a `./whitelist.txt` file in the base project directory. The IP address you provide for whitelisting doesn't _have_ to be in CIDR format, but CloudGoat will add a `/32` to any naked IPs you provide. Optionally, you can add the `--auto` argument, and CloudGoat will automatically make a network request, using curl to ifconfig.co to find your IP address, and then create the whitelist file with the result.

#### profile

While CloudGoat will not ever use the system's "default" AWS CLI profiles or profiles specified as defaults via environment variables, you can instruct CloudGoat to use a particular AWS profile by name using the `config profile` command. This will prompt for and save your profile's name in a `config.yml` file in the base project directory. As long as that file is present CloudGoat will use the profile name listed inside for create and destroy commands, rather than requiring the `--profile` flag. You can run the `config profile` command at any time to view the name of your CloudGoat-default profile and validate the format of the `config.yml`. You can also create `config.yml` manually, if you wish, provided that you use the correct format.

#### argcomplete

We really wanted to have native tab-completion in CloudGoat, but as it turns out that was somewhat difficult to do outside of a REPL. It should work reasonably well for Linux users, and those OSX users brave enough to figure out a way to upgrade their bash version to 4.2+. CloudGoat does include and support [the python library "argcomplete"](https://github.com/kislyuk/argcomplete). A brief summary of how to install argcomplete is provided below, though for more detailed steps you should refer to the official documentation at the library's [github page](https://github.com/kislyuk/argcomplete).

1. Install the argcomplete Python package using CloudGoat's requirements.txt file: `$ pip3 install -r core/python/requirements.txt`
2. In bash, run the global Python argument completion script provided by the argcomplete package: `$ activate-global-python-argcomplete`
3. Source the completion script at the location printed by the previous activation command, or restart your shell session: `$ source [ /path/to/the/completion/script ]`

For those who cannot or do not wish to configure argcomplete, CloudGoat also supports the use of directory paths as scenario names, which means tab-completion will work for scenario names. Just use `/scenario/[ scenario-name ]` or `./[ scenarioinstance-name ]` and your shell should do the rest.

### help

`help` provides contextual help about commands. `help` can come before or after the command in question, so it's always there when you need it. Below are some examples:

* `$ ./cloudgoat.py create help`
* `$ ./cloudgoat.py destroy help`
* `$ ./cloudgoat.py list help`
* `$ ./cloudgoat.py config help`

One other use of note: `$ ./cloudgoat.py [ scenario-name ] help` can be used to print to the console a brief summary of the scenario, as defined by the scenario's author.

## Feature Requests and Bug Reports

If you have a feature request or a bug to report, please [submit them here](https://github.com/RhinoSecurityLabs/cloudgoat/issues/new).

For bugs, please make sure to include a description sufficient to reproduce the bug you found, including tracebacks and reproduction steps, and check for other reports of your bug before filing a new bug report.

For features, much the same applies! Be specific in your request, and make sure someone else hasn't already requested the same feature.

## Contribution Guidelines

Contributions to CloudGoat are greatly appreciated. If you'd like to help make the project better, read on.

1. Python code in CloudGoat should generally follow Python's style conventions, favoring readability and maintainability above all.
2. Follow good git practices: use pull requests, prefer feature branches, always write clear commit messages.
3. CloudGoat uses `black` and `flake8` - Python syntax and style linters - If you're going to commit code for CloudGoat, ensure that first `flake8`, and then `black` are both run on all Python files in `core/python/` and on `cloudgoat.py`. `black`'s decisions take priority over `flake8`'s. Both of these are commented out in the `core/python/requirements.txt` file since normal users don't need them.
4. CloudGoat code should always use the BSD 3-clause license.

And lastly, thank you for contributing!

## Changelog

- **6/24/19:** CloudGoat 2.0 is released!

## Disclaimer

CloudGoat is software that comes with absolutely no warranties whatsoever. By using CloudGoat, you take full responsibility for any and all outcomes that result.
