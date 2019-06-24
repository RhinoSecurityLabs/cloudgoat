import os
import sys
import unittest

sys.path.insert(
    0, os.path.abspath(os.path.join(os.path.dirname(os.path.dirname(__file__)), ".."))
)

from core.python.utils import (
    extract_cgid_from_dir_name,
    ip_address_or_range_is_valid,
    normalize_scenario_name,
)


class TestUtilityFunctions(unittest.TestCase):
    def test_extract_cgid_from_dir_name(self):
        self.assertEqual(extract_cgid_from_dir_name("codebuild_secrets"), None)
        self.assertEqual(extract_cgid_from_dir_name("/codebuild_secrets"), None)
        self.assertEqual(extract_cgid_from_dir_name("scenarios/ec2_ssrf"), None)
        self.assertEqual(extract_cgid_from_dir_name("/scenarios/ec2_ssrf"), None)
        self.assertEqual(
            extract_cgid_from_dir_name("long/path/iam_privesc_by_attachment"), None
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/long/path/iam_privesc_by_attachment"), None
        )
        self.assertEqual(
            extract_cgid_from_dir_name("long/path/rce_web_app/even/longer/path"), None
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/long/path/rce_web_app/even/longer/path"), None
        )

        self.assertEqual(
            extract_cgid_from_dir_name("codebuild_secrets_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/codebuild_secrets_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name("scenarios/ec2_ssrf_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name("/scenarios/ec2_ssrf_cgid0123456789"),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "long/path/iam_privesc_by_attachment_cgid0123456789"
            ),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "/long/path/iam_privesc_by_attachment_cgid0123456789"
            ),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "long/path/rce_web_app_cgid0123456789/even/longer/path"
            ),
            "cgid0123456789",
        )
        self.assertEqual(
            extract_cgid_from_dir_name(
                "/long/path/rce_web_app_cgid0123456789/even/longer/path"
            ),
            "cgid0123456789",
        )

    def test_ip_address_or_range_is_valid(self):
        # IPv4 CIDR notation is required.
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1//32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1\\32"), False)

        # Octets must be valid.
        self.assertEqual(ip_address_or_range_is_valid(".0.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0./32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127..0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0..1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127...1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("..0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127..0./32"), False)
        self.assertEqual(ip_address_or_range_is_valid(".0..1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0../32"), False)
        self.assertEqual(ip_address_or_range_is_valid("...1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.../32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.255.256/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.256.255/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("255.256.255.255/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("256.255.255.255/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.255.-1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("255.255.-1.255/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("255.-1.255.255/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("-1.255.255.255/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.I/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.O.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.O.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("I27.0.0.1/32"), False)
        self.assertEqual(ip_address_or_range_is_valid("0.0.0.0/32"), True)
        self.assertEqual(ip_address_or_range_is_valid("255.255.255.255/32"), True)

        # Subnets must be valid.
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/-33"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/-32"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/-1"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/0"), True)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/O"), False)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/1"), True)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/32"), True)
        self.assertEqual(ip_address_or_range_is_valid("127.0.0.1/33"), False)

    def test_normalize_scenario_name(self):
        # Edge cases
        self.assertEqual(normalize_scenario_name(""), "")
        self.assertEqual(normalize_scenario_name("/"), "")
        self.assertEqual(normalize_scenario_name("/////"), "")

        # Simple cases, fake scenario names
        self.assertEqual(normalize_scenario_name("test_a/"), "test_a")
        self.assertEqual(normalize_scenario_name("/test_b"), "test_b")
        self.assertEqual(normalize_scenario_name("test_a/test_b"), "test_b")
        self.assertEqual(normalize_scenario_name("/test_a/test_b"), "test_b")

        # "scenarios" directory
        self.assertEqual(normalize_scenario_name("scenarios"), "scenarios")
        self.assertEqual(normalize_scenario_name("scenarios/"), "scenarios")
        self.assertEqual(normalize_scenario_name("/scenarios"), "scenarios")
        self.assertEqual(normalize_scenario_name("test_a/scenarios"), "scenarios")
        self.assertEqual(normalize_scenario_name("scenarios/test_b"), "test_b")
        self.assertEqual(normalize_scenario_name("test_a/scenarios/test_b"), "test_b")

        # Real scenario names
        self.assertEqual(normalize_scenario_name("rce_web_app/"), "rce_web_app")
        self.assertEqual(normalize_scenario_name("/rce_web_app"), "rce_web_app")

        self.assertEqual(
            normalize_scenario_name("scenarios/rce_web_app"), "rce_web_app"
        )
        self.assertEqual(
            normalize_scenario_name("/scenarios/rce_web_app"), "rce_web_app"
        )

        # Long paths
        self.assertEqual(
            normalize_scenario_name("/long/path/scenarios/rce_web_app"), "rce_web_app"
        )
        self.assertEqual(
            normalize_scenario_name("scenarios/rce_web_app/even/longer/path"),
            "rce_web_app",
        )
        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/rce_web_app/even/longer/path"
            ),
            "rce_web_app",
        )

        self.assertEqual(
            normalize_scenario_name("/long/path/scenarios/not-a-real-scenario"),
            "not-a-real-scenario",
        )
        self.assertEqual(
            normalize_scenario_name("scenarios/not-a-real-scenario/even/longer/path"),
            "not-a-real-scenario",
        )
        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/not-a-real-scenario/even/longer/path"
            ),
            "not-a-real-scenario",
        )

        # Scenario instance paths
        self.assertEqual(
            normalize_scenario_name("codebuild_secrets_cgid0123456789"),
            "codebuild_secrets",
        )
        self.assertEqual(
            normalize_scenario_name("scenarios/codebuild_secrets_cgid0123456789"),
            "codebuild_secrets",
        )
        self.assertEqual(
            normalize_scenario_name("codebuild_secrets_cgid0123456789/scenarios"),
            "codebuild_secrets",
        )

        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/codebuild_secrets_cgid0123456789"
            ),
            "codebuild_secrets",
        )
        self.assertEqual(
            normalize_scenario_name(
                "scenarios/codebuild_secrets_cgid0123456789/even/longer/path"
            ),
            "codebuild_secrets",
        )
        self.assertEqual(
            normalize_scenario_name(
                "/long/path/scenarios/codebuild_secrets_cgid0123456789/even/longer/path"
            ),
            "codebuild_secrets",
        )


if __name__ == "__main__":
    unittest.main()
