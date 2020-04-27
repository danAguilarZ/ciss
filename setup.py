from setuptools import setup, find_packages
from os.path import basename
from os.path import splitext
from glob import glob

setup(
    name='ciss',
    version='0.0.20200420',
    packages=find_packages('src'),
    package_dir={'': 'src'},
    py_modules=[splitext(basename(path))[0] for path in glob('src/*.py')],
    include_package_data=True,
    python_requires='>=3.6',
    setup_requires=[],
    install_requires=[
        "mysql-connector>=2.2.9"
        "PyYAML>=5.3.1"
    ]
)
