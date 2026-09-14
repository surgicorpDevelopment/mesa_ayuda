"""Arranque del harness local: migrate, seeds y runserver."""
import os
import subprocess
import sys

os.makedirs('/app/data', exist_ok=True)
os.makedirs('/app/media', exist_ok=True)


def run(args):
    print('+', ' '.join(args), flush=True)
    subprocess.check_call(args)


run([sys.executable, 'manage.py', 'migrate', '--noinput'])
run([sys.executable, 'manage.py', 'setup_gp_groups'])
run([sys.executable, 'manage.py', 'seed_gp_sistemas'])
run([sys.executable, 'manage.py', 'seed_local_users'])
os.execv(
    sys.executable,
    [sys.executable, 'manage.py', 'runserver', '0.0.0.0:8000'],
)
