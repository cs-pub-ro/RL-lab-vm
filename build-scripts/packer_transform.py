#!/usr/bin/env python3
""" Converts a YAML packer file to JSON """

from sys import stdout, stdin
import json
import yaml


if __name__ == '__main__':
    yaml_object = yaml.safe_load(stdin)
    json.dump(yaml_object, stdout, indent=2)

