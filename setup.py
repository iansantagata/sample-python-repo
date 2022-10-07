from setuptools import find_packages, setup

setup(
    name="sample-python-repo",
    version="0.1",
    packages=find_packages(),
    install_requires=[
        "cachetools~=5.0.0",
        "click>8.0.0",
        "geopandas",
        "matplotlib",
        "pandas>=1.0.0",
        "shapely",
        "pydantic",
    ],
    extras_require={
        "dev": [
            "black",
            "codecov",
            "isort",
            "pylint",
            "pytest",
            "pytest-cov",
            "pytest-mock",
        ]
    },
    include_package_data=True,
)

