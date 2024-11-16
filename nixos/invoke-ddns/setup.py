#!/usr/bin/env python

from distutils.core import setup

setup(name='InvokeDdns',
      version='1.0',
      description='Checks with NearlyFreeSpeech that the dynamic dns entries are right',
      author='Philip Peterson',
      author_email='peterson@sent.com',
      url='https://github.com/philip-peterson/invoke-ddns',
      packages=['invoke_ddns', 'invoke_ddns.command'],
      install_requires=[
        'tornado>=4.4'
      ],
      entry_points={
        'console_scripts': [
            'invoke-ddns = invoke_ddns.command:main',
        ],
      },
     )
