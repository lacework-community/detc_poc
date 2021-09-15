from setuptools import setup

setup(
    name="detc",
    version="1.0",
    py_modules=["detc"],
    include_package_data=True,
    install_requires=["click"],
    entry_points="""
        [console_scripts]
        detc=detc:cli
    """,
)