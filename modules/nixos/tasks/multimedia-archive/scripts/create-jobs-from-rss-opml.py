#!/usr/bin/env nix-shell
#! nix-shell -i python3 -p python3

# NOTE: If you're using Thunderbird and you're using a folder structure in your
# feeds folder where one folder == one feed. It's going to be messy for you.

# It creates a jobs database suitable for this task from a given OPML file
# typically exported through Thunderbird and newsboat. This script considers
# the outline hierarchy as part of tag hierarchy similar to Newsboat import
# script. Additionally, `categories` attribute in the element are also
# considered.
#
# Take note, this script considers the first outline with a 'title' or 'text'
# attribute containing other RSS nodes as the category name and that's it.
#
# Anywho, the following document URL at <http://opml.org/spec2.opml> is used as
# the basis for how OPML subscription lists work.
#
# This script **tries** to consider the common way how most applications export
# their OPML which is not great. The only applications I've ever inspected are
# OPMLs from Thunderbird, Feeder, and FreshFeed. Each with their own quirks and
# usage of several attributes compared to what is expected from the
# specification.
#
# For example, most applications I've used don't easily export categories into
# the 'category' attribute which is unfortunate. There seems to be little
# respect for the attribute. Not to mention, there could be many assumptions
# for the structure for these various applications so I'm taking the simplest
# way.
#
# Welp, the disadvantage of OPML being a very flexible format it seems. :(

import argparse
import json
import re
import sys
from typing import Dict
from xml.etree import ElementTree

FALLBACK_CATEGORY = "Uncategorized"


# Very lazy implementation of kebab-casing. :)
def kebab_case(string):
    string = string.lower()
    string = re.sub(r"\s+", "-", string)
    string = re.sub("[^a-zA-Z0-9-]", "", string)
    string = re.sub("-+", "-", string)
    string = re.sub("^-|-$", "", string)
    return string


def first(function, iterable, default=None):
    """
    Returns the first value that passed the predicate function. Otherwise,
    return with the given default value.
    """
    return next(filter(function, iterable), default)


class Subscription(object):
    def __init__(self, name, url, description=""):
        self.name = name
        self.url = url
        self.description = description


class Outline(object):
    """An ``<outline>`` OPML element representation in Python."""

    def __init__(self, title=None, subscriptions=None, children=None):
        self.title = title
        self.subscriptions = []
        self.children = []

        if children is not None:
            for child in children:
                self.add_child(child)

        if subscriptions is not None:
            for subscription in subscriptions:
                self.add_subscription(subscription)

    def export(self) -> Dict:
        """Export the outline hierarchy as a dictionary."""

        SUBSCRIPTION_KEY = "__subscriptions__"
        CHILDREN_KEY = "__children__"

        def recurse(root: Outline, data={}, depth: int = 1):
            title = "root" if depth == 1 else root.title

            if title is None:
                title = FALLBACK_CATEGORY

            data[title] = {SUBSCRIPTION_KEY: [], CHILDREN_KEY: {}}

            for subscription in root.subscriptions:
                data[title][SUBSCRIPTION_KEY].append(subscription)

            for child in root.children:
                recurse(child, data[title][CHILDREN_KEY], depth + 1)

            return data

        return recurse(self, {})

    def add_child(self, child):
        assert isinstance(child, Outline)
        self.children.append(child)

    def add_subscription(self, subscription):
        assert isinstance(subscription, Subscription)
        self.subscriptions.append(subscription)

    @staticmethod
    def parse(opml_xml: ElementTree.ElementTree, max_depth: int | None = None):
        """
        Parse a given OPML as an ``ElementTree`` and return an ``Outline``
        instance out of it.
        """
        opml_body = opml_xml.find("./body")

        assert (
            opml_body is not None
        ), """
            Given OPML does not have a ``<body>`` element. It is most likely
            the OPML is not valid.
        """

        root_outline = Outline()

        def get_attributes(element: ElementTree.Element, attributes=[]):
            return first(
                lambda elem: elem is not None,
                map(lambda attr: element.get(attr, None), attributes),
            )

        def recurse(
            root_outline: Outline,
            element: ElementTree.Element,
            depth: int = 1,
            max_depth: int | None = None,
        ) -> Outline:
            outlines = element.iterfind("./outline")

            for outline in outlines:
                title = get_attributes(outline, ["title", "text"])
                inner_outline = Outline(title)

                node_type = outline.get("type")
                if node_type == "rss":
                    subscription = Subscription(title, outline.get("xmlUrl"))

                    description = outline.get("description")
                    if description is not None:
                        subscription.description = description

                    inner_outline.add_subscription(subscription)

                root_outline.add_child(
                    recurse(inner_outline, outline, depth + 1, max_depth)
                )

            return root_outline

        return recurse(root_outline, opml_body, max_depth=max_depth)


def list_categories_from_outline(root_outline: Outline):
    data = set()

    for child in root_outline.children:
        title = FALLBACK_CATEGORY if child.title is None else child.title
        data.add(title)
    return list(data)


def create_jobs_from_outline(root_outline: Outline, categories=[]):
    data = {}

    def recurse(outline: Outline, category=None, data={}, depth=1):
        # We're only using the top-level outline titles as the category.
        if depth == 2:
            category = outline.title

        # The root outline shouldn't have a title.
        if depth == 1 or category is None:
            category = FALLBACK_CATEGORY

        if category not in data:
            data[category] = {
                "extraArgs": [],
                "subscriptions": [],
            }

        for subscription in outline.subscriptions:
            data[category]["subscriptions"].append(subscription)

        for child in outline.children:
            recurse(child, category, data, depth + 1)

        return data

    data = recurse(root_outline, data=data)

    keys = list(data.keys())
    for category in keys:
        if category not in categories:
            del data[category]

    return data


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Create a job database from an OPML file."
    )
    parser.add_argument("file", metavar="OPML_FILE", help="The OPML file.")
    parser.add_argument(
        "categories",
        nargs="*",
        metavar="CATEGORY",
        help="A list of categories to be extracted. If no categories are given, assumes that all categories are to be extracted.",
    )
    parser.add_argument(
        "--list",
        "-l",
        action="store_true",
        help="List all categories from the given file.",
    )
    parser.add_argument(
        "--output",
        "-o",
        action="store",
        metavar="FILE",
        help="The file where the output will be written.",
    )
    parser.add_argument(
        "--with-others",
        action="store_true",
        help=f"List all uncategorized feeds into '{FALLBACK_CATEGORY}'.",
    )

    args = parser.parse_args()

    with open(args.file, mode="r") as f:
        opml_xml = ElementTree.parse(f)
        root_outline = Outline.parse(opml_xml)
        if args.list:
            for category in list_categories_from_outline(root_outline):
                print(category)
        else:
            categories = []

            # We're setting it up this way to prioritize arguments from stdin.
            if not sys.stdin.isatty():
                for line in sys.stdin:
                    categories.append(line.strip())

            if len(args.categories) > 0:
                categories = args.categories
            elif len(categories) == 0:
                categories = list_categories_from_outline(root_outline)

            data = create_jobs_from_outline(root_outline, categories)

            # Ehhh... Personal preference.
            keys = list(data.keys())
            for key in keys:
                data[kebab_case(key)] = data.pop(key)

            json_dump_kwargs = {
                "default": vars,
                "ensure_ascii": False,
                "indent": 2,
                "sort_keys": True,
            }

            if "output" in args:
                with open(args.output, mode="w") as output_file:
                    json.dump(data, output_file, **json_dump_kwargs)
            else:
                print(json.dumps(data, **json_dump_kwargs))

# vi:ft=python:ts=4
