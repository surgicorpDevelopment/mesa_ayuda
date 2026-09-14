#!/usr/bin/env python
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent
for _p in (ROOT, ROOT.parent):
    _s = str(_p)
    if _s not in sys.path:
        sys.path.insert(0, _s)


def main():
    os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'localdev.settings')
    from django.core.management import execute_from_command_line

    execute_from_command_line(sys.argv)


if __name__ == '__main__':
    main()
