"""
helpers
"""
import getpass
import os
import re
import subprocess
import tempfile
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

from pip import main as pipmain


class EnvironmentChecker():
    """
    subcontainer for env checkers
    """

    @staticmethod
    def is_docker() -> bool:
        """
        is current process running in docker?
        """
        with open("/proc/self/cgroup", mode='r', encoding='utf-8') as fin:
            for line in fin:
                if 'cpuset' in line:
                    if 'docker' in line:
                        return True

        return False


    @staticmethod
    def is_site_user() -> bool:
        """
        is current process running in docker?
        """
        return '_' in getpass.getuser()


class Logger():
    """Logger"""

    @staticmethod
    def error(message: str) -> None:
        """error"""
        print('\x1b[1m\x1b[48;5;1m ' + message + ' \x1b[0m')


    @staticmethod
    def success(message: str) -> None:
        """success"""
        print('\x1b[1m\x1b[48;5;28m ' + message + ' \x1b[0m')


    @staticmethod
    def warning(message: str) -> None:
        """warning"""
        print('\x1b[1m\x1b[48;5;11m\x1b[30m ' + message + ' \x1b[0m')


def apt_install(package_name):
    """install deb package(s)"""
    prepare_folders()
    pipmain(['install', 'setuptools'])
    pipmain(['install', 'wget'])

    tmp_folder_4_downloads = tempfile.mkdtemp()
    tmp_folder_4_extracted = tempfile.mkdtemp()

    apt_output = subprocess.check_output('apt-get --print-uris --yes -d --reinstall --no-install-recommends install '+package_name, shell=True)
    package_links = re.findall(r'http:\/\/[\w\d\.\-\/]+\.deb', str(apt_output))
    for link in package_links:
        print(f"Getting {link}...")
        package_filename = os.path.basename(urlparse(link).path)
        target_path = os.path.join(tmp_folder_4_downloads, package_filename)
        urllib.request.urlretrieve(link, target_path)
        subprocess.run(['dpkg-deb', '-x', target_path, tmp_folder_4_extracted], check=True)


def pecl_install(ext_name: str, php_version: str) -> None:
    """install php native extension"""
    urllib.request.urlretrieve(f"https://pecl.php.net/get/{ext_name}", f"/tmp/{ext_name}.tgz")


def prepare_folders() -> None:
    """
    create common folders that we are will store temporary files and end result
    """
    Logger.warning('Preparing folders...')
    Path.home().joinpath('.beget','tmp').rmdir()

    Path.home().joinpath('.beget','tmp').mkdir(0o700, parents=True, exist_ok=True)
    Path.home().joinpath('.local','bin').mkdir(0o700, parents=True, exist_ok=True)
    Path.home().joinpath('.local','opt').mkdir(0o700, parents=True, exist_ok=True)
