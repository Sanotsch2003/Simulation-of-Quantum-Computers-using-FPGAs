from setuptools import setup, find_packages

setup(
    name='QBridge',
    version='1.0.0',
    packages=find_packages(),
    description='Package for compiling FPGA programs',
    author='Jonas Müller',
    author_email='your.email@example.com',
    url='https://github.com/yourusername/compiler_package',
    install_requires=[
        # List your dependencies here, if any
        'dependency1',
        'dependency2',
    ],
)
