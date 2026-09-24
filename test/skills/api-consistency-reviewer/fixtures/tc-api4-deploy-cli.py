"""Command-line entry point for the `shipit` deploy tool."""

import argparse
import sys

from shipit import commands


def build_parser():
    parser = argparse.ArgumentParser(prog="shipit")
    parser.add_argument("--verbose", "-v", action="store_true", help="Verbose logging")
    sub = parser.add_subparsers(dest="command", required=True)

    deploy = sub.add_parser("deploy", help="Deploy a build to an environment")
    deploy.add_argument("build_id")
    deploy.add_argument("--env", required=True, help="Target environment")
    deploy.add_argument("--dry-run", action="store_true", help="Print the plan without applying it")
    deploy.add_argument("--wait-timeout", type=int, default=300, help="Seconds to wait for health checks")
    deploy.set_defaults(func=commands.deploy)

    scale = sub.add_parser("scale", help="Change the replica count of a service")
    scale.add_argument("service")
    scale.add_argument("--env", required=True, help="Target environment")
    scale.add_argument("--replicas", type=int, required=True, help="Desired replica count")
    scale.add_argument("--dry-run", action="store_true", help="Print the plan without applying it")
    scale.add_argument("--wait-timeout", type=int, default=300, help="Seconds to wait for health checks")
    scale.set_defaults(func=commands.scale)

    status = sub.add_parser("status", help="Show what is deployed where")
    status.add_argument("--env", help="Limit to one environment")
    status.add_argument("--output-format", choices=["table", "json"], default="table")
    status.set_defaults(func=commands.status)

    # BEGIN CHANGE UNDER REVIEW
    rollback = sub.add_parser("rollback", help="Roll a service back to its previous build")
    rollback.add_argument("service")
    rollback.add_argument("--env", required=True, help="Target environment")
    rollback.add_argument("--to-build", help="Build id to roll back to (default: previous)")
    rollback.add_argument("--dry_run", action="store_true", help="Print the plan without applying it")
    rollback.add_argument("--wait-timeout", type=int, default=300, help="Seconds to wait for health checks")
    rollback.set_defaults(func=commands.rollback)
    # END CHANGE UNDER REVIEW

    return parser


def main(argv=None):
    args = build_parser().parse_args(argv)
    return args.func(args)


if __name__ == "__main__":
    sys.exit(main())
