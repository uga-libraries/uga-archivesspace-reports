# uga-archivesspace-reports
A collection of custom reports built for UGA's ArchivesSpace instance. The following reports are:

- **check_urls** - A custom report to capture URLs in notes and digital object file versions and check them for bad requests (404, 500, etc.). Redirected links check the destination URL for errors.

# Getting Started

Download the files in this repo by clicking on the Code box in the top right corner and selecting Download ZIP.

Move the downloaded ZIP folder to your ArchivesSpace's plugins path:

    /path/to/archivesspace/plugins

Unzip it:

    $ cd /path/to/archivesspace/plugins
    $ unzip uga-archivesspace-reports-main.zip -d uga-archivesspace-reports-main

Enable the plugin by editing the file in `config/config.rb`:

    AppConfig[:plugins] = ['some_plugin', 'check_urls']

(Make sure you uncomment this line (i.e., remove the leading '#' if present))

For more information on installing and making plugins:

  https://github.com/archivesspace/tech-docs/blob/master/customization/plugins.md