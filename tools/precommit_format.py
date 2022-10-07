import fnmatch
import subprocess

EXCLUDE_PATHS = ["migrations/versions/*.py"]


def run():
    """
    This method unstages files in the `EXCLUDE_PATHS` before running the precommit formatting.
    Then, once the precommit is run, restages all the excluded files.
    """
    raw = subprocess.check_output("git diff --name-only --cached", shell=True).split()
    staged_files = [x.decode("utf-8") for x in raw]
    exclude = set()
    for pattern in EXCLUDE_PATHS:
        exclude.update(fnmatch.filter(staged_files, pattern))
    for f in exclude:
        subprocess.call(f"git reset HEAD {f}", shell=True)
    status = subprocess.call("yarn indigo-scripts", shell=True)
    for f in exclude:
        subprocess.call(f"git add {f}", shell=True)
    if status != 0:
        exit(1)


if __name__ == "__main__":
    run()

